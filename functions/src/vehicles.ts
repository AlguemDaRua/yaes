// Mirrors optional partner-fleet vehicle details onto the driver's PUBLIC
// profile. Matching categories are managed directly under /drivers/{uid}.
//
// Why: vehicles live under /partners/{partnerId}/vehicles/{vehicleId}, which
// passengers cannot read (partner subtree is admin/support-only). The passenger
// app reads legacy display details from /users/{driverUid}/vehicle; dispatch
// and acceptance read categories from /drivers/{driverUid}, independently.

import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";

type Database = admin.database.Database;

interface VehicleNode {
  driverId?: string;
  model?: string;
  plate?: string;
  type?: string;
  seats?: number;
  color?: string;
  photoUrl?: string;
  status?: string;
}

/** Public vehicle details written to /users/{driverId}/vehicle. */
function publicSnapshot(
  partnerId: string,
  vehicleId: string,
  v: VehicleNode
): Record<string, unknown> {
  const snap: Record<string, unknown> = {
    vehicleId,
    partnerId,
  };
  if (v.model !== undefined) snap.model = v.model;
  if (v.plate !== undefined) snap.plate = v.plate;
  if (v.type !== undefined) snap.type = v.type;
  if (v.seats !== undefined) snap.seats = v.seats;
  if (v.color !== undefined) snap.color = v.color;
  if (v.photoUrl !== undefined) snap.photoUrl = v.photoUrl;
  if (v.status !== undefined) snap.status = v.status;
  return snap;
}

/** Clears a driver's mirror only if it still points at [vehicleId] (so we don't
 * wipe a mirror the driver already replaced with a newer vehicle). */
async function clearMirrorIfMatches(
  db: Database,
  driverId: string,
  vehicleId: string
): Promise<void> {
  const cur = (await db.ref(`users/${driverId}/vehicle`).get()).val() as
    | {vehicleId?: string}
    | null;
  if (cur && cur.vehicleId === vehicleId) {
    await db.ref(`users/${driverId}/vehicle`).remove();
  }
}

export async function mirrorVehicleCore(
  db: Database,
  partnerId: string,
  vehicleId: string,
  before: VehicleNode | null,
  after: VehicleNode | null
): Promise<void> {
  const prevDriver = before?.driverId;
  const newDriver = after?.driverId;

  // Driver removed / reassigned away / vehicle deleted → clear old mirror.
  if (prevDriver && prevDriver !== newDriver) {
    await clearMirrorIfMatches(db, prevDriver, vehicleId);
  }

  if (after && newDriver) {
    await db.ref(`users/${newDriver}/vehicle`).set(
      publicSnapshot(partnerId, vehicleId, after)
    );
  }
}

export const onVehicleChanged = functions.database
  .ref("/partners/{partnerId}/vehicles/{vehicleId}")
  .onWrite((change, context) =>
    mirrorVehicleCore(
      admin.database(),
      context.params.partnerId as string,
      context.params.vehicleId as string,
      change.before.val() as VehicleNode | null,
      change.after.val() as VehicleNode | null
    )
  );

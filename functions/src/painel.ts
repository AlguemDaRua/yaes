// Callable Cloud Functions used by the backoffice panel (ya-painelv1).
// These mirror the signatures consumed in
// ya-painelv1/lib/data/firebase/cloud_functions_service.dart.
//
// Authorization model (B2B partner-fleet):
//   - Platform-level actions (createPartner, approve/suspendPartner,
//     processPayout, setUserRole) are admin-only.
//   - Fleet onboarding (inviteDriver) is allowed for an admin OR the
//     partner_owner acting on their own partnerId.
//
// Each callable is a thin wrapper around a pure `*Core` function that takes the
// database handle explicitly, so the logic is unit-testable without the
// emulator (see __tests__/painel.test.ts).

import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import {writeAudit} from "./audit";

type Database = admin.database.Database;

const VALID_ROLES = [
  "admin",
  "support",
  "driver",
  "passenger",
  "partner_owner",
  "partner_staff",
] as const;

type Role = (typeof VALID_ROLES)[number];

const ROLES_NEEDING_PARTNER: Role[] = ["driver", "partner_owner", "partner_staff"];

// ─────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────

function assertAuth(context: functions.https.CallableContext): string {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Not authenticated.");
  }
  return context.auth.uid;
}

async function isAdmin(db: Database, uid: string): Promise<boolean> {
  const snap = await db.ref(`admins/${uid}`).get();
  return snap.exists() && snap.val() === true;
}

async function assertAdmin(db: Database, uid: string): Promise<void> {
  if (!(await isAdmin(db, uid))) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only administrators can perform this action."
    );
  }
}

/** Admin, or the partner_owner of the given partner, may manage that fleet. */
async function assertCanManagePartner(
  db: Database,
  callerUid: string,
  partnerId: string
): Promise<void> {
  if (await isAdmin(db, callerUid)) return;
  const snap = await db.ref(`users/${callerUid}`).get();
  const user = snap.val() as {type?: string; partnerId?: string} | null;
  if (user && user.type === "partner_owner" && user.partnerId === partnerId) {
    return;
  }
  throw new functions.https.HttpsError(
    "permission-denied",
    "Only an administrator or this partner's owner can manage the fleet."
  );
}

/** Strips everything but digits so a phone number is a safe RTDB key. */
export function phoneKey(phone: string): string {
  return phone.replace(/\D/g, "");
}

function nowIso(): string {
  return new Date().toISOString();
}

// ─────────────────────────────────────────────────────────────
// setUserRole
// ─────────────────────────────────────────────────────────────

export interface SetUserRoleData {
  uid: string;
  role: Role;
  partnerId?: string;
}

export async function setUserRoleCore(
  db: Database,
  callerUid: string,
  data: SetUserRoleData
): Promise<{success: true; uid: string; role: Role}> {
  await assertAdmin(db, callerUid);
  const {uid, role, partnerId} = data;
  if (!uid || !VALID_ROLES.includes(role)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Required: uid (string), role (one of ${VALID_ROLES.join(", ")}).`
    );
  }
  if (ROLES_NEEDING_PARTNER.includes(role) && !partnerId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Role '${role}' requires a partnerId.`
    );
  }
  const update: Record<string, unknown> = {type: role};
  if (partnerId) update.partnerId = partnerId;
  await db.ref(`users/${uid}`).update(update);
  // Keep the /admins flag in sync so panel access rules follow the role.
  if (role === "admin") {
    await db.ref(`admins/${uid}`).set(true);
  } else {
    await db.ref(`admins/${uid}`).remove();
  }
  return {success: true, uid, role};
}

export const setUserRole = functions.https.onCall(
  (data: SetUserRoleData, context: functions.https.CallableContext) =>
    setUserRoleCore(admin.database(), assertAuth(context), data)
);

// ─────────────────────────────────────────────────────────────
// createPartner
// ─────────────────────────────────────────────────────────────

export interface CreatePartnerData {
  name: string;
  nuit: string;
  city: string;
  ownerUid: string;
  email?: string;
  phone?: string;
}

export async function createPartnerCore(
  db: Database,
  callerUid: string,
  data: CreatePartnerData
): Promise<{partnerId: string}> {
  await assertAdmin(db, callerUid);
  const {name, nuit, city, ownerUid, email, phone} = data;
  if (!name || !nuit || !city || !ownerUid) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Required: name, nuit, city, ownerUid."
    );
  }
  const ownerSnap = await db.ref(`users/${ownerUid}`).get();
  if (!ownerSnap.exists()) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "ownerUid must reference an existing user (login via OTP first)."
    );
  }
  const ref = db.ref("partners").push();
  const partnerId = ref.key as string;
  const partner: Record<string, unknown> = {
    name,
    nuit,
    city,
    status: "pending",
    createdAt: nowIso(),
  };
  if (email) partner.email = email;
  if (phone) partner.phone = phone;
  await ref.set(partner);
  await db.ref(`users/${ownerUid}`).update({
    type: "partner_owner",
    partnerId,
  });
  return {partnerId};
}

export const createPartner = functions.https.onCall(
  (data: CreatePartnerData, context: functions.https.CallableContext) =>
    createPartnerCore(admin.database(), assertAuth(context), data)
);

// ─────────────────────────────────────────────────────────────
// approvePartner / suspendPartner
// ─────────────────────────────────────────────────────────────

async function setPartnerStatusCore(
  db: Database,
  callerUid: string,
  partnerId: string,
  status: "active" | "suspended",
  reason?: string
): Promise<{success: true; partnerId: string; status: string}> {
  await assertAdmin(db, callerUid);
  if (!partnerId) {
    throw new functions.https.HttpsError("invalid-argument", "Required: partnerId.");
  }
  const snap = await db.ref(`partners/${partnerId}`).get();
  if (!snap.exists()) {
    throw new functions.https.HttpsError("not-found", "Partner not found.");
  }
  const update: Record<string, unknown> = {status};
  if (status === "suspended") update.suspendReason = reason ?? null;
  await db.ref(`partners/${partnerId}`).update(update);
  return {success: true, partnerId, status};
}

export const approvePartner = functions.https.onCall(
  (data: {partnerId: string}, context: functions.https.CallableContext) =>
    setPartnerStatusCore(admin.database(), assertAuth(context), data.partnerId, "active")
);

export const suspendPartner = functions.https.onCall(
  (
    data: {partnerId: string; reason?: string},
    context: functions.https.CallableContext
  ) =>
    setPartnerStatusCore(
      admin.database(),
      assertAuth(context),
      data.partnerId,
      "suspended",
      data.reason
    )
);

export {setPartnerStatusCore};

// ─────────────────────────────────────────────────────────────
// processPayout
// ─────────────────────────────────────────────────────────────

export interface ProcessPayoutData {
  partnerId: string;
  amountMtn: number;
  method: "mpesa" | "bank";
  reference?: string;
}

export async function processPayoutCore(
  db: Database,
  callerUid: string,
  data: ProcessPayoutData
): Promise<{payoutId: string}> {
  await assertAdmin(db, callerUid);
  const {partnerId, amountMtn, method, reference} = data;
  if (!partnerId || typeof amountMtn !== "number" || amountMtn <= 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Required: partnerId and a positive amountMtn."
    );
  }
  if (method !== "mpesa" && method !== "bank") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "method must be 'mpesa' or 'bank'."
    );
  }
  const ref = db.ref(`payouts/${partnerId}`).push();
  const payoutId = ref.key as string;
  const payout: Record<string, unknown> = {
    label: method === "mpesa" ? "Payout M-Pesa" : "Payout bancário",
    amountMtn,
    method,
    status: "paid",
    createdAt: nowIso(),
  };
  if (reference) payout.reference = reference;
  await ref.set(payout);
  return {payoutId};
}

export const processPayout = functions.https.onCall(
  (data: ProcessPayoutData, context: functions.https.CallableContext) =>
    processPayoutCore(admin.database(), assertAuth(context), data)
);

// ─────────────────────────────────────────────────────────────
// inviteDriver — onboarding by phone (admin or partner_owner)
// ─────────────────────────────────────────────────────────────

export interface InviteDriverData {
  partnerId: string;
  phone: string;
  name?: string;
  vehicleId?: string;
}

export type InviteDriverResult =
  | {status: "linked"; uid: string}
  | {status: "invited"; phoneKey: string};

export async function inviteDriverCore(
  db: Database,
  callerUid: string,
  data: InviteDriverData
): Promise<InviteDriverResult> {
  const {partnerId, phone, name, vehicleId} = data;
  if (!partnerId || !phone) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Required: partnerId and phone."
    );
  }
  await assertCanManagePartner(db, callerUid, partnerId);

  const snap = await db.ref("users").orderByChild("phone").equalTo(phone).get();
  const found = snap.val() as
    | Record<string, {type?: string; partnerId?: string}>
    | null;
  const uid = found ? Object.keys(found)[0] : null;

  if (uid) {
    const existing = found?.[uid];
    // Never overwrite a privileged or already-claimed account: only onboard an
    // unassigned passenger, or re-link a driver already in this same partner.
    // Prevents a partner owner from hijacking an admin/support/other partner's
    // user by phone number.
    const type = existing?.type;
    const linkable =
      type === undefined ||
      type === "passenger" ||
      (type === "driver" && existing?.partnerId === partnerId);
    if (!linkable) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "That phone belongs to a user who is not an unassigned passenger."
      );
    }
    const update: Record<string, unknown> = {type: "driver", partnerId};
    if (vehicleId) update.vehicleId = vehicleId;
    await db.ref(`users/${uid}`).update(update);
    await db.ref(`partners/${partnerId}/drivers/${uid}`).set(true);
    if (vehicleId) {
      await db.ref(`partners/${partnerId}/vehicles/${vehicleId}`).update({driverId: uid});
    }
    return {status: "linked", uid};
  }

  const key = phoneKey(phone);
  const invite: Record<string, unknown> = {
    partnerId,
    role: "driver",
    invitedBy: callerUid,
    createdAt: nowIso(),
  };
  if (vehicleId) invite.vehicleId = vehicleId;
  if (name) invite.name = name;
  await db.ref(`partnerInvites/${key}`).set(invite);
  return {status: "invited", phoneKey: key};
}

export const inviteDriver = functions.https.onCall(
  (data: InviteDriverData, context: functions.https.CallableContext) =>
    inviteDriverCore(admin.database(), assertAuth(context), data)
);

// ─────────────────────────────────────────────────────────────
// assignVehicle — links a driver to a vehicle (or unassigns). Writes both the
// vehicle's driverId and the driver's users/{uid}/vehicleId, which a partner
// owner cannot write directly under the security rules.
// ─────────────────────────────────────────────────────────────

export interface AssignVehicleData {
  partnerId: string;
  vehicleId: string;
  driverUid?: string | null;
}

export async function assignVehicleCore(
  db: Database,
  callerUid: string,
  data: AssignVehicleData
): Promise<{success: true}> {
  const {partnerId, vehicleId, driverUid} = data;
  if (!partnerId || !vehicleId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Required: partnerId and vehicleId."
    );
  }
  await assertCanManagePartner(db, callerUid, partnerId);

  const vehicleRef = db.ref(`partners/${partnerId}/vehicles/${vehicleId}`);
  const prevSnap = await vehicleRef.child("driverId").get();
  const prevDriver = prevSnap.val() as string | null;

  // Release the previous driver of this vehicle, if different.
  if (prevDriver && prevDriver !== driverUid) {
    await db.ref(`users/${prevDriver}/vehicleId`).remove();
  }

  if (driverUid) {
    // Release the driver's previous vehicle, if any and different, so a driver
    // is never left listed on two vehicles.
    const driverSnap = await db.ref(`users/${driverUid}/vehicleId`).get();
    const oldVehicle = driverSnap.val() as string | null;
    if (oldVehicle && oldVehicle !== vehicleId) {
      await db
        .ref(`partners/${partnerId}/vehicles/${oldVehicle}/driverId`)
        .remove();
    }
    await vehicleRef.update({driverId: driverUid});
    await db.ref(`users/${driverUid}/vehicleId`).set(vehicleId);
    await db.ref(`partners/${partnerId}/drivers/${driverUid}`).set(true);
  } else {
    await vehicleRef.child("driverId").remove();
  }
  return {success: true};
}

export const assignVehicle = functions.https.onCall(
  (data: AssignVehicleData, context: functions.https.CallableContext) =>
    assignVehicleCore(admin.database(), assertAuth(context), data)
);

// ─────────────────────────────────────────────────────────────
// onUserCreated — applies a pending driver invite when the invited
// person signs up in the app (the app creates /users/{uid} with phone).
// Runs with Admin privileges, so it can set the protected `type` field and
// needs no client-side read access to /partnerInvites.
// ─────────────────────────────────────────────────────────────

export async function applyPendingInviteCore(
  db: Database,
  uid: string,
  phone: string | null | undefined
): Promise<{applied: boolean}> {
  if (!phone) return {applied: false};
  const key = phoneKey(phone);
  const snap = await db.ref(`partnerInvites/${key}`).get();
  const invite = snap.val() as
    | {partnerId?: string; vehicleId?: string; role?: string}
    | null;
  if (!invite || !invite.partnerId) return {applied: false};

  const update: Record<string, unknown> = {
    type: invite.role ?? "driver",
    partnerId: invite.partnerId,
  };
  if (invite.vehicleId) update.vehicleId = invite.vehicleId;
  await db.ref(`users/${uid}`).update(update);
  await db.ref(`partners/${invite.partnerId}/drivers/${uid}`).set(true);
  if (invite.vehicleId) {
    await db
      .ref(`partners/${invite.partnerId}/vehicles/${invite.vehicleId}`)
      .update({driverId: uid});
  }
  await db.ref(`partnerInvites/${key}`).remove();
  return {applied: true};
}

export const onUserCreated = functions.database.ref("/users/{uid}").onCreate(
  (snapshot, context) =>
    applyPendingInviteCore(
      admin.database(),
      context.params.uid as string,
      (snapshot.val() as {phone?: string} | null)?.phone
    )
);

// ─────────────────────────────────────────────────────────────
// setCommission — admin sets a partner's commission tier/rate.
// Writes /commissions/{partnerId} (rules: admin-only write).
// ─────────────────────────────────────────────────────────────

export interface SetCommissionData {
  partnerId: string;
  rate: number; // fraction, e.g. 0.12 for 12%
  label?: string;
}

export async function setCommissionCore(
  db: Database,
  callerUid: string,
  data: SetCommissionData
): Promise<{success: true; partnerId: string}> {
  await assertAdmin(db, callerUid);
  const {partnerId, rate, label} = data;
  if (!partnerId || typeof rate !== "number" || rate < 0 || rate > 1) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Required: partnerId and a rate between 0 and 1."
    );
  }
  const update: Record<string, unknown> = {
    rate,
    status: "active",
    updatedAt: nowIso(),
  };
  if (label) update.label = label;
  await db.ref(`commissions/${partnerId}`).update(update);
  await writeAudit(db, {
    action: "setCommission",
    actorUid: callerUid,
    targetType: "partner",
    targetId: partnerId,
    meta: {rate},
  });
  return {success: true, partnerId};
}

export const setCommission = functions.https.onCall(
  (data: SetCommissionData, context: functions.https.CallableContext) =>
    setCommissionCore(admin.database(), assertAuth(context), data)
);

// ─────────────────────────────────────────────────────────────
// reviewDocument — admin approves/rejects an uploaded document.
// Writes /documents/{ownerType}/{ownerId}/{docId}/status.
// ─────────────────────────────────────────────────────────────

export interface ReviewDocumentData {
  ownerType: string;
  ownerId: string;
  docId: string;
  status: "approved" | "rejected" | "pending";
  reason?: string;
}

export async function reviewDocumentCore(
  db: Database,
  callerUid: string,
  data: ReviewDocumentData
): Promise<{success: true}> {
  await assertAdmin(db, callerUid);
  const {ownerType, ownerId, docId, status, reason} = data;
  if (!ownerType || !ownerId || !docId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Required: ownerType, ownerId, docId."
    );
  }
  if (status !== "approved" && status !== "rejected" && status !== "pending") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "status must be approved, rejected or pending."
    );
  }
  const ref = db.ref(`documents/${ownerType}/${ownerId}/${docId}`);
  if (!(await ref.get()).exists()) {
    throw new functions.https.HttpsError("not-found", "Document not found.");
  }
  const update: Record<string, unknown> = {status, reviewedAt: nowIso(), reviewedBy: callerUid};
  if (reason) update.reviewReason = reason;
  await ref.update(update);
  await writeAudit(db, {
    action: "reviewDocument",
    actorUid: callerUid,
    targetType: ownerType,
    targetId: `${ownerId}/${docId}`,
    meta: {status},
  });
  return {success: true};
}

export const reviewDocument = functions.https.onCall(
  (data: ReviewDocumentData, context: functions.https.CallableContext) =>
    reviewDocumentCore(admin.database(), assertAuth(context), data)
);

// ─────────────────────────────────────────────────────────────
// setUserStatus — admin suspends/reactivates a user (driver/passenger).
// Writes /users/{uid}/status (does not touch the protected `type`).
// ─────────────────────────────────────────────────────────────

export interface SetUserStatusData {
  uid: string;
  status: "active" | "suspended";
  reason?: string;
}

export async function setUserStatusCore(
  db: Database,
  callerUid: string,
  data: SetUserStatusData
): Promise<{success: true; uid: string; status: string}> {
  await assertAdmin(db, callerUid);
  const {uid, status, reason} = data;
  if (!uid || (status !== "active" && status !== "suspended")) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Required: uid and status (active|suspended)."
    );
  }
  if (!(await db.ref(`users/${uid}`).get()).exists()) {
    throw new functions.https.HttpsError("not-found", "User not found.");
  }
  const update: Record<string, unknown> = {status};
  if (status === "suspended" && reason) update.suspendReason = reason;
  await db.ref(`users/${uid}`).update(update);
  await writeAudit(db, {
    action: "setUserStatus",
    actorUid: callerUid,
    targetType: "user",
    targetId: uid,
    meta: {status},
  });
  return {success: true, uid, status};
}

export const setUserStatus = functions.https.onCall(
  (data: SetUserStatusData, context: functions.https.CallableContext) =>
    setUserStatusCore(admin.database(), assertAuth(context), data)
);

// ─────────────────────────────────────────────────────────────
// inviteManager — admin creates a backoffice account (admin/support).
// No email service is wired up, so the password-reset link is returned to
// the inviting admin, who shares it manually.
// ─────────────────────────────────────────────────────────────

export interface InviteManagerData {
  email: string;
  role: "admin" | "support";
  name?: string;
}

/** Subset of admin.auth() used by inviteManagerCore, mockable in tests. */
export interface ManagerAuth {
  createUser(props: {
    email: string;
    emailVerified: boolean;
    displayName?: string;
  }): Promise<{uid: string}>;
  generatePasswordResetLink(email: string): Promise<string>;
}

export async function inviteManagerCore(
  db: Database,
  auth: ManagerAuth,
  callerUid: string,
  data: InviteManagerData
): Promise<{uid: string; resetLink: string}> {
  await assertAdmin(db, callerUid);
  const {email, role, name} = data;
  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Required: a valid email."
    );
  }
  if (role !== "admin" && role !== "support") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "role must be 'admin' or 'support'."
    );
  }
  const created = await auth.createUser({
    email,
    emailVerified: true,
    ...(name ? {displayName: name} : {}),
  });
  const uid = created.uid;
  const user: Record<string, unknown> = {
    type: role,
    email,
    phone: "000000000",
    status: "active",
    createdAt: nowIso(),
  };
  if (name) user.name = name;
  await db.ref(`users/${uid}`).set(user);
  if (role === "admin") {
    await db.ref(`admins/${uid}`).set(true);
  }
  const resetLink = await auth.generatePasswordResetLink(email);
  await writeAudit(db, {
    action: "inviteManager",
    actorUid: callerUid,
    targetType: "user",
    targetId: uid,
    meta: {role, email},
  });
  return {uid, resetLink};
}

// ─────────────────────────────────────────────────────────────
// createPartnerWithOwner — admin creates a partner AND the owner's panel
// login (email/password) in one step. Returns a password-reset link the
// admin shares so the owner sets their password and signs into the panel.
// ─────────────────────────────────────────────────────────────

export interface CreatePartnerWithOwnerData {
  name: string;
  nuit: string;
  city: string;
  ownerEmail: string;
  ownerName?: string;
  email?: string;
  phone?: string;
  // YA Direct fleets (drivers with no partner of their own, e.g. Nampula):
  // commission is debited from a wallet instead of paid out normally — see
  // functions/src/wallet.ts. commissionFloatMtn is the debt ceiling before a
  // driver is auto-blocked from going online.
  requiresWalletSettlement?: boolean;
  commissionFloatMtn?: number;
}

export async function createPartnerWithOwnerCore(
  db: Database,
  auth: ManagerAuth,
  callerUid: string,
  data: CreatePartnerWithOwnerData
): Promise<{partnerId: string; ownerUid: string; resetLink: string}> {
  await assertAdmin(db, callerUid);
  const {
    name, nuit, city, ownerEmail, ownerName, email, phone,
    requiresWalletSettlement, commissionFloatMtn,
  } = data;
  if (!name || !nuit || !city) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Required: name, nuit, city."
    );
  }
  if (!ownerEmail || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(ownerEmail)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "A valid ownerEmail is required."
    );
  }
  if (
    commissionFloatMtn !== undefined &&
    (typeof commissionFloatMtn !== "number" || commissionFloatMtn < 0)
  ) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "commissionFloatMtn must be a non-negative number."
    );
  }

  // Create the owner's panel account (email verified so they can sign in
  // right after setting a password).
  const created = await auth.createUser({
    email: ownerEmail,
    emailVerified: true,
    ...(ownerName ? {displayName: ownerName} : {}),
  });
  const ownerUid = created.uid;

  const ref = db.ref("partners").push();
  const partnerId = ref.key as string;
  const partner: Record<string, unknown> = {
    name,
    nuit,
    city,
    status: "pending",
    createdAt: nowIso(),
  };
  if (email) partner.email = email;
  if (phone) partner.phone = phone;
  if (requiresWalletSettlement) {
    partner.requiresWalletSettlement = true;
    partner.commissionFloatMtn = commissionFloatMtn ?? 0;
  }
  await ref.set(partner);

  const owner: Record<string, unknown> = {
    type: "partner_owner",
    partnerId,
    email: ownerEmail,
    phone: phone ?? "000000000",
    status: "active",
    createdAt: nowIso(),
  };
  if (ownerName) owner.name = ownerName;
  await db.ref(`users/${ownerUid}`).set(owner);

  const resetLink = await auth.generatePasswordResetLink(ownerEmail);
  await writeAudit(db, {
    action: "createPartnerWithOwner",
    actorUid: callerUid,
    targetType: "partner",
    targetId: partnerId,
    meta: {ownerUid, ownerEmail},
  });
  return {partnerId, ownerUid, resetLink};
}

export const createPartnerWithOwner = functions.https.onCall(
  (
    data: CreatePartnerWithOwnerData,
    context: functions.https.CallableContext
  ) =>
    createPartnerWithOwnerCore(
      admin.database(),
      admin.auth(),
      assertAuth(context),
      data
    )
);

// ─────────────────────────────────────────────────────────────
// invitePartnerStaff — admin OR the partner's own owner creates a
// partner_staff panel login (email/password) for that fleet. Mirrors
// createPartnerWithOwner's account-creation shape; returns a password-reset
// link the caller shares manually (no email service wired up).
// ─────────────────────────────────────────────────────────────

export interface InvitePartnerStaffData {
  partnerId: string;
  email: string;
  name?: string;
  phone?: string;
}

export async function invitePartnerStaffCore(
  db: Database,
  auth: ManagerAuth,
  callerUid: string,
  data: InvitePartnerStaffData
): Promise<{uid: string; resetLink: string}> {
  const {partnerId, email, name, phone} = data;
  if (!partnerId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Required: partnerId."
    );
  }
  await assertCanManagePartner(db, callerUid, partnerId);
  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "A valid email is required."
    );
  }
  const partnerSnap = await db.ref(`partners/${partnerId}`).get();
  if (!partnerSnap.exists()) {
    throw new functions.https.HttpsError("not-found", "Partner not found.");
  }

  const created = await auth.createUser({
    email,
    emailVerified: true,
    ...(name ? {displayName: name} : {}),
  });
  const uid = created.uid;
  const user: Record<string, unknown> = {
    type: "partner_staff",
    partnerId,
    email,
    phone: phone ?? "000000000",
    status: "active",
    createdAt: nowIso(),
  };
  if (name) user.name = name;
  await db.ref(`users/${uid}`).set(user);
  await db.ref(`partners/${partnerId}/staff/${uid}`).set("partner_staff");

  const resetLink = await auth.generatePasswordResetLink(email);
  await writeAudit(db, {
    action: "invitePartnerStaff",
    actorUid: callerUid,
    targetType: "user",
    targetId: uid,
    meta: {partnerId, email},
  });
  return {uid, resetLink};
}

export const invitePartnerStaff = functions.https.onCall(
  (data: InvitePartnerStaffData, context: functions.https.CallableContext) =>
    invitePartnerStaffCore(
      admin.database(),
      admin.auth(),
      assertAuth(context),
      data
    )
);

// ─────────────────────────────────────────────────────────────
// revokeUserSessions — admin invalidates a user's refresh tokens, forcing a
// new login on every device. Firebase Auth cannot list individual sessions.
// ─────────────────────────────────────────────────────────────

/** Subset of admin.auth() used by revokeUserSessionsCore. */
export interface SessionAuth {
  revokeRefreshTokens(uid: string): Promise<void>;
}

export async function revokeUserSessionsCore(
  db: Database,
  auth: SessionAuth,
  callerUid: string,
  data: {uid: string}
): Promise<{success: true; uid: string}> {
  await assertAdmin(db, callerUid);
  const {uid} = data;
  if (!uid) {
    throw new functions.https.HttpsError("invalid-argument", "Required: uid.");
  }
  await auth.revokeRefreshTokens(uid);
  await writeAudit(db, {
    action: "revokeUserSessions",
    actorUid: callerUid,
    targetType: "user",
    targetId: uid,
  });
  return {success: true, uid};
}

export const revokeUserSessions = functions.https.onCall(
  (data: {uid: string}, context: functions.https.CallableContext) =>
    revokeUserSessionsCore(
      admin.database(),
      admin.auth(),
      assertAuth(context),
      data
    )
);

export const inviteManager = functions.https.onCall(
  (data: InviteManagerData, context: functions.https.CallableContext) =>
    inviteManagerCore(
      admin.database(),
      admin.auth(),
      assertAuth(context),
      data
    )
);

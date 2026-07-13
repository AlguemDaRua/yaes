import * as admin from "firebase-admin";

type Database = admin.database.Database;

export interface NotificationRecord {
  title: string;
  body: string;
  type: string;
  tripId?: string;
}

/**
 * Persists a notification to /notifications/{uid} so the app has a real
 * history to read — previously pushes were fire-and-forget with nothing
 * persisted, so the notifications page had no feed at all. Called alongside
 * (not instead of) the existing FCM push at each trigger site, so per-case
 * push config (android/apns priority, sound, etc.) stays untouched.
 */
export async function recordNotification(
  db: Database,
  uid: string,
  payload: NotificationRecord
): Promise<void> {
  await db.ref(`notifications/${uid}`).push().set({
    title: payload.title,
    body: payload.body,
    type: payload.type,
    ...(payload.tripId ? {tripId: payload.tripId} : {}),
    read: false,
    createdAt: new Date().toISOString(),
  });
}

/**
 * Same as [recordNotification] but fanned out to every user of the given
 * audience — used by broadcasts, which send a single FCM topic push (no
 * per-recipient token) but still need a per-user history entry.
 */
export async function recordNotificationForAudience(
  db: Database,
  audience: "all" | "drivers" | "passengers",
  payload: Omit<NotificationRecord, "tripId">
): Promise<void> {
  const uids: string[] = [];
  if (audience === "all") {
    const snap = await db.ref("users").get();
    if (snap.exists()) uids.push(...Object.keys(snap.val() as object));
  } else {
    const type = audience === "drivers" ? "driver" : "passenger";
    const snap = await db.ref("users").orderByChild("type").equalTo(type).get();
    if (snap.exists()) uids.push(...Object.keys(snap.val() as object));
  }
  await Promise.all(uids.map((uid) => recordNotification(db, uid, payload)));
}

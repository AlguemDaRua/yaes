// Admin broadcast push notifications via FCM topics. The app subscribes every
// signed-in user to "all" plus "drivers" or "passengers" (see
// lib/services/messaging_service.dart), so broadcasts only reach app builds
// that include that subscription.

import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import {writeAudit} from "./audit";
import {recordNotificationForAudience} from "./notify";

type Database = admin.database.Database;

const AUDIENCES = ["all", "drivers", "passengers"] as const;
export type BroadcastAudience = (typeof AUDIENCES)[number];

export interface SendBroadcastData {
  title: string;
  body: string;
  audience: BroadcastAudience;
}

/** Subset of admin.messaging() used by sendBroadcastCore, mockable in tests. */
export interface BroadcastMessaging {
  send(message: {
    topic: string;
    notification: {title: string; body: string};
  }): Promise<string>;
}

async function assertAdmin(db: Database, uid: string): Promise<void> {
  const snap = await db.ref(`admins/${uid}`).get();
  if (!snap.exists() || snap.val() !== true) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only administrators can send broadcasts."
    );
  }
}

export async function sendBroadcastCore(
  db: Database,
  messaging: BroadcastMessaging,
  callerUid: string,
  data: SendBroadcastData
): Promise<{broadcastId: string}> {
  await assertAdmin(db, callerUid);
  const {title, body, audience} = data;
  if (!title || !title.trim() || !body || !body.trim()) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Required: title and body."
    );
  }
  if (!AUDIENCES.includes(audience)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `audience must be one of: ${AUDIENCES.join(", ")}.`
    );
  }
  await messaging.send({
    topic: audience,
    notification: {title: title.trim(), body: body.trim()},
  });
  await recordNotificationForAudience(db, audience, {
    title: title.trim(),
    body: body.trim(),
    type: "broadcast",
  });
  const ref = db.ref("broadcasts").push();
  const broadcastId = ref.key as string;
  await ref.set({
    title: title.trim(),
    body: body.trim(),
    audience,
    sentBy: callerUid,
    status: "sent",
    createdAt: new Date().toISOString(),
  });
  await writeAudit(db, {
    action: "sendBroadcast",
    actorUid: callerUid,
    targetType: "broadcast",
    targetId: broadcastId,
    meta: {audience},
  });
  return {broadcastId};
}

export const sendBroadcast = functions.https.onCall(
  (data: SendBroadcastData, context: functions.https.CallableContext) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Not authenticated.");
    }
    return sendBroadcastCore(
      admin.database(),
      admin.messaging(),
      context.auth.uid,
      data
    );
  }
);

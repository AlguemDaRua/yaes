// Passenger↔driver ratings — submitted after a completed trip.
//
// Server-authoritative by design: the passenger only sends {tripId, value,
// comment}. The trip participants and status are resolved and verified here;
// neither client can choose the identity of the person being rated.
//
// Writes under /ratings/{ratedUserId}/{tripId} and updates that user's
// aggregate rating. The tripId key makes each direction idempotent.

import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import {writeAudit} from "./audit";

type Database = admin.database.Database;

export interface SubmitRatingData {
  tripId: string;
  value: number; // 1-5, half-stars allowed (e.g. 4.5)
  comment?: string;
}

export async function submitRatingCore(
  db: Database,
  callerUid: string,
  data: SubmitRatingData
): Promise<{ratingId: string; alreadyRated: boolean}> {
  const {tripId, value} = data;
  const comment = data.comment?.trim();

  if (!tripId || typeof value !== "number" || value < 1 || value > 5) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Required: tripId and a value between 1 and 5."
    );
  }

  const tripSnap = await db.ref(`trips/${tripId}`).get();
  const trip = tripSnap.val() as
    | {passenger?: string; driver?: string; status?: string}
    | null;
  if (!trip) {
    throw new functions.https.HttpsError("not-found", "Trip not found.");
  }
  const raterRole = trip.passenger === callerUid ? "passenger" :
    trip.driver === callerUid ? "driver" : null;
  if (raterRole === null) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only a participant in this trip can submit a rating."
    );
  }
  if (trip.status !== "completed") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "The trip must be completed before it can be rated."
    );
  }
  const targetUid = raterRole === "passenger" ? trip.driver : trip.passenger;
  if (!targetUid) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "The trip participant to rate is missing."
    );
  }

  // Idempotent: one rating per trip (entry keyed by tripId). A second
  // submission (e.g. double-tap) is a no-op, not a duplicate/second average
  // fold.
  const ratingRef = db.ref(`ratings/${targetUid}/${tripId}`);
  if ((await ratingRef.get()).exists()) {
    return {ratingId: tripId, alreadyRated: true};
  }

  const createdAt = new Date().toISOString();
  const ratingRecord = {
    driverId: trip.driver ?? null,
    passengerId: trip.passenger ?? null,
    raterId: callerUid,
    ratedUserId: targetUid,
    raterRole,
    tripId,
    value,
    comment: comment && comment.length > 0 ? comment : null,
    createdAt,
  };
  await db.ref().update({
    [`ratings/${targetUid}/${tripId}`]: ratingRecord,
    [`userRatings/${callerUid}/${tripId}`]: {
      tripId,
      ratedUserId: targetUid,
      value,
      comment: comment && comment.length > 0 ? comment : null,
      createdAt,
    },
  });

  // Fold into the rated user's running average. Scoped to the whole user node
  // (RTDB has no multi-field atomic write), preserving every other field.
  // Never abort on a falsy `current` — the Admin SDK invokes the updater
  // optimistically (it may see a stale/null snapshot before the real one),
  // and returning undefined there would abandon the transaction on that
  // first pass instead of retrying with the true value (see wallet.ts's
  // `applyWalletEntry`, which uses the same "current ?? default" shape for
  // exactly this reason).
  const ratedUserRef = db.ref(`users/${targetUid}`);
  await ratedUserRef.transaction((current: Record<string, unknown> | null) => {
    const base = current ?? {};
    const prevCount = Number(base.ratingCount ?? 0);
    const prevAvg = Number(base.rating ?? 0);
    const newCount = prevCount + 1;
    const newAvg = (prevAvg * prevCount + value) / newCount;
    return {
      ...base,
      rating: Math.round(newAvg * 10) / 10,
      ratingCount: newCount,
    };
  });

  await writeAudit(db, {
    action: "submitRating",
    actorUid: callerUid,
    targetType: "rating",
    targetId: tripId,
    meta: {ratedUserId: targetUid, raterRole, value},
  });

  return {ratingId: tripId, alreadyRated: false};
}

export const submitRating = functions.https.onCall(
  (data: SubmitRatingData, context: functions.https.CallableContext) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Not authenticated.");
    }
    return submitRatingCore(admin.database(), context.auth.uid, data);
  }
);

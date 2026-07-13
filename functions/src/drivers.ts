// Note: drivers are registered by partners via the admin dashboard.
// The users/{uid}/type field is set by the admin/partner via Firebase Admin SDK.
// There is no self-registration flow in the mobile app.
//
// This Cloud Function allows the admin to change a user's type
// to driver via an authenticated call.

import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";

const db = admin.database();

interface SetDriverTypeRequest {
  uid: string; // uid of the user to promote
  type: "driver" | "passenger";
}

/**
 * Callable (admin only): sets the type of a user.
 * Called by the admin dashboard when a partner registers a driver.
 */
export const setUserType = functions.https.onCall(
  async (data: SetDriverTypeRequest, context: functions.https.CallableContext) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Not authenticated.");
    }

    // Check if the caller is an admin
    const adminSnap = await db.ref(`admins/${context.auth.uid}`).get();
    if (!adminSnap.exists() || adminSnap.val() !== true) {
      throw new functions.https.HttpsError("permission-denied", "Only administrators can change user type.");
    }

    const {uid, type} = data;

    if (!uid || (type !== "driver" && type !== "passenger")) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Required fields: uid (string), type ('driver' | 'passenger')."
      );
    }

    await db.ref(`users/${uid}/type`).set(type);
    return {success: true, uid, type};
  }
);

/* eslint-disable */
// Promote a real user to platform admin in PRODUCTION (project ya-app-z).
//
// Sets /admins/{uid}=true, /users/{uid}/type='admin', and an `admin:true`
// custom auth claim (reserved for future Storage/Firestore role checks). Run
// once per real admin to replace the demo seed accounts.
//
// Requires PRODUCTION credentials via Application Default Credentials: point
// GOOGLE_APPLICATION_CREDENTIALS at a service-account key with Firebase Admin
// and Auth Admin access (or use `gcloud auth application-default login`).
//
//   node functions/scripts/make-admin.js --email admin@ya.co.mz
//   node functions/scripts/make-admin.js --uid <auth-uid>
//
// Safety: refuses to run when an emulator host is configured.

const admin = require("firebase-admin");

function arg(flag) {
  const i = process.argv.indexOf(flag);
  return i !== -1 && i + 1 < process.argv.length ? process.argv[i + 1] : null;
}

async function main() {
  if (
    process.env.FIREBASE_DATABASE_EMULATOR_HOST ||
    process.env.FIREBASE_AUTH_EMULATOR_HOST
  ) {
    console.error(
      "Refusing to run: an emulator host is set. This script targets PRODUCTION."
    );
    process.exit(1);
  }

  const email = arg("--email");
  const uidArg = arg("--uid");
  if (!email && !uidArg) {
    console.error("Usage: node make-admin.js --email <email> | --uid <uid>");
    process.exit(1);
  }

  admin.initializeApp({
    projectId: "ya-app-z",
    databaseURL: "https://ya-app-z-default-rtdb.firebaseio.com",
  });

  let uid = uidArg;
  if (!uid) {
    const user = await admin.auth().getUserByEmail(email);
    uid = user.uid;
  }

  await admin.database().ref(`admins/${uid}`).set(true);
  await admin.database().ref(`users/${uid}/type`).set("admin");
  await admin.auth().setCustomUserClaims(uid, {admin: true});

  console.log(`OK: ${uid} is now a platform admin (RTDB + custom claim).`);
  process.exit(0);
}

main().catch((e) => {
  console.error("Failed:", e.message || e);
  process.exit(1);
});

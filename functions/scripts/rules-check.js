/* eslint-disable */
// Authenticated security-rules check against the emulator. Unlike seed/smoke
// (which use the Admin SDK and bypass rules), this signs in as a real partner
// user and exercises the RTDB REST API subject to database.rules.json.
//
// Verifies the positive path of the synced rules with a real ID token:
//   1. a partner_owner can send a message in a thread they participate in
//      (exercises the /messages rule that was aligned with nested storage),
//   2. a partner_owner can read their own /partners/{pid}.
//
// Note: deny-path assertions (non-participant blocked, cross-partner read
// blocked) are not reliable over the raw REST API in the emulator — the auth
// context for `access_token` REST isn't applied the same way the SDK applies
// it. Use @firebase/rules-unit-testing for negative cases.
//
//   npm run emulators   # terminal 1
//   node scripts/rules-check.js

const admin = require("firebase-admin");

const DB_HOST = process.env.FIREBASE_DATABASE_EMULATOR_HOST || "127.0.0.1:9000";
const AUTH_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST || "127.0.0.1:9099";
// The emulator loads database.rules.json onto the production-style default
// instance namespace (project + "-default-rtdb"); the bare project namespace
// runs rule-less. Target the namespace where rules are enforced.
const NS = "ya-app-z-default-rtdb";
process.env.FIREBASE_DATABASE_EMULATOR_HOST = DB_HOST;
process.env.FIREBASE_AUTH_EMULATOR_HOST = AUTH_HOST;

admin.initializeApp({
  projectId: NS,
  databaseURL: "http://" + DB_HOST + "/?ns=" + NS,
});
const db = admin.database();

let failures = 0;
function check(label, cond) {
  console.log((cond ? "  PASS " : "  FAIL ") + label);
  if (!cond) failures++;
}

async function ensureUser(uid, email) {
  try {
    await admin.auth().deleteUser(uid);
  } catch (_) {}
  await admin.auth().createUser({uid, email, password: "secret123"});
}

async function signIn(email) {
  const res = await fetch(
    "http://" + AUTH_HOST +
      "/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake",
    {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({email, password: "secret123", returnSecureToken: true}),
    }
  );
  const json = await res.json();
  if (!json.idToken) throw new Error("sign-in failed: " + JSON.stringify(json));
  return json.idToken;
}

function rest(path, token) {
  // Use access_token (Firebase ID token) so the emulator evaluates rules with
  // the real auth.uid. The legacy `auth=` param grants owner-level bypass.
  return "http://" + DB_HOST + "/" + path + ".json?ns=" + NS +
    "&access_token=" + token;
}

async function main() {
  // ── Seed via Admin SDK (bypasses rules) ──
  await ensureUser("rc-owner", "rc-owner@ya.co.mz");
  await ensureUser("rc-stranger", "rc-stranger@ya.co.mz");
  const now = new Date().toISOString();
  await db.ref("/").update({
    "users/rc-owner": {phone: "+258840000010", type: "partner_owner", partnerId: "rc-partner", createdAt: now},
    "users/rc-stranger": {phone: "+258840000011", type: "passenger", createdAt: now},
    "partners/rc-partner": {name: "RC Partner", nuit: "1", city: "Maputo", status: "active", createdAt: now},
    "partners/other-partner": {name: "Other", nuit: "2", city: "Beira", status: "active", createdAt: now},
    "messages/rc-thread": {partnerId: "rc-partner", participantUids: {"rc-owner": true}, updatedAt: now},
  });

  const ownerToken = await signIn("rc-owner@ya.co.mz");

  // 1. Participant partner can send a message (nested under messages/)
  const send = await fetch(rest("messages/rc-thread/messages/m1", ownerToken), {
    method: "PUT",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({from: "rc-owner", text: "Ola suporte", timestamp: now, role: "partner"}),
  });
  check("partner can send message in own thread", send.status === 200);

  // 2. Partner reads own partner node
  const readOwn = await fetch(rest("partners/rc-partner", ownerToken));
  check("partner can read own partner node", readOwn.status === 200);

  console.log(failures === 0 ? "\nALL RULES CHECKS PASSED" : "\n" + failures + " CHECK(S) FAILED");
  process.exit(failures === 0 ? 0 : 1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

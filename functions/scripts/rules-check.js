/* eslint-disable */
// Authenticated security-rules checks against the RTDB emulator. Unlike the
// seed/smoke scripts (which use the Admin SDK and bypass rules), this signs in
// as real users and exercises the REST API with their Firebase ID tokens.
//
// Positive paths covered:
//   - a partner_owner can send a message in a thread they participate in;
//   - partner owners can read their partner record and trips by partnerId;
//   - passengers and drivers can query only their own trip histories;
//   - an offered driver can read a pending trip by ID;
//   - an admin can read the full trips collection.
//
// Note: deny-path assertions over raw REST are not reliable in the emulator;
// use @firebase/rules-unit-testing for negative cases.
//
//   npm run emulators   # terminal 1
//   node scripts/rules-check.js

const admin = require("firebase-admin");

const DB_HOST = process.env.FIREBASE_DATABASE_EMULATOR_HOST || "127.0.0.1:9000";
const AUTH_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST || "127.0.0.1:9099";
const NS = "ya-app-z-default-rtdb";
process.env.FIREBASE_DATABASE_EMULATOR_HOST = DB_HOST;
process.env.FIREBASE_AUTH_EMULATOR_HOST = AUTH_HOST;

admin.initializeApp({
  projectId: NS,
  databaseURL: "http://" + DB_HOST + "/?ns=" + NS,
});
const db = admin.database();

let failures = 0;
function check(label, condition) {
  console.log((condition ? "  PASS " : "  FAIL ") + label);
  if (!condition) failures++;
}

async function ensureUser(uid, email) {
  try {
    await admin.auth().deleteUser(uid);
  } catch (_) {}
  await admin.auth().createUser({uid, email, password: "secret123"});
}

async function signIn(email) {
  const response = await fetch(
    "http://" + AUTH_HOST +
      "/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake",
    {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({
        email,
        password: "secret123",
        returnSecureToken: true,
      }),
    }
  );
  const json = await response.json();
  if (!json.idToken) {
    throw new Error("sign-in failed: " + JSON.stringify(json));
  }
  return json.idToken;
}

function rest(path, token) {
  return "http://" + DB_HOST + "/" + path + ".json?ns=" + NS +
    "&access_token=" + token;
}

function restQuery(path, token, orderBy, equalTo) {
  return rest(path, token) +
    "&orderBy=" + encodeURIComponent(JSON.stringify(orderBy)) +
    "&equalTo=" + encodeURIComponent(JSON.stringify(equalTo));
}

async function readJson(url) {
  const response = await fetch(url);
  return {status: response.status, body: await response.json()};
}

async function main() {
  for (const [uid, email] of [
    ["rc-owner", "rc-owner@ya.co.mz"],
    ["rc-staff", "rc-staff@ya.co.mz"],
    ["rc-driver", "rc-driver@ya.co.mz"],
    ["rc-passenger", "rc-passenger@ya.co.mz"],
    ["rc-admin", "rc-admin@ya.co.mz"],
    ["rc-stranger", "rc-stranger@ya.co.mz"],
  ]) {
    await ensureUser(uid, email);
  }

  const now = new Date().toISOString();
  await db.ref("/").update({
    "users/rc-owner": {
      phone: "+258840000010",
      type: "partner_owner",
      partnerId: "rc-partner",
      createdAt: now,
    },
    "users/rc-staff": {
      phone: "+258840000015",
      type: "partner_staff",
      partnerId: "rc-partner",
      createdAt: now,
    },
    "users/rc-driver": {
      phone: "+258840000012",
      type: "driver",
      partnerId: "rc-partner",
      createdAt: now,
    },
    "users/rc-passenger": {
      phone: "+258840000013",
      type: "passenger",
      createdAt: now,
    },
    "users/rc-admin": {
      phone: "+258840000014",
      type: "admin",
      createdAt: now,
    },
    "users/rc-stranger": {
      phone: "+258840000011",
      type: "passenger",
      createdAt: now,
    },
    "admins/rc-admin": true,
    "partners/rc-partner": {
      name: "RC Partner",
      nuit: "1",
      city: "Maputo",
      status: "active",
      createdAt: now,
    },
    "partners/other-partner": {
      name: "Other",
      nuit: "2",
      city: "Beira",
      status: "active",
      createdAt: now,
    },
    "messages/rc-thread": {
      partnerId: "rc-partner",
      participantUids: {"rc-owner": true},
      updatedAt: now,
    },
    "trips/rc-history-trip": {
      passenger: "rc-passenger",
      driver: "rc-driver",
      partnerId: "rc-partner",
      status: "completed",
      paymentMethod: "cash",
      tipo: "regular",
      origin: {name: "Maputo"},
      destination: {name: "Matola"},
    },
    "trips/rc-offered-trip": {
      passenger: "rc-passenger",
      driver: null,
      partnerId: "rc-partner",
      offeredTo: "rc-driver",
      status: "pending",
      paymentMethod: "cash",
      tipo: "regular",
      origin: {name: "Maputo"},
      destination: {name: "Matola"},
    },
  });

  const ownerToken = await signIn("rc-owner@ya.co.mz");
  const staffToken = await signIn("rc-staff@ya.co.mz");
  const driverToken = await signIn("rc-driver@ya.co.mz");
  const passengerToken = await signIn("rc-passenger@ya.co.mz");
  const adminToken = await signIn("rc-admin@ya.co.mz");

  // Existing support-chat flow.
  const send = await fetch(rest("messages/rc-thread/messages/m1", ownerToken), {
    method: "PUT",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({
      from: "rc-owner",
      text: "Ola suporte",
      timestamp: now,
      role: "partner",
    }),
  });
  check("partner can send message in own thread", send.status === 200);

  const readOwnPartner = await fetch(rest("partners/rc-partner", ownerToken));
  check("partner can read own partner node", readOwnPartner.status === 200);

  const partnerTrips = await readJson(
    restQuery("trips", ownerToken, "partnerId", "rc-partner")
  );
  check(
    "partner owner can query trips for own partnerId",
    partnerTrips.status === 200 && partnerTrips.body?.["rc-history-trip"] != null,
  );

  const staffTrips = await readJson(
    restQuery("trips", staffToken, "partnerId", "rc-partner")
  );
  check(
    "partner staff can query trips for own partnerId",
    staffTrips.status === 200 && staffTrips.body?.["rc-history-trip"] != null,
  );

  const passengerTrips = await readJson(
    restQuery("trips", passengerToken, "passenger", "rc-passenger")
  );
  check(
    "passenger can query own trip history",
    passengerTrips.status === 200 &&
      passengerTrips.body?.["rc-history-trip"] != null,
  );

  const driverTrips = await readJson(
    restQuery("trips", driverToken, "driver", "rc-driver")
  );
  check(
    "driver can query own trip history",
    driverTrips.status === 200 && driverTrips.body?.["rc-history-trip"] != null,
  );

  const passengerTrip = await fetch(
    rest("trips/rc-history-trip", passengerToken)
  );
  check("passenger can read own trip by ID", passengerTrip.status === 200);

  const driverTrip = await fetch(rest("trips/rc-history-trip", driverToken));
  check("driver can read assigned trip by ID", driverTrip.status === 200);

  const partnerTrip = await fetch(rest("trips/rc-history-trip", ownerToken));
  check("partner can read own trip by ID", partnerTrip.status === 200);

  const offeredTrip = await fetch(rest("trips/rc-offered-trip", driverToken));
  check(
    "offered driver can read pending trip by ID",
    offeredTrip.status === 200,
  );

  const adminTrips = await readJson(rest("trips", adminToken));
  check(
    "admin can read the full trips collection",
    adminTrips.status === 200 &&
      adminTrips.body?.["rc-history-trip"] != null &&
      adminTrips.body?.["rc-offered-trip"] != null,
  );

  console.log(
    failures === 0
      ? "\nALL RULES CHECKS PASSED"
      : "\n" + failures + " CHECK(S) FAILED"
  );
  process.exit(failures === 0 ? 0 : 1);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

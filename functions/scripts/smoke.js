/* eslint-disable */
// End-to-end smoke test against the running emulator. Verifies that:
//  1. the seed data is readable,
//  2. the onUserCreated trigger applies a pending driver invite when an
//     invited phone signs up (the core app<->panel onboarding flow), and
//  3. the driver commission wallet: a completed cash trip debits the driver,
//     crossing the float blocks him, and a confirmed top-up credits and
//     unblocks (the YA Direct cash cycle).
//
//   npm run emulators   # terminal 1 (+ npm run seed)
//   node scripts/smoke.js

const admin = require("firebase-admin");

const HOST = process.env.FIREBASE_DATABASE_EMULATOR_HOST || "127.0.0.1:9000";
process.env.FIREBASE_DATABASE_EMULATOR_HOST = HOST;
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "ya-app-z";
admin.initializeApp({
  projectId: "ya-app-z",
  databaseURL: "http://" + HOST + "/?ns=ya-app-z-default-rtdb",
});
const db = admin.database();

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
let failures = 0;
function check(label, cond) {
  console.log((cond ? "  PASS " : "  FAIL ") + label);
  if (!cond) failures++;
}

async function main() {
  // 1. Seed readable
  const partner = (await db.ref("partners/demo-partner").get()).val();
  check("partner seed readable", partner && partner.name === "Maputo Executive");
  const vehicles = partner && partner.vehicles ? Object.keys(partner.vehicles) : [];
  check("partner has vehicles", vehicles.length === 2);
  const trip = (await db.ref("trips/demo-trip-1").get()).val();
  check("trip carries partnerId", trip && trip.partnerId === "demo-partner");
  check("trip has flat completedAt + amountMtn", trip && !!trip.completedAt && trip.amountMtn === 850);

  // 2. onUserCreated applies a pending invite
  const phone = "+258 82 111 2222";
  const key = phone.replace(/\D/g, "");
  const uid = "smoke-newdriver";
  await db.ref("users/" + uid).remove();
  await db.ref("partnerInvites/" + key).set({
    partnerId: "demo-partner",
    role: "driver",
    vehicleId: "demo-vehicle",
  });
  // Simulate the app creating the profile on first OTP sign-in.
  await db.ref("users/" + uid).set({
    phone: phone,
    name: "Novo Motorista",
    type: "passenger",
    createdAt: new Date().toISOString(),
  });

  let user = null;
  for (let i = 0; i < 25; i++) {
    await sleep(400);
    user = (await db.ref("users/" + uid).get()).val();
    if (user && user.type === "driver") break;
  }
  check("invited signup promoted to driver", user && user.type === "driver");
  check("invited signup linked to partner", user && user.partnerId === "demo-partner");
  check("invited signup linked to vehicle", user && user.vehicleId === "demo-vehicle");
  const inviteGone = (await db.ref("partnerInvites/" + key).get()).val();
  check("invite consumed", inviteGone === null);

  // cleanup
  await db.ref("users/" + uid).remove();

  // 3. Driver commission wallet (YA Direct cash cycle)
  const wPartner = "smoke-ya-direct";
  const wDriver = "smoke-wdriver";
  await db.ref("driverWallets/" + wPartner).remove();
  await db.ref("partners/" + wPartner).set({
    name: "YA Direct (smoke)",
    status: "active",
    requiresWalletSettlement: true,
    commissionFloatMtn: 100, // low float: two trips cross it
  });
  await db.ref("users/" + wDriver).set({
    name: "Motorista Directo",
    type: "driver",
    partnerId: wPartner,
    phone: "+258 84 000 9999",
  });

  const wallet = () =>
    db.ref("driverWallets/" + wPartner + "/" + wDriver).get().then((s) => s.val());
  const pollWallet = async (pred) => {
    for (let i = 0; i < 25; i++) {
      await sleep(400);
      const w = await wallet();
      if (w && pred(w)) return w;
    }
    return wallet();
  };
  const makeTrip = async (id, price, method, driverId) => {
    // Create in a pre-completed state, then flip the status so the
    // onTripStatusChanged trigger fires (create-with-completed would not).
    await db.ref("trips/" + id).set({
      partnerId: wPartner,
      driver: driverId,
      passenger: "smoke-pax",
      estimatedPrice: price,
      paymentMethod: method,
      tripType: "regular",
      status: "started",
      createdAt: new Date().toISOString(),
    });
    await db.ref("trips/" + id + "/status").set("completed");
  };

  // Cash trip of 500 MT at the default 12% => -60
  await makeTrip("smoke-wtrip-1", 500, "", wDriver);
  let w = await pollWallet((x) => x.balance === -60);
  check("cash trip debits commission (-60)", w && w.balance === -60);
  check("debit entry keyed by tripId",
    w && w.entries && !!w.entries["smoke-wtrip-1"]);
  check("not blocked before the float", w && !w.blockedAt);

  // Second cash trip crosses the float (-120 <= -100) => blocked
  await makeTrip("smoke-wtrip-3", 500, "", wDriver);
  w = await pollWallet((x) => x.balance === -120);
  check("second cash trip debits (-120)", w && w.balance === -120);
  check("debt past float blocks the driver", w && !!w.blockedAt);

  // Top-up via the PSP webhook: credit + unblock
  const topupRef = db.ref("walletTopups").push();
  await topupRef.set({
    driverId: wDriver,
    partnerId: wPartner,
    amountMtn: 150,
    method: "mpesa",
    status: "pending",
    pspRef: "smoke-psp-1",
    createdAt: new Date().toISOString(),
  });
  const fnHost = process.env.FUNCTIONS_EMULATOR_HOST || "127.0.0.1:5001";
  const res = await fetch(
    "http://" + fnHost + "/ya-app-z/us-central1/walletTopupCallback",
    {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({pspRef: "smoke-psp-1", status: "paid"}),
    }
  );
  check("topup webhook accepted", res.status === 200);
  w = await pollWallet((x) => x.balance === 30);
  check("topup credits the wallet (+150 => 30)", w && w.balance === 30);
  check("back above float unblocks", w && !w.blockedAt);
  const topupAfter = (await topupRef.get()).val();
  check("topup marked paid", topupAfter && topupAfter.status === "paid");

  // Webhook retry must be a no-op (idempotent by pspRef)
  await fetch(
    "http://" + fnHost + "/ya-app-z/us-central1/walletTopupCallback",
    {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({pspRef: "smoke-psp-1", status: "paid"}),
    }
  );
  await sleep(1000);
  w = await wallet();
  check("webhook retry does not double-credit", w && w.balance === 30);

  // Digital trips credit the driver's net share (YA Direct has no partner to
  // pay out to — the wallet is the driver's one running account). A second
  // driver keeps this independent of the cash/topup narrative above.
  const wDriver2 = "smoke-wdriver-2";
  await db.ref("users/" + wDriver2).set({
    name: "Motorista Directo 2",
    type: "driver",
    partnerId: wPartner,
    phone: "+258 84 000 9998",
  });
  const wallet2 = () =>
    db.ref("driverWallets/" + wPartner + "/" + wDriver2).get().then((s) => s.val());
  const pollWallet2 = async (pred) => {
    for (let i = 0; i < 25; i++) {
      await sleep(400);
      const v = await wallet2();
      if (v && pred(v)) return v;
    }
    return wallet2();
  };

  // Cash trip pushes into debt past the float => blocked.
  await makeTrip("smoke-wtrip-d1", 500, "", wDriver2);
  let w2 = await pollWallet2((x) => x.balance === -60);
  check("driver2 cash trip debits (-60)", w2 && w2.balance === -60);

  await makeTrip("smoke-wtrip-d2", 500, "", wDriver2);
  w2 = await pollWallet2((x) => x.balance === -120);
  check("driver2 second cash trip blocks", w2 && !!w2.blockedAt);

  // Digital trip (mpesa) at 12% => net credit of 440, enough to clear the
  // debt and unblock the driver automatically (no top-up needed).
  await makeTrip("smoke-wtrip-d3", 500, "mpesa", wDriver2);
  w2 = await pollWallet2((x) => x.balance === 320);
  check("digital trip credits net earning (-120 + 440 = 320)",
    w2 && w2.balance === 320);
  check("digital earning entry type is 'earning'",
    w2 && w2.entries && w2.entries["smoke-wtrip-d3"]?.type === "earning");
  check("earning offsets debt and unblocks the driver", w2 && !w2.blockedAt);

  // cleanup wallet fixtures
  await db.ref("users/" + wDriver).remove();
  await db.ref("users/" + wDriver2).remove();
  await db.ref("partners/" + wPartner).remove();
  await db.ref("driverWallets/" + wPartner).remove();
  for (const t of [
    "smoke-wtrip-1", "smoke-wtrip-3",
    "smoke-wtrip-d1", "smoke-wtrip-d2", "smoke-wtrip-d3",
  ]) {
    await db.ref("trips/" + t).remove();
  }
  await topupRef.remove();

  // 4. onVehicleChanged mirrors the partner vehicle onto the driver's
  //    public profile (so passengers see real vehicles, not a fake catalog).
  const vDriver = "smoke-vdriver";
  await db.ref("users/" + vDriver).remove();
  await db.ref("users/" + vDriver).set({type: "driver", partnerId: "demo-partner"});
  const vRef = db.ref("partners/demo-partner/vehicles/smoke-veh");
  await vRef.set({
    plate: "MOT-01-NPL",
    model: "Honda 125",
    type: "moto",
    category: "moto",
    status: "available",
    driverId: vDriver,
    photoUrl: "https://x/moto.png",
  });
  let mirror = null;
  for (let i = 0; i < 25; i++) {
    await sleep(400);
    mirror = (await db.ref("users/" + vDriver + "/vehicle").get()).val();
    if (mirror) break;
  }
  check("vehicle mirrored to driver profile", mirror && mirror.model === "Honda 125");
  check("mirror carries category for filtering", mirror && mirror.category === "moto");
  check("mirror carries real plate + photo",
    mirror && mirror.plate === "MOT-01-NPL" && !!mirror.photoUrl);

  // Unassign → mirror cleared
  await vRef.child("driverId").remove();
  let cleared = mirror;
  for (let i = 0; i < 25; i++) {
    await sleep(400);
    cleared = (await db.ref("users/" + vDriver + "/vehicle").get()).val();
    if (cleared === null) break;
  }
  check("mirror cleared when driver unassigned", cleared === null);

  await db.ref("users/" + vDriver).remove();
  await vRef.remove();

  // 5. Ratings: the passenger submits via the deployed submitRating callable
  //    (server resolves driver/passenger/status from the trip — the client
  //    never asserts a driverId), and the RTDB rules let the driver read
  //    their own ratings while denying a stranger. This exercises real Auth
  //    identities + the deployed rules, not just the pure-function logic.
  const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST || "127.0.0.1:9099";
  async function signUpTestUser(email) {
    // Idempotent across reruns: sign in if the emulator already has this
    // test account from a previous run, sign up otherwise.
    for (const op of ["signInWithPassword", "signUp"]) {
      const res = await fetch(
        "http://" + authHost + "/identitytoolkit.googleapis.com/v1/accounts:" + op + "?key=fake-api-key",
        {
          method: "POST",
          headers: {"content-type": "application/json"},
          body: JSON.stringify({email, password: "smoke123456", returnSecureToken: true}),
        }
      );
      const json = await res.json();
      if (json.idToken) return {uid: json.localId, idToken: json.idToken};
    }
    throw new Error("signUpTestUser failed for " + email);
  }
  async function callFunction(name, idToken, data) {
    const res = await fetch(
      "http://" + fnHost + "/ya-app-z/us-central1/" + name,
      {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "Authorization": "Bearer " + idToken,
        },
        body: JSON.stringify({data}),
      }
    );
    return {status: res.status, body: await res.json()};
  }
  async function readAsUser(path, idToken) {
    const res = await fetch(
      "http://127.0.0.1:9000/" + path + ".json?ns=ya-app-z-default-rtdb&auth=" + idToken
    );
    return {status: res.status, body: await res.json()};
  }

  const rPax = await signUpTestUser("smoke-rating-pax@test.com");
  const rDriver = await signUpTestUser("smoke-rating-driver@test.com");
  const rStranger = await signUpTestUser("smoke-rating-stranger@test.com");

  await db.ref("users/" + rDriver.uid).set({name: "Motorista Avaliado", type: "driver"});
  await db.ref("trips/smoke-rtrip").set({
    passenger: rPax.uid,
    driver: rDriver.uid,
    status: "completed",
    partnerId: "demo-partner",
  });

  const submitRes = await callFunction("submitRating", rPax.idToken, {
    tripId: "smoke-rtrip",
    value: 4.5,
    comment: "Boa viagem!",
  });
  check("submitRating accepted (200)", submitRes.status === 200);
  check("submitRating not already-rated", submitRes.body?.result?.alreadyRated === false);

  const driverAfter = (await db.ref("users/" + rDriver.uid).get()).val();
  check("driver's running average updated (4.5)", driverAfter?.rating === 4.5);
  check("driver's ratingCount updated (1)", driverAfter?.ratingCount === 1);

  const ratingEntry = (await db.ref("ratings/" + rDriver.uid + "/smoke-rtrip").get()).val();
  check("rating entry has the right shape",
    ratingEntry && ratingEntry.value === 4.5 &&
    ratingEntry.passengerId === rPax.uid && ratingEntry.comment === "Boa viagem!");

  // A second submission for the same trip must be a no-op (idempotent),
  // not a second fold into the average.
  const retryRes = await callFunction("submitRating", rPax.idToken, {
    tripId: "smoke-rtrip",
    value: 1,
  });
  check("submitRating retry reports alreadyRated",
    retryRes.body?.result?.alreadyRated === true);
  const driverAfterRetry = (await db.ref("users/" + rDriver.uid).get()).val();
  check("average unchanged by the idempotent retry", driverAfterRetry?.rating === 4.5);

  // Rules: the driver can read their own ratings subtree...
  const driverRead = await readAsUser("ratings/" + rDriver.uid, rDriver.idToken);
  check("driver can read own ratings via rules",
    driverRead.status === 200 && driverRead.body && driverRead.body["smoke-rtrip"]);

  // ...but a stranger (any other authenticated user) is denied.
  const strangerRead = await readAsUser("ratings/" + rDriver.uid, rStranger.idToken);
  check("stranger is denied reading another driver's ratings",
    strangerRead.status !== 200 || strangerRead.body === null);

  await db.ref("users/" + rDriver.uid).remove();
  await db.ref("trips/smoke-rtrip").remove();
  await db.ref("ratings/" + rDriver.uid).remove();

  console.log(failures === 0 ? "\nALL SMOKE CHECKS PASSED" : "\n" + failures + " CHECK(S) FAILED");
  process.exit(failures === 0 ? 0 : 1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

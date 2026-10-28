/* eslint-disable */
// Checks read permissions for /trips against the RTDB emulator using the
// Firebase Rules Unit Testing SDK, including negative cases that raw REST
// checks cannot reliably evaluate.
//
// Run with: npm run emulators (terminal 1), then npm run rules-unit-test.

const fs = require("fs");
const path = require("path");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const {
  equalTo,
  get,
  orderByChild,
  query,
  ref,
  set,
} = require("firebase/database");

const PROJECT_ID = "ya-app-z";
const DB_HOST = process.env.FIREBASE_DATABASE_EMULATOR_HOST || "127.0.0.1:9000";
const [HOST, PORT] = DB_HOST.split(":");
const RULES_PATH = path.resolve(__dirname, "../../database.rules.json");

async function main() {
  const testEnvironment = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    database: {
      rules: fs.readFileSync(RULES_PATH, "utf8"),
      host: HOST,
      port: Number(PORT),
    },
  });

  try {
    await testEnvironment.clearDatabase();
    await testEnvironment.withSecurityRulesDisabled(async (context) => {
      const database = context.database();
      await set(ref(database, "/"), {
        admins: {admin: true},
        users: {
          owner: {type: "partner_owner", partnerId: "partner-a"},
          staff: {type: "partner_staff", partnerId: "partner-a"},
          driver: {type: "driver", partnerId: "partner-a"},
          passenger: {type: "passenger"},
          otherPassenger: {type: "passenger"},
          support: {type: "support"},
          stranger: {type: "passenger"},
        },
        trips: {
          ownTrip: {
            passenger: "passenger",
            driver: "driver",
            partnerId: "partner-a",
            status: "completed",
            paymentMethod: "cash",
            tipo: "regular",
            origin: {name: "Maputo"},
            destination: {name: "Matola"},
          },
          otherTrip: {
            passenger: "otherPassenger",
            driver: "otherDriver",
            partnerId: "partner-b",
            status: "completed",
            paymentMethod: "cash",
            tipo: "regular",
            origin: {name: "Beira"},
            destination: {name: "Dondo"},
          },
          offeredTrip: {
            passenger: "passenger",
            driver: null,
            partnerId: "partner-a",
            offeredTo: "driver",
            status: "pending",
            paymentMethod: "cash",
            tipo: "regular",
            origin: {name: "Maputo"},
            destination: {name: "Matola"},
          },
        },
      });
    });

    const passengerDb = testEnvironment.authenticatedContext("passenger").database();
    const driverDb = testEnvironment.authenticatedContext("driver").database();
    const ownerDb = testEnvironment.authenticatedContext("owner").database();
    const staffDb = testEnvironment.authenticatedContext("staff").database();
    const adminDb = testEnvironment.authenticatedContext("admin").database();
    const supportDb = testEnvironment.authenticatedContext("support").database();
    const strangerDb = testEnvironment.authenticatedContext("stranger").database();
    const otherDriverDb = testEnvironment
      .authenticatedContext("otherDriver")
      .database();

    const passengerTrips = await assertSucceeds(
      get(
        query(
          ref(passengerDb, "trips"),
          orderByChild("passenger"),
          equalTo("passenger"),
        ),
      ),
    );
    check(
      "passenger query returns only their own history",
      passengerTrips.hasChild("ownTrip") && !passengerTrips.hasChild("otherTrip"),
    );
    await expectFails("passenger cannot read all trips", get(ref(passengerDb, "trips")));
    await expectFails(
      "passenger cannot read another passenger's trip",
      get(ref(passengerDb, "trips/otherTrip")),
    );
    await expectFails(
      "passenger cannot query another passenger's trips",
      get(
        query(
          ref(passengerDb, "trips"),
          orderByChild("passenger"),
          equalTo("otherPassenger"),
        ),
      ),
    );

    const driverTrips = await assertSucceeds(
      get(
        query(
          ref(driverDb, "trips"),
          orderByChild("driver"),
          equalTo("driver"),
        ),
      ),
    );
    check(
      "driver query returns assigned trips only",
      driverTrips.hasChild("ownTrip") && !driverTrips.hasChild("otherTrip"),
    );
    await assertSucceeds(get(ref(driverDb, "trips/ownTrip")));
    await assertSucceeds(get(ref(driverDb, "trips/offeredTrip")));
    await expectFails(
      "offered trip cannot be read by a different driver",
      get(ref(otherDriverDb, "trips/offeredTrip")),
    );
    await expectFails(
      "driver cannot use partnerId to read the fleet's trips",
      get(
        query(
          ref(driverDb, "trips"),
          orderByChild("partnerId"),
          equalTo("partner-a"),
        ),
      ),
    );

    const ownerTrips = await assertSucceeds(
      get(
        query(
          ref(ownerDb, "trips"),
          orderByChild("partnerId"),
          equalTo("partner-a"),
        ),
      ),
    );
    check(
      "partner owner can query trips for their partner",
      ownerTrips.hasChild("ownTrip") && !ownerTrips.hasChild("otherTrip"),
    );
    await assertSucceeds(get(ref(ownerDb, "trips/ownTrip")));
    await expectFails(
      "partner owner cannot read a different partner's trip",
      get(ref(ownerDb, "trips/otherTrip")),
    );
    await expectFails(
      "partner owner cannot query a different partnerId",
      get(
        query(
          ref(ownerDb, "trips"),
          orderByChild("partnerId"),
          equalTo("partner-b"),
        ),
      ),
    );
    await assertSucceeds(
      get(
        query(
          ref(staffDb, "trips"),
          orderByChild("partnerId"),
          equalTo("partner-a"),
        ),
      ),
    );

    await expectFails("support cannot read the trips collection", get(ref(supportDb, "trips")));
    await expectFails(
      "unrelated authenticated user cannot read a trip",
      get(ref(strangerDb, "trips/ownTrip")),
    );
    const allTrips = await assertSucceeds(get(ref(adminDb, "trips")));
    check(
      "admin can read the full trips collection",
      allTrips.hasChild("ownTrip") &&
        allTrips.hasChild("otherTrip") &&
        allTrips.hasChild("offeredTrip"),
    );

    console.log("\nALL TRIP RULES UNIT CHECKS PASSED");
  } finally {
    await testEnvironment.cleanup();
  }
}

async function expectFails(label, operation) {
  await assertFails(operation);
  console.log("  PASS " + label);
}

function check(label, condition) {
  if (!condition) throw new Error("Check failed: " + label);
  console.log("  PASS " + label);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

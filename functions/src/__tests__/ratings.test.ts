import {submitRatingCore} from "../ratings";
import {db, expectHttpsError} from "./fake-db";

function seedTrip(overrides: Record<string, unknown> = {}) {
  return db({
    trips: {
      t1: {
        passenger: "pax1",
        driver: "drv1",
        status: "completed",
        ...overrides,
      },
    },
    users: {drv1: {name: "Motorista", type: "driver"}},
  });
}

describe("submitRatingCore", () => {
  test("writes the rating and folds it into the driver's average", async () => {
    const d = seedTrip();
    const res = await submitRatingCore(d, "pax1", {tripId: "t1", value: 5, comment: "Óptimo!"});
    expect(res.alreadyRated).toBe(false);
    expect(d.store.ratings.drv1.t1).toMatchObject({
      driverId: "drv1",
      passengerId: "pax1",
      tripId: "t1",
      value: 5,
      comment: "Óptimo!",
    });
    expect(d.store.users.drv1.rating).toBe(5);
    expect(d.store.users.drv1.ratingCount).toBe(1);
  });

  test("computes a running average across multiple ratings", async () => {
    const d = seedTrip();
    await submitRatingCore(d, "pax1", {tripId: "t1", value: 5});
    d.store.trips.t2 = {passenger: "pax2", driver: "drv1", status: "completed"};
    await submitRatingCore(d, "pax2", {tripId: "t2", value: 3});
    expect(d.store.users.drv1.rating).toBe(4); // (5+3)/2
    expect(d.store.users.drv1.ratingCount).toBe(2);
  });

  test("is idempotent: a second submission for the same trip does not shift the average", async () => {
    const d = seedTrip();
    await submitRatingCore(d, "pax1", {tripId: "t1", value: 5});
    const second = await submitRatingCore(d, "pax1", {tripId: "t1", value: 1});
    expect(second.alreadyRated).toBe(true);
    expect(d.store.users.drv1.rating).toBe(5);
    expect(d.store.users.drv1.ratingCount).toBe(1);
  });

  test("rejects a value outside 1-5", async () => {
    const d = seedTrip();
    await expectHttpsError(
      submitRatingCore(d, "pax1", {tripId: "t1", value: 6}),
      "invalid-argument"
    );
  });

  test("rejects a caller who is not the trip's passenger", async () => {
    const d = seedTrip();
    await expectHttpsError(
      submitRatingCore(d, "someone-else", {tripId: "t1", value: 5}),
      "permission-denied"
    );
  });

  test("rejects a trip that is not completed", async () => {
    const d = seedTrip({status: "started"});
    await expectHttpsError(
      submitRatingCore(d, "pax1", {tripId: "t1", value: 5}),
      "failed-precondition"
    );
  });

  test("rejects an unknown trip", async () => {
    const d = db({});
    await expectHttpsError(
      submitRatingCore(d, "pax1", {tripId: "ghost", value: 5}),
      "not-found"
    );
  });

  test("preserves other fields on the driver's profile", async () => {
    const d = db({
      trips: {t1: {passenger: "pax1", driver: "drv1", status: "completed"}},
      users: {drv1: {name: "Motorista", phone: "+258840000000", vehicleId: "v1"}},
    });
    await submitRatingCore(d, "pax1", {tripId: "t1", value: 4});
    expect(d.store.users.drv1.name).toBe("Motorista");
    expect(d.store.users.drv1.phone).toBe("+258840000000");
    expect(d.store.users.drv1.vehicleId).toBe("v1");
  });
});

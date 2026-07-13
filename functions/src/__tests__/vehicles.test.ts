import {mirrorVehicleCore} from "../vehicles";
import {db} from "./fake-db";

describe("mirrorVehicleCore", () => {
  test("mirrors an assigned vehicle onto the driver's public profile", async () => {
    const d = db({users: {drv: {name: "M", type: "driver"}}});
    await mirrorVehicleCore(d as never, "p1", "v1", null, {
      driverId: "drv",
      model: "Toyota Vitz",
      plate: "AAA-01-MP",
      category: "economico",
      seats: 4,
      photoUrl: "https://x/car.png",
    });
    expect(d.store.users.drv.vehicle).toMatchObject({
      vehicleId: "v1",
      partnerId: "p1",
      model: "Toyota Vitz",
      plate: "AAA-01-MP",
      category: "economico",
      photoUrl: "https://x/car.png",
    });
  });

  test("defaults category to economico when absent", async () => {
    const d = db({});
    await mirrorVehicleCore(d as never, "p1", "v1", null, {driverId: "drv"});
    expect(d.store.users.drv.vehicle.category).toBe("economico");
  });

  test("clears the mirror when the driver is unassigned", async () => {
    const d = db({users: {drv: {vehicle: {vehicleId: "v1", partnerId: "p1"}}}});
    await mirrorVehicleCore(
      d as never,
      "p1",
      "v1",
      {driverId: "drv", model: "Vitz"},
      {model: "Vitz"} // driverId removed
    );
    expect(d.store.users.drv.vehicle).toBeUndefined();
  });

  test("moves the mirror to the new driver on reassign", async () => {
    const d = db({users: {old: {vehicle: {vehicleId: "v1"}}, neu: {}}});
    await mirrorVehicleCore(
      d as never,
      "p1",
      "v1",
      {driverId: "old"},
      {driverId: "neu", model: "Vitz"}
    );
    expect(d.store.users.old.vehicle).toBeUndefined();
    expect(d.store.users.neu.vehicle).toMatchObject({vehicleId: "v1"});
  });

  test("does not clear a mirror the driver already replaced", async () => {
    // old driver moved to v2 already; deleting v1 must not wipe v2's mirror.
    const d = db({users: {old: {vehicle: {vehicleId: "v2"}}}});
    await mirrorVehicleCore(d as never, "p1", "v1", {driverId: "old"}, null);
    expect(d.store.users.old.vehicle).toMatchObject({vehicleId: "v2"});
  });

  test("clears the mirror when the vehicle is deleted", async () => {
    const d = db({users: {drv: {vehicle: {vehicleId: "v1"}}}});
    await mirrorVehicleCore(d as never, "p1", "v1", {driverId: "drv"}, null);
    expect(d.store.users.drv.vehicle).toBeUndefined();
  });
});

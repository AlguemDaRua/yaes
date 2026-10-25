import {mirrorVehicleCore} from "../vehicles";
import {db} from "./fake-db";

describe("mirrorVehicleCore", () => {
  test("mirrors optional vehicle details without changing direct driver categories", async () => {
    const d = db({
      users: {drv: {name: "M", type: "driver"}},
      drivers: {drv: {categories: {moto: true}}},
    });
    await mirrorVehicleCore(d as never, "p1", "v1", null, {
      driverId: "drv",
      model: "Toyota Vitz",
      plate: "AAA-01-MP",
      seats: 4,
      photoUrl: "https://x/car.png",
    });
    expect(d.store.users.drv.vehicle).toMatchObject({
      vehicleId: "v1",
      partnerId: "p1",
      model: "Toyota Vitz",
      plate: "AAA-01-MP",
      photoUrl: "https://x/car.png",
    });
    expect(d.store.users.drv.vehicle).not.toHaveProperty("categories");
    expect(d.store.drivers.drv).toEqual({categories: {moto: true}});
  });

  test("does not create driver categories from partner vehicle records", async () => {
    const d = db({});
    await mirrorVehicleCore(d as never, "p1", "v1", null, {driverId: "drv"});
    expect(d.store.users.drv.vehicle).not.toHaveProperty("category");
    expect(d.store.drivers?.drv).toBeUndefined();
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
    const d = db({
      users: {old: {vehicle: {vehicleId: "v1"}}, neu: {}},
      drivers: {old: {categories: {economico: true}}},
    });
    await mirrorVehicleCore(
      d as never,
      "p1",
      "v1",
      {driverId: "old"},
      {driverId: "neu", model: "Vitz"}
    );
    expect(d.store.users.old.vehicle).toBeUndefined();
    expect(d.store.drivers.old).toEqual({categories: {economico: true}});
    expect(d.store.users.neu.vehicle).toMatchObject({vehicleId: "v1"});
    expect(d.store.drivers.neu).toBeUndefined();
  });

  test("does not clear a mirror the driver already replaced", async () => {
    // old driver moved to v2 already; deleting v1 must not wipe v2's mirror.
    const d = db({users: {old: {vehicle: {vehicleId: "v2"}}}});
    await mirrorVehicleCore(d as never, "p1", "v1", {driverId: "old"}, null);
    expect(d.store.users.old.vehicle).toMatchObject({vehicleId: "v2"});
  });

  test("clears the mirror when the vehicle is deleted", async () => {
    const d = db({
      users: {drv: {vehicle: {vehicleId: "v1"}}},
      drivers: {
        drv: {
          vehicleId: "v1",
          category: "confort",
          categories: {confort: true},
        },
      },
    });
    await mirrorVehicleCore(d as never, "p1", "v1", {driverId: "drv"}, null);
    expect(d.store.users.drv.vehicle).toBeUndefined();
    expect(d.store.drivers.drv).toEqual({
      vehicleId: "v1",
      category: "confort",
      categories: {confort: true},
    });
  });
});

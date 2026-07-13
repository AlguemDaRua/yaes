import {recordNotification, recordNotificationForAudience} from "../notify";
import {db} from "./fake-db";

describe("recordNotification", () => {
  test("writes a notification entry under /notifications/{uid}", async () => {
    const d = db();
    await recordNotification(d, "uid-1", {
      title: "Motorista a caminho!",
      body: "O seu motorista aceitou a viagem.",
      type: "trip_accepted",
      tripId: "trip-1",
    });
    const entries = Object.values(
      d.store.notifications["uid-1"] as Record<string, unknown>
    );
    expect(entries).toHaveLength(1);
    expect(entries[0]).toMatchObject({
      title: "Motorista a caminho!",
      type: "trip_accepted",
      tripId: "trip-1",
      read: false,
    });
  });

  test("omits tripId when absent", async () => {
    const d = db();
    await recordNotification(d, "uid-1", {
      title: "Viagem Agendada!",
      body: "...",
      type: "schedule_created",
    });
    const entries = Object.values(
      d.store.notifications["uid-1"] as Record<string, unknown>
    );
    expect(entries[0]).not.toHaveProperty("tripId");
  });
});

describe("recordNotificationForAudience", () => {
  const SEED = {
    users: {
      "driver-1": {type: "driver"},
      "driver-2": {type: "driver"},
      "pax-1": {type: "passenger"},
    },
  };

  test("audience 'drivers' only records for drivers", async () => {
    const d = db(SEED);
    await recordNotificationForAudience(d, "drivers", {
      title: "Manutenção",
      body: "Hoje às 22h",
      type: "broadcast",
    });
    expect(d.store.notifications["driver-1"]).toBeDefined();
    expect(d.store.notifications["driver-2"]).toBeDefined();
    expect(d.store.notifications["pax-1"]).toBeUndefined();
  });

  test("audience 'all' records for every user", async () => {
    const d = db(SEED);
    await recordNotificationForAudience(d, "all", {
      title: "Novidade",
      body: "...",
      type: "broadcast",
    });
    expect(d.store.notifications["driver-1"]).toBeDefined();
    expect(d.store.notifications["pax-1"]).toBeDefined();
  });

  test("no matching users writes nothing", async () => {
    const d = db();
    await recordNotificationForAudience(d, "passengers", {
      title: "T",
      body: "B",
      type: "broadcast",
    });
    expect(d.store.notifications).toBeUndefined();
  });
});

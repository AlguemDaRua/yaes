import {sendBroadcastCore} from "../broadcast";
import {db, expectHttpsError} from "./fake-db";

const ADMIN = {
  admins: {"admin-uid": true},
  users: {"driver-1": {type: "driver"}, "pax-1": {type: "passenger"}},
};

function messaging() {
  return {send: jest.fn(async () => "msg-id")};
}

describe("sendBroadcastCore", () => {
  test("rejects non-admin caller", async () => {
    await expectHttpsError(
      sendBroadcastCore(db(), messaging(), "nobody", {
        title: "T",
        body: "B",
        audience: "all",
      }),
      "permission-denied"
    );
  });

  test("rejects blank title or body", async () => {
    await expectHttpsError(
      sendBroadcastCore(db(ADMIN), messaging(), "admin-uid", {
        title: " ",
        body: "B",
        audience: "all",
      }),
      "invalid-argument"
    );
  });

  test("rejects invalid audience", async () => {
    await expectHttpsError(
      sendBroadcastCore(db(ADMIN), messaging(), "admin-uid", {
        title: "T",
        body: "B",
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        audience: "partners" as any,
      }),
      "invalid-argument"
    );
  });

  test("sends to the topic and records history + audit", async () => {
    const d = db(ADMIN);
    const m = messaging();
    const res = await sendBroadcastCore(d, m, "admin-uid", {
      title: "Manutenção",
      body: "Hoje às 22h",
      audience: "drivers",
    });
    expect(m.send).toHaveBeenCalledWith({
      topic: "drivers",
      notification: {title: "Manutenção", body: "Hoje às 22h"},
    });
    expect(d.store.broadcasts[res.broadcastId]).toMatchObject({
      title: "Manutenção",
      audience: "drivers",
      sentBy: "admin-uid",
      status: "sent",
    });
    const audits = Object.values(d.store.audit as Record<string, unknown>);
    expect(audits[0]).toMatchObject({action: "sendBroadcast"});
    expect(d.store.notifications["driver-1"]).toBeDefined();
    expect(d.store.notifications["pax-1"]).toBeUndefined();
  });
});

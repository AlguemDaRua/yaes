import {
  applyTripWalletSettlementCore,
  initiateWalletTopupCore,
  walletTopupCallbackCore,
  adjustDriverWalletCore,
  GatewayFactory,
} from "../wallet";
import {SandboxAdapter} from "../payments/sandbox";
import {PaymentMethod} from "../payments/gateway";
import {db, expectHttpsError} from "./fake-db";

const sandbox: GatewayFactory = (method: PaymentMethod) =>
  new SandboxAdapter(method);

const YA_DIRECT = {
  partners: {p1: {name: "YA Direct", requiresWalletSettlement: true, commissionFloatMtn: 500}},
  commissions: {p1: {rate: 0.2}},
};

const REGULAR_PARTNER = {
  partners: {p2: {name: "Fleet Co"}},
};

describe("applyTripWalletSettlementCore", () => {
  test("debits the correct amount for a cash trip using the partner rate", async () => {
    const d = db({
      ...YA_DIRECT,
      trips: {t1: {partnerId: "p1", driver: "drv1", amountMtn: 1000, paymentMethod: ""}},
    });
    const res = await applyTripWalletSettlementCore(d, "t1");
    expect(res.applied).toBe(true);
    expect(d.store.driverWallets.p1.drv1.balance).toBe(-200);
    expect(d.store.driverWallets.p1.drv1.entries.t1).toMatchObject({
      type: "commission",
      amountMtn: -200,
      tripId: "t1",
    });
  });

  test("credits the driver's net share for a digital (mpesa) trip", async () => {
    const d = db({
      ...YA_DIRECT,
      trips: {t1: {partnerId: "p1", driver: "drv1", amountMtn: 1000, paymentMethod: "mpesa"}},
    });
    const res = await applyTripWalletSettlementCore(d, "t1");
    expect(res.applied).toBe(true);
    // 20% commission on 1000 => driver's net = 800.
    expect(d.store.driverWallets.p1.drv1.balance).toBe(800);
    expect(d.store.driverWallets.p1.drv1.entries.t1).toMatchObject({
      type: "earning",
      amountMtn: 800,
      tripId: "t1",
    });
  });

  test("credits the driver's net share for a digital (emola) trip", async () => {
    const d = db({
      ...YA_DIRECT,
      trips: {t1: {partnerId: "p1", driver: "drv1", amountMtn: 500, paymentMethod: "emola"}},
    });
    await applyTripWalletSettlementCore(d, "t1");
    expect(d.store.driverWallets.p1.drv1.balance).toBe(400);
  });

  test("a digital earning can offset prior cash debt and unblock the driver", async () => {
    const d = db({
      ...YA_DIRECT,
      trips: {
        t1: {partnerId: "p1", driver: "drv1", amountMtn: 3000, paymentMethod: ""},
        t2: {partnerId: "p1", driver: "drv1", amountMtn: 4000, paymentMethod: "mpesa"},
      },
    });
    await applyTripWalletSettlementCore(d, "t1");
    expect(d.store.driverWallets.p1.drv1.blockedAt).toEqual(expect.any(String));
    await applyTripWalletSettlementCore(d, "t2");
    // -600 (cash commission) + 3200 (80% of 4000 digital net) = 2600.
    expect(d.store.driverWallets.p1.drv1.balance).toBe(2600);
    expect(d.store.driverWallets.p1.drv1.blockedAt).toBeNull();
  });

  test("does not settle a partner without requiresWalletSettlement", async () => {
    const d = db({
      ...REGULAR_PARTNER,
      trips: {t1: {partnerId: "p2", driver: "drv1", amountMtn: 1000, paymentMethod: ""}},
    });
    const res = await applyTripWalletSettlementCore(d, "t1");
    expect(res.applied).toBe(false);
    expect(d.store.driverWallets).toBeUndefined();
  });

  test("is idempotent by tripId across a double-fire of the trigger", async () => {
    const d = db({
      ...YA_DIRECT,
      trips: {t1: {partnerId: "p1", driver: "drv1", amountMtn: 1000, paymentMethod: ""}},
    });
    const first = await applyTripWalletSettlementCore(d, "t1");
    const second = await applyTripWalletSettlementCore(d, "t1");
    expect(first.applied).toBe(true);
    expect(second.applied).toBe(false);
    expect(d.store.driverWallets.p1.drv1.balance).toBe(-200);
  });

  test("sets blockedAt once the debit crosses the commission float", async () => {
    const d = db({
      ...YA_DIRECT,
      trips: {t1: {partnerId: "p1", driver: "drv1", amountMtn: 3000, paymentMethod: ""}},
    });
    await applyTripWalletSettlementCore(d, "t1");
    // 20% of 3000 = 600 > float of 500
    expect(d.store.driverWallets.p1.drv1.balance).toBe(-600);
    expect(d.store.driverWallets.p1.drv1.blockedAt).toEqual(expect.any(String));
  });

  test("falls back to /config/pricing commission when no /commissions rate exists", async () => {
    const d = db({
      partners: {p1: {name: "YA Direct", requiresWalletSettlement: true}},
      config: {pricing: {fares: {regular: {commission: 0.1}}}},
      trips: {t1: {partnerId: "p1", driver: "drv1", amountMtn: 1000, paymentMethod: "", tripType: "regular"}},
    });
    await applyTripWalletSettlementCore(d, "t1");
    expect(d.store.driverWallets.p1.drv1.balance).toBe(-100);
  });
});

describe("initiateWalletTopupCore + walletTopupCallbackCore", () => {
  function seed() {
    return db({
      ...YA_DIRECT,
      users: {drv1: {type: "driver", partnerId: "p1", phone: "258840000000"}},
    });
  }

  test("credits the wallet and clears blockedAt once back above the float", async () => {
    const d = seed();
    // First push the driver into debt past the float.
    d.store.trips = {t1: {partnerId: "p1", driver: "drv1", amountMtn: 3000, paymentMethod: ""}};
    await applyTripWalletSettlementCore(d, "t1");
    expect(d.store.driverWallets.p1.drv1.blockedAt).toEqual(expect.any(String));

    const init = await initiateWalletTopupCore(
      d,
      "drv1",
      {amountMtn: 1000, method: "mpesa"},
      sandbox
    );
    expect(init.status).toBe("pending");

    const cb = await walletTopupCallbackCore(d, {
      topupId: init.topupId,
      pspRef: `SANDBOX-${init.topupId}`,
      status: "paid",
    });
    expect(cb.applied).toBe(true);
    expect(d.store.driverWallets.p1.drv1.balance).toBe(-600 + 1000);
    expect(d.store.driverWallets.p1.drv1.blockedAt).toBeNull();
  });

  test("is idempotent on a retried callback for the same pspRef", async () => {
    const d = seed();
    const init = await initiateWalletTopupCore(
      d,
      "drv1",
      {amountMtn: 500, method: "mpesa"},
      sandbox
    );
    const pspRef = `SANDBOX-${init.topupId}`;
    const first = await walletTopupCallbackCore(d, {topupId: init.topupId, pspRef, status: "paid"});
    const second = await walletTopupCallbackCore(d, {topupId: init.topupId, pspRef, status: "paid"});
    expect(first.applied).toBe(true);
    expect(second.applied).toBe(false);
    expect(d.store.driverWallets.p1.drv1.balance).toBe(500);
  });

  test("crash between wallet credit and status update: retry credits exactly once and marks paid", async () => {
    const d = seed();
    const init = await initiateWalletTopupCore(
      d,
      "drv1",
      {amountMtn: 300, method: "mpesa"},
      sandbox
    );
    const pspRef = `SANDBOX-${init.topupId}`;
    // Simulate the crash window: wallet entry already written (credit
    // applied) but the topup status was never updated to paid.
    d.store.driverWallets = {
      p1: {
        drv1: {
          balance: 300,
          entries: {[init.topupId]: {type: "topup", amountMtn: 300, mpesaRef: pspRef, createdAt: "x"}},
        },
      },
    };
    expect(d.store.walletTopups[init.topupId].status).toBe("pending");

    const retry = await walletTopupCallbackCore(d, {topupId: init.topupId, pspRef, status: "paid"});
    expect(retry.applied).toBe(true);
    // Credited exactly once, and now marked paid.
    expect(d.store.driverWallets.p1.drv1.balance).toBe(300);
    expect(d.store.walletTopups[init.topupId].status).toBe("paid");
  });

  test("wallet is credited before the topup is marked paid (no paid-without-credit state)", async () => {
    const d = seed();
    const init = await initiateWalletTopupCore(
      d,
      "drv1",
      {amountMtn: 200, method: "mpesa"},
      sandbox
    );
    // Make the wallet credit fail: the topup must then NOT be marked paid,
    // so the PSP retry can still deliver the money.
    const realRef = d.ref.bind(d);
    d.ref = (path: string) => {
      if (path.startsWith("driverWallets/")) {
        throw new Error("boom");
      }
      return realRef(path);
    };
    await expect(
      walletTopupCallbackCore(d, {
        topupId: init.topupId,
        pspRef: `SANDBOX-${init.topupId}`,
        status: "paid",
      })
    ).rejects.toThrow("boom");
    expect(d.store.walletTopups[init.topupId].status).toBe("pending");
  });

  test("concurrent duplicate entry writes: second transaction aborts and balance changes once", async () => {
    const d = seed();
    d.store.trips = {t1: {partnerId: "p1", driver: "drv1", amountMtn: 1000, paymentMethod: ""}};
    // Both calls target the same deterministic entryKey (tripId); the entry
    // transaction commits once, the duplicate aborts (committed: false).
    const [a, b] = await Promise.all([
      applyTripWalletSettlementCore(d, "t1"),
      applyTripWalletSettlementCore(d, "t1"),
    ]);
    expect([a.applied, b.applied].sort()).toEqual([false, true]);
    expect(d.store.driverWallets.p1.drv1.balance).toBe(-200);
  });
});

describe("adjustDriverWalletCore", () => {
  test("requires admin", async () => {
    const d = db({...YA_DIRECT, users: {u1: {type: "partner_owner", partnerId: "p1"}}});
    await expectHttpsError(
      adjustDriverWalletCore(d, "u1", {partnerId: "p1", driverId: "drv1", amountMtn: -100, note: "penalty"}),
      "permission-denied"
    );
  });

  test("admin can adjust the balance", async () => {
    const d = db({...YA_DIRECT, admins: {"admin-uid": true}});
    const res = await adjustDriverWalletCore(d, "admin-uid", {
      partnerId: "p1",
      driverId: "drv1",
      amountMtn: -50,
      note: "manual correction",
    });
    expect(res.balance).toBe(-50);
  });
});

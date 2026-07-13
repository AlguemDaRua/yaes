import {
  initiatePaymentCore,
  paymentCallbackCore,
  GatewayFactory,
} from "../payments";
import {SandboxAdapter} from "../payments/sandbox";
import {PaymentMethod} from "../payments/gateway";
import {db, expectHttpsError} from "./fake-db";

const sandbox: GatewayFactory = (method: PaymentMethod) =>
  new SandboxAdapter(method);

const TRIP = {
  users: {pax: {phone: "258840000000"}},
  trips: {t1: {passenger: "pax", estimatedPrice: 850}},
};

describe("initiatePaymentCore", () => {
  test("rejects an invalid method", async () => {
    const d = db(TRIP);
    await expectHttpsError(
      initiatePaymentCore(
        d,
        "pax",
        {tripId: "t1", method: "card" as PaymentMethod},
        sandbox
      ),
      "invalid-argument"
    );
  });

  test("404 when the trip is missing", async () => {
    const d = db(TRIP);
    await expectHttpsError(
      initiatePaymentCore(d, "pax", {tripId: "nope", method: "mpesa"}, sandbox),
      "not-found"
    );
  });

  test("rejects a caller who is not the passenger", async () => {
    const d = db(TRIP);
    await expectHttpsError(
      initiatePaymentCore(d, "intruder", {tripId: "t1", method: "mpesa"}, sandbox),
      "permission-denied"
    );
  });

  test("rejects an already-paid trip", async () => {
    const d = db({
      ...TRIP,
      trips: {t1: {passenger: "pax", estimatedPrice: 850, paymentStatus: "paid"}},
    });
    await expectHttpsError(
      initiatePaymentCore(d, "pax", {tripId: "t1", method: "mpesa"}, sandbox),
      "failed-precondition"
    );
  });

  test("rejects a trip with no payable amount", async () => {
    const d = db({trips: {t1: {passenger: "pax", estimatedPrice: 0}}});
    await expectHttpsError(
      initiatePaymentCore(d, "pax", {tripId: "t1", method: "mpesa"}, sandbox),
      "failed-precondition"
    );
  });

  test("creates a pending payment and stamps the trip", async () => {
    const d = db(TRIP);
    const res = await initiatePaymentCore(
      d,
      "pax",
      {tripId: "t1", method: "mpesa"},
      sandbox
    );
    expect(res.status).toBe("pending");
    const payment = d.store.payments[res.paymentId];
    expect(payment).toMatchObject({
      tripId: "t1",
      passenger: "pax",
      method: "mpesa",
      amountMtn: 850,
      status: "pending",
      pspRef: `SANDBOX-${res.paymentId}`,
      gateway: "sandbox:mpesa",
    });
    expect(d.store.trips.t1).toMatchObject({
      paymentStatus: "pending",
      paymentId: res.paymentId,
    });
  });

  test("an admin can pay on behalf of the passenger", async () => {
    const d = db({...TRIP, admins: {"admin-uid": true}});
    const res = await initiatePaymentCore(
      d,
      "admin-uid",
      {tripId: "t1", method: "emola"},
      sandbox
    );
    expect(res.status).toBe("pending");
  });
});

describe("paymentCallbackCore", () => {
  test("rejects an invalid status", async () => {
    const d = db({payments: {p1: {tripId: "t1", pspRef: "X", status: "pending"}}});
    await expectHttpsError(
      paymentCallbackCore(d, {pspRef: "X", status: "bogus" as "paid"}),
      "invalid-argument"
    );
  });

  test("404 when no payment matches", async () => {
    const d = db({});
    await expectHttpsError(
      paymentCallbackCore(d, {pspRef: "missing", status: "paid"}),
      "not-found"
    );
  });

  test("marks the payment and trip paid (by paymentId)", async () => {
    const d = db({
      payments: {p1: {tripId: "t1", pspRef: "PSP-9", status: "pending"}},
      trips: {t1: {paymentStatus: "pending"}},
    });
    const res = await paymentCallbackCore(d, {
      paymentId: "p1",
      pspRef: "PSP-9",
      status: "paid",
    });
    expect(res.applied).toBe(true);
    expect(d.store.payments.p1.status).toBe("paid");
    expect(d.store.trips.t1.paymentStatus).toBe("paid");
  });

  test("resolves the payment by pspRef when no paymentId is given", async () => {
    const d = db({
      payments: {p1: {tripId: "t1", pspRef: "PSP-42", status: "pending"}},
      trips: {t1: {}},
    });
    const res = await paymentCallbackCore(d, {pspRef: "PSP-42", status: "paid"});
    expect(res.applied).toBe(true);
    expect(res.paymentId).toBe("p1");
    expect(d.store.payments.p1.status).toBe("paid");
  });

  test("is idempotent for an already-paid payment", async () => {
    const d = db({
      payments: {p1: {tripId: "t1", pspRef: "PSP-9", status: "paid"}},
      trips: {t1: {paymentStatus: "paid"}},
    });
    const res = await paymentCallbackCore(d, {
      paymentId: "p1",
      pspRef: "PSP-9",
      status: "paid",
    });
    expect(res.applied).toBe(false);
  });

  test("initiate then callback completes the round trip", async () => {
    const d = db(TRIP);
    const init = await initiatePaymentCore(
      d,
      "pax",
      {tripId: "t1", method: "mpesa"},
      sandbox
    );
    const cb = await paymentCallbackCore(d, {
      paymentId: init.paymentId,
      pspRef: `SANDBOX-${init.paymentId}`,
      status: "paid",
    });
    expect(cb.applied).toBe(true);
    expect(d.store.trips.t1.paymentStatus).toBe("paid");
  });
});

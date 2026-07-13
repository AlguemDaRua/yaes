// Digital payments (M-Pesa + e-Mola) for the YA platform.
//
//   initiatePayment  callable — passenger starts a C2B collection for a trip.
//   paymentCallback  HTTP webhook — the PSP confirms paid/failed (idempotent).
//
// Pure *Core functions take the db and a gateway factory so they unit-test
// without the emulator or real credentials (see __tests__/payments.test.ts).

import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import * as crypto from "crypto";
import {writeAudit} from "./audit";
import {dispatchWebhooks} from "./webhooks";
import {PaymentGateway, PaymentMethod, PaymentStatus} from "./payments/gateway";
import {selectGateway} from "./payments/select";

type Database = admin.database.Database;

const PAYMENT_SECRETS = [
  "MPESA_API_KEY",
  "MPESA_PUBLIC_KEY",
  "MPESA_SERVICE_PROVIDER_CODE",
  "MPESA_API_HOST",
  "EMOLA_API_KEY",
  "EMOLA_API_HOST",
  "EMOLA_WALLET_ID",
];

function nowIso(): string {
  return new Date().toISOString();
}

async function isAdmin(db: Database, uid: string): Promise<boolean> {
  const snap = await db.ref(`admins/${uid}`).get();
  return snap.exists() && snap.val() === true;
}

// ── initiatePayment ──────────────────────────────────────────
export interface InitiatePaymentData {
  tripId: string;
  method: PaymentMethod;
  msisdn?: string;
}

export type GatewayFactory = (method: PaymentMethod) => PaymentGateway;

export async function initiatePaymentCore(
  db: Database,
  callerUid: string,
  data: InitiatePaymentData,
  makeGateway: GatewayFactory
): Promise<{paymentId: string; status: PaymentStatus}> {
  const {tripId, method} = data;
  if (!tripId || (method !== "mpesa" && method !== "emola")) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Required: tripId and method (mpesa|emola)."
    );
  }

  const trip = (await db.ref(`trips/${tripId}`).get()).val() as Record<
    string,
    unknown
  > | null;
  if (!trip) {
    throw new functions.https.HttpsError("not-found", "Trip not found.");
  }
  if (trip.passenger !== callerUid && !(await isAdmin(db, callerUid))) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only the trip passenger can pay for it."
    );
  }
  if (trip.paymentStatus === "paid") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Trip is already paid."
    );
  }

  const amountMtn = Math.round(
    Number(trip.estimatedPrice ?? trip.amountMtn ?? 0)
  );
  if (amountMtn <= 0) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Trip has no payable amount."
    );
  }

  let msisdn = data.msisdn ?? "";
  if (!msisdn) {
    msisdn =
      ((await db.ref(`users/${callerUid}/phone`).get()).val() as
        | string
        | null) ?? "";
  }

  const ref = db.ref("payments").push();
  const paymentId = ref.key as string;
  const gateway = makeGateway(method);
  const result = await gateway.charge({
    paymentId,
    amountMtn,
    msisdn,
    reference: tripId,
    description: `Viagem ${tripId}`,
  });

  await ref.set({
    tripId,
    passenger: callerUid,
    method,
    amountMtn,
    status: result.status,
    pspRef: result.pspRef,
    gateway: gateway.name,
    createdAt: nowIso(),
    updatedAt: nowIso(),
  });
  await db.ref(`trips/${tripId}`).update({
    paymentStatus: result.status,
    paymentId,
  });
  await writeAudit(db, {
    action: "initiatePayment",
    actorUid: callerUid,
    targetType: "payment",
    targetId: paymentId,
    meta: {tripId, method, amountMtn},
  });
  return {paymentId, status: result.status};
}

export const initiatePayment = functions
  .runWith({secrets: PAYMENT_SECRETS})
  .https.onCall(
    (data: InitiatePaymentData, context: functions.https.CallableContext) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "Not authenticated."
        );
      }
      return initiatePaymentCore(
        admin.database(),
        context.auth.uid,
        data,
        selectGateway
      );
    }
  );

// ── paymentCallback (PSP webhook) ────────────────────────────
export interface PaymentCallbackPayload {
  paymentId?: string;
  pspRef: string;
  status: PaymentStatus;
}

export async function paymentCallbackCore(
  db: Database,
  payload: PaymentCallbackPayload
): Promise<{applied: boolean; paymentId?: string}> {
  const {pspRef, status} = payload;
  if (!pspRef || (status !== "paid" && status !== "failed")) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Required: pspRef and status (paid|failed)."
    );
  }

  let paymentId = payload.paymentId;
  let payment: Record<string, unknown> | null = null;
  if (paymentId) {
    payment = (await db.ref(`payments/${paymentId}`).get()).val() as Record<
      string,
      unknown
    > | null;
  } else {
    const q = await db
      .ref("payments")
      .orderByChild("pspRef")
      .equalTo(pspRef)
      .get();
    const val = q.val() as Record<string, Record<string, unknown>> | null;
    if (val) {
      paymentId = Object.keys(val)[0];
      payment = val[paymentId];
    }
  }
  if (!payment || !paymentId) {
    throw new functions.https.HttpsError("not-found", "Payment not found.");
  }
  // Idempotent: a second callback for an already-paid payment is a no-op.
  if (payment.status === "paid") {
    return {applied: false, paymentId};
  }

  await db.ref(`payments/${paymentId}`).update({status, updatedAt: nowIso()});
  await db.ref(`trips/${payment.tripId}`).update({paymentStatus: status});
  await writeAudit(db, {
    action: "paymentCallback",
    actorUid: "psp",
    targetType: "payment",
    targetId: paymentId,
    meta: {status},
  });
  await dispatchWebhooks(db, "payment.updated", {
    paymentId,
    tripId: payment.tripId,
    status,
  });
  return {applied: true, paymentId};
}

export const paymentCallback = functions
  .runWith({secrets: ["PSP_WEBHOOK_SECRET"]})
  .https.onRequest(async (req, res) => {
    try {
      const secret = process.env.PSP_WEBHOOK_SECRET;
      // "TODO" is the pre-provisioning placeholder — no PSP is calling yet.
      if (secret && secret !== "TODO") {
        const signature = req.get("x-psp-signature") ?? "";
        const expected = crypto
          .createHmac("sha256", secret)
          .update(JSON.stringify(req.body))
          .digest("hex");
        if (signature !== expected) {
          res.status(401).json({error: "invalid signature"});
          return;
        }
      }
      const result = await paymentCallbackCore(
        admin.database(),
        req.body as PaymentCallbackPayload
      );
      res.status(200).json(result);
    } catch (e) {
      const err = e as {message?: string};
      res.status(400).json({error: err.message ?? String(e)});
    }
  });

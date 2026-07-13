// Driver commission wallet — Nampula direct-driver operation (YA Direct).
//
// Cash rides put the driver in debt to YA for the commission; this ledger
// tracks that debt per driver and blocks the driver once it crosses the
// partner's float. Only partners with /partners/{partnerId}/requiresWalletSettlement
// === true are opted in (everyone else is unaffected — B2B partner-fleet
// keeps settling commission the existing way).
//
// Pure *Core functions take the db (and gateway factory for the top-up flow)
// explicitly, mirroring painel.ts / payments.ts, so they unit-test without
// the emulator (see __tests__/wallet.test.ts).

import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import * as crypto from "crypto";
import {writeAudit} from "./audit";
import {PaymentGateway, PaymentMethod} from "./payments/gateway";
import {selectGateway} from "./payments/select";

type Database = admin.database.Database;

const DEFAULT_COMMISSION_FLOAT_MTN = 500;
const DEFAULT_COMMISSION_RATE = 0.12;

function nowIso(): string {
  return new Date().toISOString();
}

async function isAdmin(db: Database, uid: string): Promise<boolean> {
  const snap = await db.ref(`admins/${uid}`).get();
  return snap.exists() && snap.val() === true;
}

/** Manual wallet adjustments are admin-only (unlike fleet management, which
 * also allows the partner_owner — see painel.ts assertCanManagePartner). */
async function assertAdmin(db: Database, callerUid: string): Promise<void> {
  if (await isAdmin(db, callerUid)) return;
  throw new functions.https.HttpsError(
    "permission-denied",
    "Only administrators can perform this action."
  );
}

/** Applies a wallet ledger entry (idempotent by entryKey) and updates the
 * cached balance via transaction(), then (un)blocks the driver per the
 * partner's commissionFloatMtn. Shared by the commission debit, top-up
 * credit, and manual adjustment paths so the block rule lives in one place. */
async function applyWalletEntry(
  db: Database,
  partnerId: string,
  driverId: string,
  entryKey: string,
  entry: Record<string, unknown>
): Promise<{applied: boolean; balance: number}> {
  const walletRef = db.ref(`driverWallets/${partnerId}/${driverId}`);
  const entryRef = walletRef.child(`entries/${entryKey}`);
  // Atomic create-if-absent: returning undefined aborts the transaction, so
  // two concurrent duplicate deliveries can never both write the entry (a
  // plain exists()-then-set() check would race and double-debit).
  const entryTx = await entryRef.transaction((current: unknown) =>
    current === null ? entry : undefined
  );
  if (!entryTx.committed) {
    const snap = await walletRef.child("balance").get();
    return {applied: false, balance: (snap.val() as number) ?? 0};
  }

  const amountMtn = entry.amountMtn as number;
  const balanceRef = walletRef.child("balance");
  const txResult = await balanceRef.transaction(
    (current: number | null) => (current ?? 0) + amountMtn
  );
  const balance =
    (txResult?.snapshot?.val() as number | undefined) ?? amountMtn;

  const partnerSnap = await db.ref(`partners/${partnerId}`).get();
  const partner = partnerSnap.val() as
    | {commissionFloatMtn?: number}
    | null;
  const float = partner?.commissionFloatMtn ?? DEFAULT_COMMISSION_FLOAT_MTN;

  const blockedAtSnap = await walletRef.child("blockedAt").get();
  const blockedAt = blockedAtSnap.val() as string | null;

  if (balance <= -float && !blockedAt) {
    await walletRef.child("blockedAt").set(nowIso());
  } else if (balance > -float && blockedAt) {
    await walletRef.child("blockedAt").set(null);
  }

  return {applied: true, balance};
}

// ─────────────────────────────────────────────────────────────
// applyTripWalletSettlementCore — settles a completed trip against the
// driver's wallet for YA Direct partners. Wired into the trip-status
// trigger in notifications.ts.
//
// Cash trip: the passenger paid the driver directly, so the driver OWES the
// commission — debit entry (type "commission", negative).
// Digital trip (mpesa/emola): the passenger's payment settled through YA
// (see payments.ts), so YA owes the driver their net share — credit entry
// (type "earning", positive). Without this, a YA Direct driver's digital
// earnings would vanish: there is no partner to run a payout to (the
// "partner" IS YA), so the wallet is the driver's one running account.
// ─────────────────────────────────────────────────────────────

export async function applyTripWalletSettlementCore(
  db: Database,
  tripId: string
): Promise<{applied: boolean}> {
  const tripSnap = await db.ref(`trips/${tripId}`).get();
  if (!tripSnap.exists()) return {applied: false};
  const trip = tripSnap.val() as Record<string, unknown>;

  const partnerId = trip.partnerId as string | undefined;
  const driverId = trip.driver as string | undefined;
  const paymentMethod = (trip.paymentMethod as string | undefined) ?? "";
  const isDigital = paymentMethod === "mpesa" || paymentMethod === "emola";

  if (!partnerId || !driverId) return {applied: false};

  const partnerSnap = await db.ref(`partners/${partnerId}`).get();
  const partner = partnerSnap.val() as
    | {requiresWalletSettlement?: boolean; commissionFloatMtn?: number}
    | null;
  if (!partner?.requiresWalletSettlement) return {applied: false};

  const fare = Number(trip.amountMtn ?? trip.estimatedPrice ?? 0);
  if (!(fare > 0)) return {applied: false};

  const tripType = (trip.tripType as string | undefined) ?? "regular";
  let rate = DEFAULT_COMMISSION_RATE;
  const commissionSnap = await db.ref(`commissions/${partnerId}`).get();
  const commission = commissionSnap.val() as {rate?: number} | null;
  if (typeof commission?.rate === "number") {
    rate = commission.rate;
  } else {
    const pricingSnap = await db.ref("config/pricing").get();
    const pricing = pricingSnap.val() as
      | {fares?: Record<string, {commission?: number}>}
      | null;
    const cfgRate = pricing?.fares?.[tripType]?.commission;
    if (typeof cfgRate === "number") rate = cfgRate;
  }

  const entry = isDigital ?
    {
      type: "earning",
      amountMtn: Math.round(fare * (1 - rate)),
      tripId,
      createdAt: nowIso(),
    } :
    {
      type: "commission",
      amountMtn: -Math.round(fare * rate),
      tripId,
      createdAt: nowIso(),
    };

  const result = await applyWalletEntry(db, partnerId, driverId, tripId, entry);
  return {applied: result.applied};
}

// ─────────────────────────────────────────────────────────────
// initiateWalletTopup — driver tops up their wallet (e.g. via M-Pesa).
// Mirrors initiatePayment in payments.ts.
// ─────────────────────────────────────────────────────────────

export interface InitiateWalletTopupData {
  amountMtn: number;
  method: PaymentMethod;
  msisdn?: string;
}

export type GatewayFactory = (method: PaymentMethod) => PaymentGateway;

export async function initiateWalletTopupCore(
  db: Database,
  callerUid: string,
  data: InitiateWalletTopupData,
  makeGateway: GatewayFactory
): Promise<{topupId: string; status: string}> {
  const {amountMtn, method} = data;
  if (
    !amountMtn ||
    typeof amountMtn !== "number" ||
    amountMtn <= 0 ||
    (method !== "mpesa" && method !== "emola")
  ) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Required: a positive amountMtn and method (mpesa|emola)."
    );
  }

  const userSnap = await db.ref(`users/${callerUid}`).get();
  const user = userSnap.val() as
    | {type?: string; partnerId?: string; phone?: string}
    | null;
  if (!user || user.type !== "driver" || !user.partnerId) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only a driver may top up their wallet."
    );
  }
  const partnerSnap = await db.ref(`partners/${user.partnerId}`).get();
  const partner = partnerSnap.val() as
    | {requiresWalletSettlement?: boolean}
    | null;
  if (!partner?.requiresWalletSettlement) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "This partner does not use wallet settlement."
    );
  }

  const msisdn = data.msisdn ?? user.phone ?? "";
  const ref = db.ref("walletTopups").push();
  const topupId = ref.key as string;
  const gateway = makeGateway(method);
  const result = await gateway.charge({
    paymentId: topupId,
    amountMtn: Math.round(amountMtn),
    msisdn,
    reference: topupId,
    description: `Recarga carteira ${topupId}`,
  });

  await ref.set({
    driverId: callerUid,
    partnerId: user.partnerId,
    amountMtn: Math.round(amountMtn),
    method,
    status: result.status,
    pspRef: result.pspRef,
    gateway: gateway.name,
    createdAt: nowIso(),
    updatedAt: nowIso(),
  });
  await writeAudit(db, {
    action: "initiateWalletTopup",
    actorUid: callerUid,
    targetType: "walletTopup",
    targetId: topupId,
    meta: {amountMtn, method},
  });
  return {topupId, status: result.status};
}

export const initiateWalletTopup = functions.https.onCall(
  (data: InitiateWalletTopupData, context: functions.https.CallableContext) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Not authenticated.");
    }
    return initiateWalletTopupCore(
      admin.database(),
      context.auth.uid,
      data,
      selectGateway
    );
  }
);

// ─────────────────────────────────────────────────────────────
// walletTopupCallback — PSP webhook confirming a top-up (idempotent).
// Mirrors paymentCallback in payments.ts.
// ─────────────────────────────────────────────────────────────

export interface WalletTopupCallbackPayload {
  topupId?: string;
  pspRef: string;
  status: "paid" | "failed";
}

export async function walletTopupCallbackCore(
  db: Database,
  payload: WalletTopupCallbackPayload
): Promise<{applied: boolean; topupId?: string}> {
  const {pspRef, status} = payload;
  if (!pspRef || (status !== "paid" && status !== "failed")) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Required: pspRef and status (paid|failed)."
    );
  }

  let topupId = payload.topupId;
  let topup: Record<string, unknown> | null = null;
  if (topupId) {
    topup = (await db.ref(`walletTopups/${topupId}`).get()).val() as Record<
      string,
      unknown
    > | null;
  } else {
    const q = await db
      .ref("walletTopups")
      .orderByChild("pspRef")
      .equalTo(pspRef)
      .get();
    const val = q.val() as Record<string, Record<string, unknown>> | null;
    if (val) {
      topupId = Object.keys(val)[0];
      topup = val[topupId];
    }
  }
  if (!topup || !topupId) {
    throw new functions.https.HttpsError("not-found", "Top-up not found.");
  }
  // Idempotent: a second callback for an already-paid top-up is a no-op.
  if (topup.status === "paid") {
    return {applied: false, topupId};
  }

  // Credit the wallet BEFORE marking the topup paid: a crash in between
  // leaves the topup pending, so the PSP retry re-runs applyWalletEntry,
  // which is idempotent by entryKey. The reverse order could mark a topup
  // paid without ever crediting the driver.
  if (status === "paid") {
    await applyWalletEntry(
      db,
      topup.partnerId as string,
      topup.driverId as string,
      topupId,
      {
        type: "topup",
        amountMtn: topup.amountMtn as number,
        mpesaRef: pspRef,
        createdAt: nowIso(),
      }
    );
  }

  await db.ref(`walletTopups/${topupId}`).update({status, updatedAt: nowIso()});

  await writeAudit(db, {
    action: "walletTopupCallback",
    actorUid: "psp",
    targetType: "walletTopup",
    targetId: topupId,
    meta: {status},
  });
  return {applied: true, topupId};
}

export const walletTopupCallback = functions
  .runWith({secrets: ["PSP_WEBHOOK_SECRET"]})
  .https.onRequest(async (req, res) => {
    try {
      const secret = process.env.PSP_WEBHOOK_SECRET;
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
      const result = await walletTopupCallbackCore(
        admin.database(),
        req.body as WalletTopupCallbackPayload
      );
      res.status(200).json(result);
    } catch (e) {
      const err = e as {message?: string};
      res.status(400).json({error: err.message ?? String(e)});
    }
  });

// ─────────────────────────────────────────────────────────────
// adjustDriverWallet — admin manual correction (credit or debit).
// ─────────────────────────────────────────────────────────────

export interface AdjustDriverWalletData {
  partnerId: string;
  driverId: string;
  amountMtn: number;
  note?: string;
}

export async function adjustDriverWalletCore(
  db: Database,
  callerUid: string,
  data: AdjustDriverWalletData
): Promise<{success: true; balance: number}> {
  const {partnerId, driverId, amountMtn, note} = data;
  if (!partnerId || !driverId || typeof amountMtn !== "number" || amountMtn === 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Required: partnerId, driverId, and a non-zero amountMtn."
    );
  }
  await assertAdmin(db, callerUid);

  const entryKey = db.ref(`driverWallets/${partnerId}/${driverId}/entries`).push()
    .key as string;
  const entry: Record<string, unknown> = {
    type: "adjustment",
    amountMtn,
    adminId: callerUid,
    createdAt: nowIso(),
  };
  if (note) entry.note = note;

  const result = await applyWalletEntry(db, partnerId, driverId, entryKey, entry);
  await writeAudit(db, {
    action: "adjustDriverWallet",
    actorUid: callerUid,
    targetType: "driverWallet",
    targetId: `${partnerId}/${driverId}`,
    meta: {amountMtn, note},
  });
  return {success: true, balance: result.balance};
}

export const adjustDriverWallet = functions.https.onCall(
  (data: AdjustDriverWalletData, context: functions.https.CallableContext) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Not authenticated.");
    }
    return adjustDriverWalletCore(admin.database(), context.auth.uid, data);
  }
);

// Callable Cloud Functions for the support backoffice (ya-painelv1 support area).
// Mutations on tickets and disputes. Authorization: an admin OR a user whose
// /users/{uid}/type is 'support'. Each callable wraps a pure *Core function for
// unit testing (see __tests__).

import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import {writeAudit} from "./audit";

type Database = admin.database.Database;

function assertAuth(context: functions.https.CallableContext): string {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Not authenticated.");
  }
  return context.auth.uid;
}

/** Admin (via /admins/{uid}) or a support agent (users/{uid}.type==='support'). */
async function assertSupport(db: Database, uid: string): Promise<void> {
  const adminSnap = await db.ref(`admins/${uid}`).get();
  if (adminSnap.exists() && adminSnap.val() === true) return;
  const userSnap = await db.ref(`users/${uid}`).get();
  const user = userSnap.val() as {type?: string} | null;
  if (user && user.type === "support") return;
  throw new functions.https.HttpsError(
    "permission-denied",
    "Only an administrator or a support agent can perform this action."
  );
}

function nowIso(): string {
  return new Date().toISOString();
}

// ── assignTicket ─────────────────────────────────────────────
export interface AssignTicketData {
  ticketId: string;
  agentUid: string;
}

export async function assignTicketCore(
  db: Database,
  callerUid: string,
  data: AssignTicketData
): Promise<{success: true}> {
  await assertSupport(db, callerUid);
  const {ticketId, agentUid} = data;
  if (!ticketId || !agentUid) {
    throw new functions.https.HttpsError("invalid-argument", "Required: ticketId, agentUid.");
  }
  const ref = db.ref(`tickets/${ticketId}`);
  if (!(await ref.get()).exists()) {
    throw new functions.https.HttpsError("not-found", "Ticket not found.");
  }
  await ref.update({assignedTo: agentUid, status: "in_progress", updatedAt: nowIso()});
  await writeAudit(db, {
    action: "assignTicket",
    actorUid: callerUid,
    targetType: "ticket",
    targetId: ticketId,
    meta: {agentUid},
  });
  return {success: true};
}

export const assignTicket = functions.https.onCall(
  (data: AssignTicketData, context: functions.https.CallableContext) =>
    assignTicketCore(admin.database(), assertAuth(context), data)
);

// ── replyTicket ──────────────────────────────────────────────
export interface ReplyTicketData {
  ticketId: string;
  text: string;
  authorName?: string;
}

export async function replyTicketCore(
  db: Database,
  callerUid: string,
  data: ReplyTicketData
): Promise<{messageId: string}> {
  await assertSupport(db, callerUid);
  const {ticketId, text, authorName} = data;
  if (!ticketId || !text || !text.trim()) {
    throw new functions.https.HttpsError("invalid-argument", "Required: ticketId and non-empty text.");
  }
  const ticketRef = db.ref(`tickets/${ticketId}`);
  if (!(await ticketRef.get()).exists()) {
    throw new functions.https.HttpsError("not-found", "Ticket not found.");
  }
  const now = nowIso();
  const msgRef = ticketRef.child("messages").push();
  await msgRef.set({
    author: authorName ?? callerUid,
    authorUid: callerUid,
    text,
    role: "support",
    createdAt: now,
  });
  await ticketRef.update({lastMessageAt: now, status: "in_progress"});
  await writeAudit(db, {
    action: "replyTicket",
    actorUid: callerUid,
    targetType: "ticket",
    targetId: ticketId,
  });
  return {messageId: msgRef.key as string};
}

export const replyTicket = functions.https.onCall(
  (data: ReplyTicketData, context: functions.https.CallableContext) =>
    replyTicketCore(admin.database(), assertAuth(context), data)
);

// ── closeTicket ──────────────────────────────────────────────
export interface CloseTicketData {
  ticketId: string;
}

export async function closeTicketCore(
  db: Database,
  callerUid: string,
  data: CloseTicketData
): Promise<{success: true}> {
  await assertSupport(db, callerUid);
  const {ticketId} = data;
  if (!ticketId) {
    throw new functions.https.HttpsError("invalid-argument", "Required: ticketId.");
  }
  const ref = db.ref(`tickets/${ticketId}`);
  if (!(await ref.get()).exists()) {
    throw new functions.https.HttpsError("not-found", "Ticket not found.");
  }
  await ref.update({status: "resolved", resolvedAt: nowIso(), resolvedBy: callerUid});
  await writeAudit(db, {
    action: "closeTicket",
    actorUid: callerUid,
    targetType: "ticket",
    targetId: ticketId,
  });
  return {success: true};
}

export const closeTicket = functions.https.onCall(
  (data: CloseTicketData, context: functions.https.CallableContext) =>
    closeTicketCore(admin.database(), assertAuth(context), data)
);

// ── resolveDispute ───────────────────────────────────────────
export interface ResolveDisputeData {
  tripId: string;
  resolution: string;
  status?: "resolved" | "rejected";
}

export async function resolveDisputeCore(
  db: Database,
  callerUid: string,
  data: ResolveDisputeData
): Promise<{success: true}> {
  await assertSupport(db, callerUid);
  const {tripId, resolution, status} = data;
  if (!tripId || !resolution || !resolution.trim()) {
    throw new functions.https.HttpsError("invalid-argument", "Required: tripId and resolution.");
  }
  const ref = db.ref(`disputes/${tripId}`);
  if (!(await ref.get()).exists()) {
    throw new functions.https.HttpsError("not-found", "Dispute not found.");
  }
  await ref.update({
    status: status ?? "resolved",
    resolution,
    resolvedAt: nowIso(),
    resolvedBy: callerUid,
  });
  await writeAudit(db, {
    action: "resolveDispute",
    actorUid: callerUid,
    targetType: "dispute",
    targetId: tripId,
    meta: {status: status ?? "resolved"},
  });
  return {success: true};
}

export const resolveDispute = functions.https.onCall(
  (data: ResolveDisputeData, context: functions.https.CallableContext) =>
    resolveDisputeCore(admin.database(), assertAuth(context), data)
);

// ── createTicket ─────────────────────────────────────────────
export interface CreateTicketData {
  subject: string;
  priority?: "low" | "normal" | "high";
  authorUid?: string;
  authorName?: string;
  tripId?: string;
  text?: string;
}

export async function createTicketCore(
  db: Database,
  callerUid: string,
  data: CreateTicketData
): Promise<{ticketId: string}> {
  const {subject, priority, authorUid, authorName, tripId, text} = data;
  // Self-service: qualquer utilizador autenticado pode abrir um ticket em seu
  // próprio nome. Criar em nome de outra pessoa continua reservado a
  // admin/suporte.
  const isSelfService = !authorUid || authorUid === callerUid;
  let callerType: string | undefined;
  if (isSelfService) {
    const userSnap = await db.ref(`users/${callerUid}`).get();
    callerType = (userSnap.val() as {type?: string} | null)?.type;
  } else {
    await assertSupport(db, callerUid);
  }
  if (!subject || !subject.trim()) {
    throw new functions.https.HttpsError("invalid-argument", "Required: subject.");
  }
  const now = nowIso();
  const ref = db.ref("tickets").push();
  const role = isSelfService ? (callerType ?? "passenger") : "support";
  const ticket: Record<string, unknown> = {
    subject,
    priority: priority ?? "normal",
    status: "open",
    authorUid: authorUid ?? callerUid,
    authorName: authorName ?? (isSelfService ? "Utilizador" : "Suporte"),
    role,
    createdAt: now,
    lastMessageAt: now,
  };
  if (tripId) ticket.tripId = tripId;
  if (text && text.trim()) {
    ticket.preview = text;
    ticket.messages = {
      m1: {author: authorName ?? "Utilizador", authorUid: callerUid, text, role, createdAt: now},
    };
  }
  await ref.set(ticket);
  await writeAudit(db, {
    action: "createTicket",
    actorUid: callerUid,
    targetType: "ticket",
    targetId: ref.key as string,
  });
  return {ticketId: ref.key as string};
}

export const createTicket = functions.https.onCall(
  (data: CreateTicketData, context: functions.https.CallableContext) =>
    createTicketCore(admin.database(), assertAuth(context), data)
);

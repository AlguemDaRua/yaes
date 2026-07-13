// Lightweight audit-trail helper. Admin/support mutations append an entry to
// /audit, which the backoffice panel reads (see ya-painelv1
// firebase_admin_data_repository.dart listAuditLogs).

import * as admin from "firebase-admin";

type Database = admin.database.Database;

export interface AuditEntry {
  action: string;
  actorUid: string;
  targetType?: string;
  targetId?: string;
  meta?: Record<string, unknown>;
}

/** Appends an audit entry under /audit/{pushId} with an ISO timestamp. */
export async function writeAudit(db: Database, entry: AuditEntry): Promise<void> {
  const ref = db.ref("audit").push();
  const record: Record<string, unknown> = {
    action: entry.action,
    actorUid: entry.actorUid,
    at: new Date().toISOString(),
  };
  if (entry.targetType) record.targetType = entry.targetType;
  if (entry.targetId) record.targetId = entry.targetId;
  if (entry.meta) record.meta = entry.meta;
  await ref.set(record);
}

// Outbound webhooks: admins register endpoints under /config/webhooks/{id}
// ({url, events[], secret, active}) via the panel; platform triggers call
// dispatchWebhooks to POST signed JSON to every active endpoint subscribed
// to the event. Failures never break the calling trigger.

import * as crypto from "crypto";
import * as admin from "firebase-admin";

type Database = admin.database.Database;

export interface WebhookConfig {
  url?: string;
  events?: string[] | Record<string, boolean>;
  secret?: string;
  active?: boolean;
}

export type FetchLike = (
  url: string,
  init: {method: string; headers: Record<string, string>; body: string}
) => Promise<{ok: boolean; status: number}>;

function subscribed(hook: WebhookConfig, event: string): boolean {
  const events = hook.events;
  if (Array.isArray(events)) return events.includes(event);
  if (events && typeof events === "object") return events[event] === true;
  return false;
}

/** HMAC-SHA256 of the body with the endpoint's secret (X-Ya-Signature). */
export function signPayload(secret: string, body: string): string {
  return crypto.createHmac("sha256", secret).update(body).digest("hex");
}

/**
 * POSTs {event, data, sentAt} to every active endpoint subscribed to
 * [event], with one retry per endpoint. Errors are swallowed (logged).
 */
export async function dispatchWebhooks(
  db: Database,
  event: string,
  data: Record<string, unknown>,
  fetchFn: FetchLike = fetch as unknown as FetchLike
): Promise<{delivered: number}> {
  let hooks: Record<string, WebhookConfig> | null = null;
  try {
    hooks = (await db.ref("config/webhooks").get()).val() as Record<
      string,
      WebhookConfig
    > | null;
  } catch {
    return {delivered: 0};
  }
  if (!hooks) return {delivered: 0};

  const body = JSON.stringify({event, data, sentAt: new Date().toISOString()});
  let delivered = 0;

  for (const [id, hook] of Object.entries(hooks)) {
    if (!hook || hook.active !== true || !hook.url) continue;
    if (!subscribed(hook, event)) continue;
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
    };
    if (hook.secret) {
      headers["X-Ya-Signature"] = signPayload(hook.secret, body);
    }
    for (let attempt = 0; attempt < 2; attempt++) {
      try {
        const res = await fetchFn(hook.url, {method: "POST", headers, body});
        if (res.ok) {
          delivered++;
          break;
        }
        console.warn(`[webhook ${id}] HTTP ${res.status} (attempt ${attempt + 1})`);
      } catch (e) {
        console.warn(`[webhook ${id}] failed (attempt ${attempt + 1}):`, e);
      }
    }
  }
  return {delivered};
}

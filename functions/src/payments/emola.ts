import {ChargeRequest, ChargeResult, PaymentGateway} from "./gateway";

// Movitel e-Mola C2B collection. `charge` initiates the push; the customer
// approves and the PSP confirms via the paymentCallback webhook. Credentials
// are injected from Secret Manager — never hard-coded.
export interface EmolaConfig {
  apiHost: string;
  apiKey: string;
  walletId: string;
}

export class EmolaAdapter implements PaymentGateway {
  constructor(private readonly cfg: EmolaConfig) {}

  get name(): string {
    return "emola";
  }

  async charge(req: ChargeRequest): Promise<ChargeResult> {
    const res = await fetch(`https://${this.cfg.apiHost}/v1/c2b`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${this.cfg.apiKey}`,
      },
      body: JSON.stringify({
        amount: req.amountMtn,
        msisdn: req.msisdn,
        reference: req.reference,
        thirdPartyReference: req.paymentId,
        walletId: this.cfg.walletId,
      }),
    });
    const body = (await res.json()) as Record<string, unknown>;
    const ok = String(body.status ?? "").toLowerCase() === "accepted";
    return {
      status: ok ? "pending" : "failed",
      pspRef: String(body.transactionId ?? req.paymentId),
      raw: body,
    };
  }
}

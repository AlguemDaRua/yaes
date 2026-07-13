import {ChargeRequest, ChargeResult, PaymentGateway} from "./gateway";

// Vodacom M-Pesa C2B (USSD push). `charge` initiates the collection; the
// customer approves on their handset and the PSP confirms via the
// paymentCallback webhook. Credentials are injected from Secret Manager (bound
// on the callable via runWith.secrets) — never hard-coded.
export interface MpesaConfig {
  apiHost: string; // e.g. api.vm.co.mz:18352
  apiKey: string;
  publicKey: string;
  serviceProviderCode: string;
}

export class MpesaAdapter implements PaymentGateway {
  constructor(private readonly cfg: MpesaConfig) {}

  get name(): string {
    return "mpesa";
  }

  async charge(req: ChargeRequest): Promise<ChargeResult> {
    const res = await fetch(
      `https://${this.cfg.apiHost}/ipg/v1x/c2bPayment/singleStage/`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${this.bearerToken()}`,
          "Origin": "developer.mpesa.vm.co.mz",
        },
        body: JSON.stringify({
          input_Amount: String(req.amountMtn),
          input_CustomerMSISDN: req.msisdn,
          input_TransactionReference: req.reference,
          input_ThirdPartyReference: req.paymentId,
          input_ServiceProviderCode: this.cfg.serviceProviderCode,
        }),
      }
    );
    const body = (await res.json()) as Record<string, unknown>;
    // INS-0 = accepted; the final paid/failed state arrives via the webhook.
    const code = String(body.output_ResponseCode ?? "");
    const status = code === "INS-0" ? "pending" : "failed";
    return {
      status,
      pspRef: String(body.output_TransactionID ?? req.paymentId),
      raw: body,
    };
  }

  // M-Pesa requires the API key to be RSA-encrypted with the session public
  // key. That step is finalised once the real credentials are provisioned; the
  // adapter is only selected when those secrets are present.
  private bearerToken(): string {
    return this.cfg.apiKey;
  }
}

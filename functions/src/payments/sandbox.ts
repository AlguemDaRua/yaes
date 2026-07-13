import {
  ChargeRequest,
  ChargeResult,
  PaymentGateway,
  PaymentMethod,
} from "./gateway";

// Deterministic, no-network gateway used until real PSP credentials are wired.
// Returns "pending" with a SANDBOX reference; the payment is completed by the
// paymentCallback webhook, mirroring a real asynchronous C2B push.
export class SandboxAdapter implements PaymentGateway {
  constructor(private readonly method: PaymentMethod) {}

  get name(): string {
    return `sandbox:${this.method}`;
  }

  async charge(req: ChargeRequest): Promise<ChargeResult> {
    return {status: "pending", pspRef: `SANDBOX-${req.paymentId}`};
  }
}

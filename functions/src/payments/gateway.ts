// Payment gateway abstraction. Concrete adapters (M-Pesa, e-Mola, sandbox)
// implement `charge` to initiate a customer-to-business collection. Real PSPs
// confirm asynchronously through the paymentCallback webhook; the sandbox
// adapter also returns "pending" so the same callback path is exercised
// end-to-end without credentials.

export type PaymentMethod = "mpesa" | "emola";
export type PaymentStatus = "pending" | "paid" | "failed";

export interface ChargeRequest {
  paymentId: string;
  amountMtn: number;
  msisdn: string;
  reference: string;
  description?: string;
}

export interface ChargeResult {
  status: PaymentStatus;
  pspRef: string;
  raw?: Record<string, unknown>;
}

export interface PaymentGateway {
  readonly name: string;
  charge(req: ChargeRequest): Promise<ChargeResult>;
}

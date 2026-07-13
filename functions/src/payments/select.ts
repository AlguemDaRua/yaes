import {PaymentGateway, PaymentMethod} from "./gateway";
import {SandboxAdapter} from "./sandbox";
import {MpesaAdapter} from "./mpesa";
import {EmolaAdapter} from "./emola";

// Chooses a real adapter when its credentials are present in the environment
// (bound from Secret Manager on the callable), otherwise falls back to the
// sandbox. No secret values are ever hard-coded. Secrets provisioned with the
// "TODO" placeholder (so the functions can deploy before the PSP contracts
// are signed) count as absent.
function present(value?: string): value is string {
  return !!value && value !== "TODO";
}

export function selectGateway(method: PaymentMethod): PaymentGateway {
  const env = process.env;
  if (
    method === "mpesa" &&
    present(env.MPESA_API_KEY) &&
    present(env.MPESA_PUBLIC_KEY) &&
    present(env.MPESA_SERVICE_PROVIDER_CODE)
  ) {
    return new MpesaAdapter({
      apiHost: present(env.MPESA_API_HOST) ?
        env.MPESA_API_HOST :
        "api.vm.co.mz:18352",
      apiKey: env.MPESA_API_KEY as string,
      publicKey: env.MPESA_PUBLIC_KEY as string,
      serviceProviderCode: env.MPESA_SERVICE_PROVIDER_CODE as string,
    });
  }
  if (method === "emola" && present(env.EMOLA_API_KEY)) {
    return new EmolaAdapter({
      apiHost: present(env.EMOLA_API_HOST) ? env.EMOLA_API_HOST : "",
      apiKey: env.EMOLA_API_KEY,
      walletId: present(env.EMOLA_WALLET_ID) ? env.EMOLA_WALLET_ID : "",
    });
  }
  return new SandboxAdapter(method);
}

import { env } from "../../config/env";

// omise-node ships no TypeScript types; these interfaces cover only the
// fields this module actually reads/writes from the Charge/Refund/Event
// resources (see https://docs.omise.co/charges-api for the full shape).
export interface OmiseCharge {
  object: "charge";
  id: string;
  status: "successful" | "failed" | "pending" | "expired" | "reversed";
  paid: boolean;
  amount: number;
  currency: string;
  failure_code: string | null;
  failure_message: string | null;
  refunded: number;
  metadata: Record<string, unknown>;
}

export interface OmiseRefund {
  object: "refund";
  id: string;
  amount: number;
  charge: string;
}

export interface OmiseEvent {
  object: "event";
  id: string;
  key: string; // e.g. 'charge.complete'
  data: OmiseCharge | Record<string, unknown>;
}

export interface OmiseErrorShape {
  object: "error";
  location?: string;
  code: string;
  message: string;
}

export class OmiseApiError extends Error {
  constructor(public code: string, message: string) {
    super(message);
  }
}

function isOmiseError(err: unknown): err is OmiseErrorShape {
  return typeof err === "object" && err !== null && (err as { object?: string }).object === "error";
}

function wrap<T>(promise: Promise<T>): Promise<T> {
  return promise.catch((err) => {
    if (isOmiseError(err)) throw new OmiseApiError(err.code, err.message);
    throw err;
  });
}

interface OmiseSdk {
  charges: {
    create(data: Record<string, unknown>): Promise<OmiseCharge>;
    retrieve(id: string): Promise<OmiseCharge>;
    createRefund(chargeId: string, data: { amount: number }): Promise<OmiseRefund>;
  };
  events: {
    retrieve(id: string): Promise<OmiseEvent>;
  };
}

let sdk: OmiseSdk | null = null;

/// Lazily constructed so the app can boot (and every other module can be
/// tested) without OMISE_SECRET_KEY set; only payment-related calls fail
/// until a real sandbox key is configured.
function getSdk(): OmiseSdk {
  if (!env.omiseSecretKey) {
    throw new OmiseApiError("not_configured", "OMISE_SECRET_KEY is not set — payments are unavailable");
  }
  if (!sdk) {
    const omise = require("omise") as (config: Record<string, unknown>) => OmiseSdk;
    sdk = omise({ secretKey: env.omiseSecretKey, omiseVersion: "2019-05-29" });
  }
  return sdk;
}

export const omiseClient = {
  createCharge(data: Record<string, unknown>): Promise<OmiseCharge> {
    return wrap(getSdk().charges.create(data));
  },
  retrieveCharge(id: string): Promise<OmiseCharge> {
    return wrap(getSdk().charges.retrieve(id));
  },
  createRefund(chargeId: string, amountSatang: number): Promise<OmiseRefund> {
    return wrap(getSdk().charges.createRefund(chargeId, { amount: amountSatang }));
  },
  retrieveEvent(id: string): Promise<OmiseEvent> {
    return wrap(getSdk().events.retrieve(id));
  },
};

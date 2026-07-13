import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";

// ─────────────────────────────────────────────────────────────
// FARES (in MZN — Mozambican Metical)
// ─────────────────────────────────────────────────────────────

export type TripType = "regular" | "scheduled" | "airport" | "event";
export type SurgeLevel = "normal" | "moderate" | "high" | "extreme" | "maximum";

const SURGE_MULTIPLIERS: Record<SurgeLevel, number> = {
  normal: 1.0,
  moderate: 1.3,
  high: 1.5,
  extreme: 1.8,
  maximum: 2.0,
};

interface Fare {
  baseFare: number;
  perKm: number;
  perMinute: number;
  perHour: number;
  minimumHours: number;
  minimumFare: number;
  commission: number; // percentage e.g. 0.12 = 12%
  surgeAllowed: boolean;
}

// Defaults used when /config/pricing is absent or partial.
const FARES: Record<TripType, Fare> = {
  // Standard point-to-point trip
  regular: {
    baseFare: 150,
    perKm: 35,
    perMinute: 5,
    perHour: 0,
    minimumHours: 0,
    minimumFare: 250,
    commission: 0.12,
    surgeAllowed: true,
  },
  // Pre-scheduled trip (~10% premium)
  scheduled: {
    baseFare: 165,
    perKm: 35,
    perMinute: 5,
    perHour: 0,
    minimumHours: 0,
    minimumFare: 275,
    commission: 0.10,
    surgeAllowed: true,
  },
  // Airport transfer (fixed base + per km beyond the zone)
  airport: {
    baseFare: 500,
    perKm: 30,
    perMinute: 0,
    perHour: 0,
    minimumHours: 0,
    minimumFare: 500,
    commission: 0.15,
    surgeAllowed: false,
  },
  // Hourly hire (minimum 2 hours)
  event: {
    baseFare: 500,
    perKm: 20,
    perMinute: 0,
    perHour: 800,
    minimumHours: 2,
    minimumFare: 2100, // 500 + 2*800
    commission: 0.10,
    surgeAllowed: false,
  },
};

// ─────────────────────────────────────────────────────────────
// REMOTE CONFIG (/config/pricing) — editable from the admin panel
// ─────────────────────────────────────────────────────────────

export interface CategoryConfig {
  label?: string;
  multiplier?: number;
  seats?: number;
  order?: number;
}

export interface PricingConfig {
  fares?: Partial<Record<TripType, Partial<Fare>>>;
  categories?: Record<string, CategoryConfig>;
}

/** Merges the stored fare overrides over the hardcoded defaults. */
export function resolveFare(tripType: TripType, config?: PricingConfig): Fare {
  const overrides = config?.fares?.[tripType];
  if (!overrides) return FARES[tripType];
  const merged: Fare = {...FARES[tripType]};
  for (const key of Object.keys(merged) as (keyof Fare)[]) {
    const value = overrides[key];
    if (key === "surgeAllowed") {
      if (typeof value === "boolean") merged.surgeAllowed = value;
    } else if (typeof value === "number" && isFinite(value) && value >= 0) {
      (merged[key] as number) = value;
    }
  }
  return merged;
}

/** Resolves a category's price multiplier (defaults to 1). */
export function resolveCategoryMultiplier(
  category: string | undefined,
  config?: PricingConfig
): number {
  if (!category) return 1;
  const m = config?.categories?.[category]?.multiplier;
  return typeof m === "number" && isFinite(m) && m > 0 ? m : 1;
}

/** Reads /config/pricing; returns undefined on absence or error (fallback). */
export async function loadPricingConfig(
  db: admin.database.Database
): Promise<PricingConfig | undefined> {
  try {
    const snap = await db.ref("config/pricing").get();
    const val = snap.val();
    return val && typeof val === "object" ? (val as PricingConfig) : undefined;
  } catch {
    return undefined;
  }
}

// ─────────────────────────────────────────────────────────────
// INTERFACES
// ─────────────────────────────────────────────────────────────

interface CalculatePriceRequest {
  tripType: TripType;
  distanceKm: number;
  durationMinutes: number;
  surge?: SurgeLevel; // optional, default "normal"
  hours?: number; // required for tripType "event"
  category?: string; // car category id (e.g. "economico"), default multiplier 1
}

interface CalculatePriceResponse {
  tripType: TripType;
  baseFare: number;
  distanceAmount: number;
  timeAmount: number;
  subtotal: number;
  surgeMultiplier: number;
  categoryMultiplier: number;
  totalAmount: number;
  minimumFare: number;
  minimumFareApplied: boolean;
  commissionRate: number;
  commissionAmount: number;
  netAmount: number; // totalAmount - commissionAmount
}

// ─────────────────────────────────────────────────────────────
// PURE COMPUTATION (exported for unit testing)
// ─────────────────────────────────────────────────────────────

export function computePrice(
  params: CalculatePriceRequest,
  config?: PricingConfig
): CalculatePriceResponse {
  const {tripType, distanceKm, durationMinutes, surge = "normal", hours, category} = params;

  const fare = resolveFare(tripType, config);
  const surgeMultiplier = fare.surgeAllowed ? SURGE_MULTIPLIERS[surge] : 1.0;
  const categoryMultiplier = resolveCategoryMultiplier(category, config);

  // Calculate components
  const distanceAmount = distanceKm * fare.perKm;
  let timeAmount = 0;

  if (tripType === "event") {
    // Event: charge by number of hours (minimum minimumHours)
    const effectiveHours = Math.max(hours ?? 0, fare.minimumHours);
    timeAmount = effectiveHours * fare.perHour;
  } else {
    timeAmount = durationMinutes * fare.perMinute;
  }

  const subtotal = fare.baseFare + distanceAmount + timeAmount;
  // The category multiplier scales the whole fare, minimum included, so a
  // premium ride is never priced below its scaled minimum.
  const subtotalWithSurge = subtotal * surgeMultiplier * categoryMultiplier;
  const minimumFare = Math.round(fare.minimumFare * categoryMultiplier * 100) / 100;

  // Apply minimum fare
  const minimumFareApplied = subtotalWithSurge < minimumFare;
  const totalAmount = Math.round(Math.max(subtotalWithSurge, minimumFare) * 100) / 100;

  // Calculate commission
  const commissionAmount = Math.round(totalAmount * fare.commission * 100) / 100;
  const netAmount = Math.round((totalAmount - commissionAmount) * 100) / 100;

  return {
    tripType,
    baseFare: fare.baseFare,
    distanceAmount: Math.round(distanceAmount * 100) / 100,
    timeAmount: Math.round(timeAmount * 100) / 100,
    subtotal: Math.round(subtotal * 100) / 100,
    surgeMultiplier,
    categoryMultiplier,
    totalAmount,
    minimumFare,
    minimumFareApplied,
    commissionRate: fare.commission,
    commissionAmount,
    netAmount,
  };
}

// ─────────────────────────────────────────────────────────────
// CLOUD FUNCTION
// ─────────────────────────────────────────────────────────────

export const calculatePrice = functions.https.onCall(
  async (data: CalculatePriceRequest, context: functions.https.CallableContext): Promise<CalculatePriceResponse> => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "User not authenticated.");
    }

    const {tripType, distanceKm, durationMinutes, surge = "normal", hours} = data;

    // Validate trip type
    if (!FARES[tripType]) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `Invalid trip type: "${tripType}". Use: regular, scheduled, airport, event.`
      );
    }

    // Validate distance
    if (typeof distanceKm !== "number" || distanceKm < 0 || distanceKm > 500) {
      throw new functions.https.HttpsError("invalid-argument", "distanceKm must be a number between 0 and 500.");
    }

    // Validate duration
    if (typeof durationMinutes !== "number" || durationMinutes < 0) {
      throw new functions.https.HttpsError("invalid-argument", "durationMinutes must be a positive number.");
    }

    // Validate surge
    if (!SURGE_MULTIPLIERS[surge]) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `Invalid surge level: "${surge}". Use: normal, moderate, high, extreme, maximum.`
      );
    }

    // Validate hours for event trips
    if (tripType === "event") {
      if (typeof hours !== "number" || hours <= 0) {
        throw new functions.https.HttpsError("invalid-argument", "For event trip type, hours is required and must be > 0.");
      }
    }

    const config = await loadPricingConfig(admin.database());
    return computePrice(data, config);
  }
);

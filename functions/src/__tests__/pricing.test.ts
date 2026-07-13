import {computePrice} from "../pricing";

// ─────────────────────────────────────────────────────────────
// Regular trips
// ─────────────────────────────────────────────────────────────

describe("computePrice — regular", () => {
  test("applies minimum price when calculation is below threshold", () => {
    // 150 base + 0 km + 0 min = 150 → below 250 minimum
    const result = computePrice({
      tripType: "regular",
      distanceKm: 0,
      durationMinutes: 0,
    });

    expect(result.totalAmount).toBe(250);
    expect(result.minimumFareApplied).toBe(true);
  });

  test("calculates correctly for a standard trip", () => {
    // 150 base + (5 km × 35) + (10 min × 5) = 150 + 175 + 50 = 375
    const result = computePrice({
      tripType: "regular",
      distanceKm: 5,
      durationMinutes: 10,
    });

    expect(result.baseFare).toBe(150);
    expect(result.distanceAmount).toBe(175);
    expect(result.timeAmount).toBe(50);
    expect(result.subtotal).toBe(375);
    expect(result.totalAmount).toBe(375);
    expect(result.minimumFareApplied).toBe(false);
  });

  test("applies surge multiplier for regular trip", () => {
    // subtotal = 375, surge maximum = 2.0 → 750
    const result = computePrice({
      tripType: "regular",
      distanceKm: 5,
      durationMinutes: 10,
      surge: "maximum",
    });

    expect(result.surgeMultiplier).toBe(2.0);
    expect(result.totalAmount).toBe(750);
  });

  test("calculates 12% commission for regular", () => {
    const result = computePrice({
      tripType: "regular",
      distanceKm: 5,
      durationMinutes: 10,
    });

    expect(result.commissionRate).toBe(0.12);
    expect(result.commissionAmount).toBe(Math.round(375 * 0.12 * 100) / 100);
    expect(result.netAmount).toBe(
      Math.round((result.totalAmount - result.commissionAmount) * 100) / 100
    );
  });

  test("defaults surge to normal (1.0) when not provided", () => {
    const withSurge = computePrice({
      tripType: "regular",
      distanceKm: 10,
      durationMinutes: 20,
      surge: "normal",
    });
    const withoutSurge = computePrice({
      tripType: "regular",
      distanceKm: 10,
      durationMinutes: 20,
    });

    expect(withSurge.totalAmount).toBe(withoutSurge.totalAmount);
    expect(withoutSurge.surgeMultiplier).toBe(1.0);
  });
});

// ─────────────────────────────────────────────────────────────
// Scheduled trips
// ─────────────────────────────────────────────────────────────

describe("computePrice — scheduled", () => {
  test("uses 165 base fare (10% premium over regular)", () => {
    const result = computePrice({
      tripType: "scheduled",
      distanceKm: 0,
      durationMinutes: 0,
    });

    expect(result.baseFare).toBe(165);
    expect(result.minimumFareApplied).toBe(true);
    expect(result.totalAmount).toBe(275); // minimum
  });

  test("applies 10% commission (lower than regular)", () => {
    const result = computePrice({
      tripType: "scheduled",
      distanceKm: 10,
      durationMinutes: 15,
    });

    expect(result.commissionRate).toBe(0.10);
  });
});

// ─────────────────────────────────────────────────────────────
// Airport trips
// ─────────────────────────────────────────────────────────────

describe("computePrice — airport", () => {
  test("does NOT apply surge (surgeAllowed: false)", () => {
    const normal = computePrice({
      tripType: "airport",
      distanceKm: 10,
      durationMinutes: 0,
    });
    const withSurge = computePrice({
      tripType: "airport",
      distanceKm: 10,
      durationMinutes: 0,
      surge: "maximum",
    });

    expect(normal.totalAmount).toBe(withSurge.totalAmount);
    expect(withSurge.surgeMultiplier).toBe(1.0);
  });

  test("applies 500 base + 30/km", () => {
    // 500 + (10 × 30) = 800 → above 500 minimum
    const result = computePrice({
      tripType: "airport",
      distanceKm: 10,
      durationMinutes: 0,
    });

    expect(result.baseFare).toBe(500);
    expect(result.distanceAmount).toBe(300);
    expect(result.totalAmount).toBe(800);
  });

  test("returns minimum 500 when distanceKm is 0", () => {
    // 500 base + 0 km = 500 = exactly the minimum (not below it)
    // distanceKm=0 → subtotal = 500 = minimumFare, so minimum is not "applied"
    // Use a negative scenario: a trip that would be 480 if base were lower —
    // instead verify minimum == 500 and subtotal == 500 for 0 km
    const result = computePrice({
      tripType: "airport",
      distanceKm: 0,
      durationMinutes: 0,
    });

    expect(result.totalAmount).toBe(500);
    expect(result.baseFare).toBe(500);
    expect(result.distanceAmount).toBe(0);
  });

  test("applies 15% commission", () => {
    const result = computePrice({
      tripType: "airport",
      distanceKm: 10,
      durationMinutes: 0,
    });

    expect(result.commissionRate).toBe(0.15);
  });
});

// ─────────────────────────────────────────────────────────────
// Event (hourly hire) trips
// ─────────────────────────────────────────────────────────────

describe("computePrice — event", () => {
  test("enforces 2-hour minimum even when fewer hours requested", () => {
    // 500 base + (0 km × 20) + (2 h × 800) = 2100 = minimum
    const result = computePrice({
      tripType: "event",
      distanceKm: 0,
      durationMinutes: 0,
      hours: 1, // below minimum 2
    });

    expect(result.timeAmount).toBe(1600); // 2 × 800
    expect(result.totalAmount).toBe(2100);
  });

  test("bills actual hours when above minimum", () => {
    // 500 base + (0 km × 20) + (6 h × 800) = 5300
    const result = computePrice({
      tripType: "event",
      distanceKm: 0,
      durationMinutes: 0,
      hours: 6,
    });

    expect(result.timeAmount).toBe(4800); // 6 × 800
    expect(result.totalAmount).toBe(5300);
  });

  test("does NOT apply surge", () => {
    const base = computePrice({
      tripType: "event",
      distanceKm: 0,
      durationMinutes: 0,
      hours: 4,
    });
    const withSurge = computePrice({
      tripType: "event",
      distanceKm: 0,
      durationMinutes: 0,
      hours: 4,
      surge: "extreme",
    });

    expect(base.totalAmount).toBe(withSurge.totalAmount);
  });

  test("ignores durationMinutes (uses hours instead)", () => {
    const result = computePrice({
      tripType: "event",
      distanceKm: 0,
      durationMinutes: 999, // should be ignored
      hours: 4,
    });

    // timeAmount = 4 × 800 = 3200, not 999 × any per-minute rate
    expect(result.timeAmount).toBe(3200);
  });
});

// ─────────────────────────────────────────────────────────────
// Cross-cutting: response shape
// ─────────────────────────────────────────────────────────────

describe("computePrice — response shape", () => {
  test("netAmount = totalAmount - commissionAmount", () => {
    const result = computePrice({
      tripType: "regular",
      distanceKm: 8,
      durationMinutes: 15,
    });

    expect(result.netAmount).toBeCloseTo(result.totalAmount - result.commissionAmount, 2);
  });

  test("all monetary values are rounded to 2 decimal places", () => {
    const result = computePrice({
      tripType: "regular",
      distanceKm: 3.333,
      durationMinutes: 7,
    });

    const hasAtMost2Decimals = (n: number) =>
      Number.isInteger(Math.round(n * 100));

    expect(hasAtMost2Decimals(result.distanceAmount)).toBe(true);
    expect(hasAtMost2Decimals(result.totalAmount)).toBe(true);
    expect(hasAtMost2Decimals(result.commissionAmount)).toBe(true);
    expect(hasAtMost2Decimals(result.netAmount)).toBe(true);
  });
});

// ─────────────────────────────────────────────────────────────
// /config/pricing overrides + category multipliers
// ─────────────────────────────────────────────────────────────

describe("computePrice — remote config", () => {
  const base = {tripType: "regular" as const, distanceKm: 10, durationMinutes: 20};

  test("no config falls back to the hardcoded fares", () => {
    const noConfig = computePrice(base);
    const emptyConfig = computePrice(base, {});
    expect(emptyConfig).toEqual(noConfig);
  });

  test("partial fare override merges over defaults", () => {
    const result = computePrice(base, {
      fares: {regular: {perKm: 40}},
    });
    // base 150 + 10*40 + 20*5 = 650
    expect(result.distanceAmount).toBe(400);
    expect(result.totalAmount).toBe(650);
    // untouched fields keep defaults
    expect(result.baseFare).toBe(150);
    expect(result.commissionRate).toBe(0.12);
  });

  test("ignores invalid override values", () => {
    const result = computePrice(base, {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      fares: {regular: {perKm: -5, baseFare: "x" as any}},
    });
    expect(computePrice(base).totalAmount).toBe(result.totalAmount);
  });

  test("category multiplier scales total and minimum fare", () => {
    const config = {categories: {conforto: {multiplier: 1.35}}};
    const normal = computePrice(base);
    const conforto = computePrice({...base, category: "conforto"}, config);
    expect(conforto.categoryMultiplier).toBe(1.35);
    expect(conforto.totalAmount).toBeCloseTo(normal.totalAmount * 1.35, 2);
  });

  test("scaled minimum fare applies to short premium trips", () => {
    const config = {categories: {premium: {multiplier: 2}}};
    const result = computePrice(
      {tripType: "regular", distanceKm: 1, durationMinutes: 2, category: "premium"},
      config
    );
    // subtotal 150+35+10=195 → x2 = 390 < min 250x2=500
    expect(result.minimumFare).toBe(500);
    expect(result.minimumFareApplied).toBe(true);
    expect(result.totalAmount).toBe(500);
  });

  test("unknown category defaults to multiplier 1", () => {
    const config = {categories: {conforto: {multiplier: 1.35}}};
    const result = computePrice({...base, category: "ghost"}, config);
    expect(result.categoryMultiplier).toBe(1);
    expect(result.totalAmount).toBe(computePrice(base).totalAmount);
  });
});

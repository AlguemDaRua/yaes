import {dispatchWebhooks, signPayload} from "../webhooks";
import {db} from "./fake-db";

function hooksSeed(overrides: Record<string, unknown> = {}) {
  return {
    config: {
      webhooks: {
        w1: {
          url: "https://example.com/hook",
          events: ["trip.status"],
          secret: "s3cret",
          active: true,
          ...overrides,
        },
      },
    },
  };
}

describe("dispatchWebhooks", () => {
  test("delivers to an active subscribed endpoint with signature", async () => {
    const calls: Array<{url: string; init: {headers: Record<string, string>; body: string}}> = [];
    const fetchFn = async (url: string, init: never) => {
      calls.push({url, init});
      return {ok: true, status: 200};
    };
    const res = await dispatchWebhooks(
      db(hooksSeed()),
      "trip.status",
      {tripId: "t1", status: "completed"},
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      fetchFn as any
    );
    expect(res.delivered).toBe(1);
    expect(calls[0].url).toBe("https://example.com/hook");
    const body = calls[0].init.body;
    expect(calls[0].init.headers["X-Ya-Signature"]).toBe(
      signPayload("s3cret", body)
    );
    expect(JSON.parse(body)).toMatchObject({
      event: "trip.status",
      data: {tripId: "t1", status: "completed"},
    });
  });

  test("skips inactive endpoints and other events", async () => {
    const fetchFn = jest.fn(async () => ({ok: true, status: 200}));
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const f = fetchFn as any;
    expect(
      (await dispatchWebhooks(db(hooksSeed({active: false})), "trip.status", {}, f))
        .delivered
    ).toBe(0);
    expect(
      (await dispatchWebhooks(db(hooksSeed()), "payment.updated", {}, f)).delivered
    ).toBe(0);
    expect(fetchFn).not.toHaveBeenCalled();
  });

  test("retries once on failure and never throws", async () => {
    const fetchFn = jest
      .fn()
      .mockRejectedValueOnce(new Error("boom"))
      .mockResolvedValueOnce({ok: true, status: 200});
    const res = await dispatchWebhooks(
      db(hooksSeed()),
      "trip.status",
      {},
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      fetchFn as any
    );
    expect(res.delivered).toBe(1);
    expect(fetchFn).toHaveBeenCalledTimes(2);
  });

  test("no config node delivers nothing", async () => {
    const fetchFn = jest.fn();
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const res = await dispatchWebhooks(db(), "trip.status", {}, fetchFn as any);
    expect(res.delivered).toBe(0);
  });
});

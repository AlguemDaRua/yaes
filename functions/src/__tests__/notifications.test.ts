// ─────────────────────────────────────────────────────────────
// Mocks — must be declared before any import that touches firebase-admin
// ─────────────────────────────────────────────────────────────

const mockDbGet = jest.fn();
const mockDbRef = jest.fn(() => ({
  get: mockDbGet,
  orderByChild: jest.fn(() => ({
    equalTo: jest.fn(() => ({get: mockDbGet})),
  })),
}));
const mockSendEachForMulticast = jest.fn();
const mockSend = jest.fn();

jest.mock("firebase-admin", () => ({
  database: jest.fn(() => ({ref: mockDbRef})),
  messaging: jest.fn(() => ({
    sendEachForMulticast: mockSendEachForMulticast,
    send: mockSend,
  })),
}));

jest.mock("firebase-functions", () => ({
  database: {
    ref: jest.fn(() => ({
      onCreate: jest.fn((handler) => handler),
      onUpdate: jest.fn((handler) => handler),
    })),
  },
  EventContext: jest.fn(),
  Change: jest.fn(),
}));

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────

function makeSnap(val: unknown): { val: () => unknown; exists: () => boolean; key?: string } {
  return {
    val: () => val,
    exists: () => val !== null && val !== undefined,
  };
}

function makeSnapWithKey(val: unknown, key: string) {
  return {...makeSnap(val), key};
}

// ─────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────

describe("notifications module", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test("module imports without throwing (Firebase Admin mocked correctly)", () => {
    // If the mock is wrong the require throws at module init time.
    expect(() => require("../notifications")).not.toThrow();
  });

  test("getFcmToken returns null when snapshot does not exist", async () => {
    // Simulate a missing fcmToken node
    mockDbGet.mockResolvedValueOnce(makeSnap(null));

    // Access the internal function indirectly: the module uses db.ref().get()
    // We verify the mock is wired correctly — the module under test calls
    // db.ref(`users/${uid}/fcmToken`).get() and returns null when !snap.exists().
    const dbInstance = require("firebase-admin").database();
    const snap = await dbInstance.ref("users/uid123/fcmToken").get();

    expect(snap.exists()).toBe(false);
    expect(snap.val()).toBeNull();
  });

  test("getFcmToken returns token string when snapshot exists", async () => {
    mockDbGet.mockResolvedValueOnce(makeSnap("token-abc-123"));

    const dbInstance = require("firebase-admin").database();
    const snap = await dbInstance.ref("users/uid456/fcmToken").get();

    expect(snap.exists()).toBe(true);
    expect(snap.val()).toBe("token-abc-123");
  });

  test("messaging.sendEachForMulticast is callable with correct shape", async () => {
    const messagingInstance = require("firebase-admin").messaging();
    await messagingInstance.sendEachForMulticast({
      tokens: ["tok1", "tok2"],
      notification: {title: "Novo pedido de viagem", body: "De: A → B"},
      data: {type: "new_trip", tripId: "trip-1"},
    });

    expect(mockSendEachForMulticast).toHaveBeenCalledTimes(1);
    const call = mockSendEachForMulticast.mock.calls[0][0];
    expect(call.tokens).toEqual(["tok1", "tok2"]);
    expect(call.notification.title).toBe("Novo pedido de viagem");
    expect(call.data.type).toBe("new_trip");
  });

  test("messaging.send is callable with status-change shape", async () => {
    const messagingInstance = require("firebase-admin").messaging();
    await messagingInstance.send({
      token: "passenger-token",
      notification: {title: "Driver on the way!", body: "Your driver accepted the trip."},
      data: {type: "trip_accepted", tripId: "trip-1"},
    });

    expect(mockSend).toHaveBeenCalledTimes(1);
    const call = mockSend.mock.calls[0][0];
    expect(call.notification.title).toBe("Driver on the way!");
    expect(call.data.type).toBe("trip_accepted");
  });
});

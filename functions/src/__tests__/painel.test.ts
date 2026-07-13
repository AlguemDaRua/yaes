import {
  setUserRoleCore,
  createPartnerCore,
  setPartnerStatusCore,
  processPayoutCore,
  inviteDriverCore,
  assignVehicleCore,
  applyPendingInviteCore,
  setCommissionCore,
  reviewDocumentCore,
  setUserStatusCore,
  inviteManagerCore,
  createPartnerWithOwnerCore,
  invitePartnerStaffCore,
  revokeUserSessionsCore,
  phoneKey,
} from "../painel";
import {
  assignTicketCore,
  replyTicketCore,
  closeTicketCore,
  resolveDisputeCore,
  createTicketCore,
} from "../support";
import {db, expectHttpsError} from "./fake-db";

const ADMIN = {admins: {"admin-uid": true}};

// ─────────────────────────────────────────────────────────────
// setUserRole
// ─────────────────────────────────────────────────────────────

describe("setUserRoleCore", () => {
  test("rejects non-admin caller", async () => {
    await expectHttpsError(
      setUserRoleCore(db(), "nobody", {uid: "u1", role: "support"}),
      "permission-denied"
    );
  });

  test("rejects invalid role", async () => {
    await expectHttpsError(
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      setUserRoleCore(db(ADMIN), "admin-uid", {uid: "u1", role: "ceo" as any}),
      "invalid-argument"
    );
  });

  test("driver role requires partnerId", async () => {
    await expectHttpsError(
      setUserRoleCore(db(ADMIN), "admin-uid", {uid: "u1", role: "driver"}),
      "invalid-argument"
    );
  });

  test("sets type and partnerId for a driver", async () => {
    const d = db(ADMIN);
    const res = await setUserRoleCore(d, "admin-uid", {
      uid: "u1",
      role: "driver",
      partnerId: "p1",
    });
    expect(res).toEqual({success: true, uid: "u1", role: "driver"});
    expect(d.store.users.u1).toEqual({type: "driver", partnerId: "p1"});
  });

  test("sets a partner-less role without partnerId", async () => {
    const d = db(ADMIN);
    await setUserRoleCore(d, "admin-uid", {uid: "u2", role: "support"});
    expect(d.store.users.u2).toEqual({type: "support"});
  });
});

// ─────────────────────────────────────────────────────────────
// createPartner
// ─────────────────────────────────────────────────────────────

describe("createPartnerCore", () => {
  const seed = {...ADMIN, users: {owner1: {phone: "+258840000000", type: "passenger"}}};

  test("rejects non-admin", async () => {
    await expectHttpsError(
      createPartnerCore(db(seed), "nobody", {
        name: "Maputo Exec",
        nuit: "123",
        city: "Maputo",
        ownerUid: "owner1",
      }),
      "permission-denied"
    );
  });

  test("rejects missing fields", async () => {
    await expectHttpsError(
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      createPartnerCore(db(seed), "admin-uid", {name: "X"} as any),
      "invalid-argument"
    );
  });

  test("rejects unknown ownerUid", async () => {
    await expectHttpsError(
      createPartnerCore(db(seed), "admin-uid", {
        name: "X",
        nuit: "1",
        city: "Maputo",
        ownerUid: "ghost",
      }),
      "failed-precondition"
    );
  });

  test("creates partner (pending) and promotes the owner", async () => {
    const d = db(seed);
    const res = await createPartnerCore(d, "admin-uid", {
      name: "Maputo Exec",
      nuit: "123456789",
      city: "Maputo",
      ownerUid: "owner1",
      email: "a@b.mz",
    });
    const pid = res.partnerId;
    expect(pid).toBeTruthy();
    expect(d.store.partners[pid]).toMatchObject({
      name: "Maputo Exec",
      nuit: "123456789",
      city: "Maputo",
      status: "pending",
      email: "a@b.mz",
    });
    expect(d.store.users.owner1).toMatchObject({
      type: "partner_owner",
      partnerId: pid,
    });
  });
});

// ─────────────────────────────────────────────────────────────
// approve / suspend partner
// ─────────────────────────────────────────────────────────────

describe("setPartnerStatusCore", () => {
  const seed = {...ADMIN, partners: {p1: {name: "P", status: "pending"}}};

  test("approve sets active", async () => {
    const d = db(seed);
    await setPartnerStatusCore(d, "admin-uid", "p1", "active");
    expect(d.store.partners.p1.status).toBe("active");
  });

  test("suspend sets suspended + reason", async () => {
    const d = db(seed);
    await setPartnerStatusCore(d, "admin-uid", "p1", "suspended", "fraude");
    expect(d.store.partners.p1.status).toBe("suspended");
    expect(d.store.partners.p1.suspendReason).toBe("fraude");
  });

  test("rejects unknown partner", async () => {
    await expectHttpsError(
      setPartnerStatusCore(db(ADMIN), "admin-uid", "ghost", "active"),
      "not-found"
    );
  });

  test("rejects non-admin", async () => {
    await expectHttpsError(
      setPartnerStatusCore(db(seed), "nobody", "p1", "active"),
      "permission-denied"
    );
  });
});

// ─────────────────────────────────────────────────────────────
// processPayout
// ─────────────────────────────────────────────────────────────

describe("processPayoutCore", () => {
  test("rejects non-positive amount", async () => {
    await expectHttpsError(
      processPayoutCore(db(ADMIN), "admin-uid", {
        partnerId: "p1",
        amountMtn: 0,
        method: "mpesa",
      }),
      "invalid-argument"
    );
  });

  test("rejects invalid method", async () => {
    await expectHttpsError(
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      processPayoutCore(db(ADMIN), "admin-uid", {
        partnerId: "p1",
        amountMtn: 100,
        method: "paypal" as any,
      }),
      "invalid-argument"
    );
  });

  test("writes a paid payout and returns its id", async () => {
    const d = db(ADMIN);
    const res = await processPayoutCore(d, "admin-uid", {
      partnerId: "p1",
      amountMtn: 5000,
      method: "mpesa",
      reference: "MP-123",
    });
    expect(res.payoutId).toBeTruthy();
    expect(d.store.payouts.p1[res.payoutId]).toMatchObject({
      amountMtn: 5000,
      method: "mpesa",
      status: "paid",
      reference: "MP-123",
    });
  });
});

// ─────────────────────────────────────────────────────────────
// inviteDriver
// ─────────────────────────────────────────────────────────────

describe("inviteDriverCore", () => {
  test("rejects unrelated partner_owner", async () => {
    const d = db({
      users: {owner2: {type: "partner_owner", partnerId: "OTHER"}},
    });
    await expectHttpsError(
      d && inviteDriverCore(d, "owner2", {partnerId: "p1", phone: "+258841111111"}),
      "permission-denied"
    );
  });

  test("links an existing user by phone (admin caller)", async () => {
    const d = db({
      ...ADMIN,
      users: {drv: {phone: "+258841234567", type: "passenger"}},
    });
    const res = await inviteDriverCore(d, "admin-uid", {
      partnerId: "p1",
      phone: "+258841234567",
      vehicleId: "v1",
    });
    expect(res).toEqual({status: "linked", uid: "drv"});
    expect(d.store.users.drv).toMatchObject({type: "driver", partnerId: "p1", vehicleId: "v1"});
    expect(d.store.partners.p1.vehicles.v1.driverId).toBe("drv");
    expect(d.store.partners.p1.drivers.drv).toBe(true);
  });

  test("partner_owner can invite into their own partner", async () => {
    const d = db({
      users: {
        owner1: {type: "partner_owner", partnerId: "p1"},
        drv: {phone: "+258849999999", type: "passenger"},
      },
    });
    const res = await inviteDriverCore(d, "owner1", {
      partnerId: "p1",
      phone: "+258849999999",
    });
    expect(res).toEqual({status: "linked", uid: "drv"});
  });

  test("refuses to hijack a non-passenger (admin) user by phone", async () => {
    const d = db({
      ...ADMIN,
      users: {boss: {phone: "+258840000000", type: "admin"}},
    });
    await expectHttpsError(
      inviteDriverCore(d, "admin-uid", {
        partnerId: "p1",
        phone: "+258840000000",
      }),
      "failed-precondition"
    );
    expect(d.store.users.boss.type).toBe("admin");
  });

  test("refuses to steal a driver already in another partner", async () => {
    const d = db({
      ...ADMIN,
      users: {drv: {phone: "+258849999999", type: "driver", partnerId: "OTHER"}},
    });
    await expectHttpsError(
      inviteDriverCore(d, "admin-uid", {
        partnerId: "p1",
        phone: "+258849999999",
      }),
      "failed-precondition"
    );
    expect(d.store.users.drv.partnerId).toBe("OTHER");
  });

  test("creates a pending invite when no user has that phone", async () => {
    const d = db(ADMIN);
    const res = await inviteDriverCore(d, "admin-uid", {
      partnerId: "p1",
      phone: "+258 84 765 4321",
      name: "Novo Motorista",
    });
    expect(res).toEqual({status: "invited", phoneKey: "258847654321"});
    expect(d.store.partnerInvites["258847654321"]).toMatchObject({
      partnerId: "p1",
      role: "driver",
      name: "Novo Motorista",
    });
  });
});

// ─────────────────────────────────────────────────────────────
// applyPendingInviteCore (onUserCreated)
// ─────────────────────────────────────────────────────────────

describe("applyPendingInviteCore", () => {
  test("no-op when the new user has no phone", async () => {
    const d = db();
    expect(await applyPendingInviteCore(d, "u1", undefined)).toEqual({applied: false});
  });

  test("no-op when there is no matching invite", async () => {
    const d = db({users: {u1: {phone: "+258840000000"}}});
    expect(await applyPendingInviteCore(d, "u1", "+258840000000")).toEqual({
      applied: false,
    });
  });

  test("links the user, assigns the vehicle and consumes the invite", async () => {
    const d = db({
      users: {u1: {phone: "+258 84 765 4321", type: "passenger"}},
      partnerInvites: {
        "258847654321": {partnerId: "p1", role: "driver", vehicleId: "v1"},
      },
    });
    const res = await applyPendingInviteCore(d, "u1", "+258 84 765 4321");
    expect(res).toEqual({applied: true});
    expect(d.store.users.u1).toMatchObject({
      type: "driver",
      partnerId: "p1",
      vehicleId: "v1",
    });
    expect(d.store.partners.p1.vehicles.v1.driverId).toBe("u1");
    expect(d.store.partners.p1.drivers.u1).toBe(true);
    expect(d.store.partnerInvites["258847654321"]).toBeUndefined();
  });
});

// ─────────────────────────────────────────────────────────────
// assignVehicleCore
// ─────────────────────────────────────────────────────────────

describe("assignVehicleCore", () => {
  test("rejects unrelated partner_owner", async () => {
    const d = db({users: {o2: {type: "partner_owner", partnerId: "OTHER"}}});
    await expectHttpsError(
      assignVehicleCore(d, "o2", {partnerId: "p1", vehicleId: "v1", driverUid: "drv"}),
      "permission-denied"
    );
  });

  test("assigns driver to vehicle (both sides)", async () => {
    const d = db({
      ...ADMIN,
      partners: {p1: {vehicles: {v1: {plate: "AAA"}}}},
      users: {drv: {type: "driver", partnerId: "p1"}},
    });
    const res = await assignVehicleCore(d, "admin-uid", {
      partnerId: "p1",
      vehicleId: "v1",
      driverUid: "drv",
    });
    expect(res).toEqual({success: true});
    expect(d.store.partners.p1.vehicles.v1.driverId).toBe("drv");
    expect(d.store.users.drv.vehicleId).toBe("v1");
    expect(d.store.partners.p1.drivers.drv).toBe(true);
  });

  test("reassigning releases the previous driver", async () => {
    const d = db({
      ...ADMIN,
      partners: {p1: {vehicles: {v1: {plate: "AAA", driverId: "old"}}}},
      users: {old: {vehicleId: "v1"}, neu: {}},
    });
    await assignVehicleCore(d, "admin-uid", {
      partnerId: "p1",
      vehicleId: "v1",
      driverUid: "neu",
    });
    expect(d.store.partners.p1.vehicles.v1.driverId).toBe("neu");
    expect(d.store.users.neu.vehicleId).toBe("v1");
    expect(d.store.users.old.vehicleId).toBeUndefined();
  });

  test("releases the driver's previous vehicle on reassign", async () => {
    const d = db({
      ...ADMIN,
      partners: {
        p1: {
          vehicles: {
            v1: {plate: "AAA", driverId: "drv"},
            v2: {plate: "BBB"},
          },
        },
      },
      users: {drv: {vehicleId: "v1"}},
    });
    await assignVehicleCore(d, "admin-uid", {
      partnerId: "p1",
      vehicleId: "v2",
      driverUid: "drv",
    });
    expect(d.store.partners.p1.vehicles.v2.driverId).toBe("drv");
    expect(d.store.users.drv.vehicleId).toBe("v2");
    expect(d.store.partners.p1.vehicles.v1.driverId).toBeUndefined();
  });

  test("unassigns when driverUid is null", async () => {
    const d = db({
      ...ADMIN,
      partners: {p1: {vehicles: {v1: {plate: "AAA", driverId: "drv"}}}},
      users: {drv: {vehicleId: "v1"}},
    });
    await assignVehicleCore(d, "admin-uid", {
      partnerId: "p1",
      vehicleId: "v1",
      driverUid: null,
    });
    expect(d.store.partners.p1.vehicles.v1.driverId).toBeUndefined();
    expect(d.store.users.drv.vehicleId).toBeUndefined();
  });
});

describe("phoneKey", () => {
  test("strips non-digits", () => {
    expect(phoneKey("+258 84 123 4567")).toBe("258841234567");
  });
});

// ─────────────────────────────────────────────────────────────
// Admin write cores: setCommission / reviewDocument / setUserStatus
// ─────────────────────────────────────────────────────────────

describe("setCommissionCore", () => {
  test("rejects non-admin", async () => {
    const d = db({users: {u1: {type: "partner_owner", partnerId: "p1"}}});
    await expectHttpsError(
      setCommissionCore(d, "u1", {partnerId: "p1", rate: 0.1}),
      "permission-denied"
    );
  });
  test("rejects an out-of-range rate", async () => {
    const d = db(ADMIN);
    await expectHttpsError(
      setCommissionCore(d, "admin-uid", {partnerId: "p1", rate: 1.5}),
      "invalid-argument"
    );
  });
  test("writes the commission", async () => {
    const d = db(ADMIN);
    const res = await setCommissionCore(d, "admin-uid", {partnerId: "p1", rate: 0.12, label: "Tier A"});
    expect(res).toEqual({success: true, partnerId: "p1"});
    expect(d.store.commissions.p1).toMatchObject({rate: 0.12, status: "active", label: "Tier A"});
  });
});

describe("reviewDocumentCore", () => {
  test("rejects non-admin", async () => {
    const d = db({documents: {driver: {drv: {doc1: {status: "pending"}}}}});
    await expectHttpsError(
      reviewDocumentCore(d, "nobody", {ownerType: "driver", ownerId: "drv", docId: "doc1", status: "approved"}),
      "permission-denied"
    );
  });
  test("404 when the document is missing", async () => {
    const d = db(ADMIN);
    await expectHttpsError(
      reviewDocumentCore(d, "admin-uid", {ownerType: "driver", ownerId: "drv", docId: "x", status: "approved"}),
      "not-found"
    );
  });
  test("sets the document status", async () => {
    const d = db({...ADMIN, documents: {driver: {drv: {doc1: {status: "pending"}}}}});
    const res = await reviewDocumentCore(d, "admin-uid", {ownerType: "driver", ownerId: "drv", docId: "doc1", status: "approved"});
    expect(res).toEqual({success: true});
    expect(d.store.documents.driver.drv.doc1.status).toBe("approved");
    expect(d.store.documents.driver.drv.doc1.reviewedBy).toBe("admin-uid");
  });
});

describe("setUserStatusCore", () => {
  test("rejects non-admin", async () => {
    const d = db({users: {drv: {type: "driver"}}});
    await expectHttpsError(
      setUserStatusCore(d, "drv", {uid: "drv", status: "suspended"}),
      "permission-denied"
    );
  });
  test("suspends a user without touching type", async () => {
    const d = db({...ADMIN, users: {drv: {type: "driver", partnerId: "p1"}}});
    const res = await setUserStatusCore(d, "admin-uid", {uid: "drv", status: "suspended", reason: "fraude"});
    expect(res).toEqual({success: true, uid: "drv", status: "suspended"});
    expect(d.store.users.drv).toMatchObject({type: "driver", status: "suspended", suspendReason: "fraude"});
  });
});

// ─────────────────────────────────────────────────────────────
// Support write cores
// ─────────────────────────────────────────────────────────────

const SUPPORT = {users: {sup: {type: "support"}}};

describe("support cores authorization", () => {
  test("a passenger cannot assign a ticket", async () => {
    const d = db({users: {pax: {type: "passenger"}}, tickets: {t1: {status: "open"}}});
    await expectHttpsError(
      assignTicketCore(d, "pax", {ticketId: "t1", agentUid: "sup"}),
      "permission-denied"
    );
  });
});

describe("assignTicketCore", () => {
  test("assigns and moves to in_progress", async () => {
    const d = db({...SUPPORT, tickets: {t1: {status: "open"}}});
    const res = await assignTicketCore(d, "sup", {ticketId: "t1", agentUid: "sup"});
    expect(res).toEqual({success: true});
    expect(d.store.tickets.t1).toMatchObject({assignedTo: "sup", status: "in_progress"});
  });
  test("404 for a missing ticket", async () => {
    const d = db(SUPPORT);
    await expectHttpsError(
      assignTicketCore(d, "sup", {ticketId: "nope", agentUid: "sup"}),
      "not-found"
    );
  });
});

describe("replyTicketCore", () => {
  test("appends a message and bumps lastMessageAt", async () => {
    const d = db({...SUPPORT, tickets: {t1: {status: "open"}}});
    const res = await replyTicketCore(d, "sup", {ticketId: "t1", text: "Ola", authorName: "Ana"});
    expect(res.messageId).toBeTruthy();
    const messages = d.store.tickets.t1.messages as Record<string, {text: string; author: string}>;
    const first = Object.values(messages)[0];
    expect(first).toMatchObject({text: "Ola", author: "Ana", role: "support"});
    expect(d.store.tickets.t1.lastMessageAt).toBeTruthy();
  });
  test("rejects empty text", async () => {
    const d = db({...SUPPORT, tickets: {t1: {status: "open"}}});
    await expectHttpsError(
      replyTicketCore(d, "sup", {ticketId: "t1", text: "   "}),
      "invalid-argument"
    );
  });
});

describe("closeTicketCore", () => {
  test("marks the ticket resolved", async () => {
    const d = db({...SUPPORT, tickets: {t1: {status: "in_progress"}}});
    const res = await closeTicketCore(d, "sup", {ticketId: "t1"});
    expect(res).toEqual({success: true});
    expect(d.store.tickets.t1).toMatchObject({status: "resolved", resolvedBy: "sup"});
  });
});

describe("resolveDisputeCore", () => {
  test("rejects empty resolution", async () => {
    const d = db({...SUPPORT, disputes: {trip1: {status: "open"}}});
    await expectHttpsError(
      resolveDisputeCore(d, "sup", {tripId: "trip1", resolution: ""}),
      "invalid-argument"
    );
  });
  test("resolves the dispute", async () => {
    const d = db({...SUPPORT, disputes: {trip1: {status: "open"}}});
    const res = await resolveDisputeCore(d, "sup", {tripId: "trip1", resolution: "Reembolso emitido"});
    expect(res).toEqual({success: true});
    expect(d.store.disputes.trip1).toMatchObject({status: "resolved", resolution: "Reembolso emitido"});
  });
});

describe("createTicketCore", () => {
  test("creates an open ticket with a first message", async () => {
    const d = db(SUPPORT);
    const res = await createTicketCore(d, "sup", {subject: "Teste", text: "Corpo", priority: "high"});
    expect(res.ticketId).toBeTruthy();
    const ticket = d.store.tickets[res.ticketId];
    expect(ticket).toMatchObject({subject: "Teste", status: "open", priority: "high", preview: "Corpo"});
    expect(ticket.messages.m1).toMatchObject({text: "Corpo", role: "support"});
  });
  test("rejects a blank subject", async () => {
    const d = db(SUPPORT);
    await expectHttpsError(createTicketCore(d, "sup", {subject: "  "}), "invalid-argument");
  });
  test("self-service: a passenger can open a ticket in their own name", async () => {
    const d = db({users: {pax: {type: "passenger"}}});
    const res = await createTicketCore(d, "pax", {subject: "Preciso de ajuda", text: "Oi"});
    const ticket = d.store.tickets[res.ticketId];
    expect(ticket).toMatchObject({authorUid: "pax", role: "passenger"});
    expect(ticket.messages.m1).toMatchObject({authorUid: "pax", role: "passenger"});
  });
  test("rejects a passenger opening a ticket in someone else's name", async () => {
    const d = db({users: {pax: {type: "passenger"}}});
    await expectHttpsError(
      createTicketCore(d, "pax", {subject: "Teste", authorUid: "other-uid"}),
      "permission-denied"
    );
  });
});

// ─────────────────────────────────────────────────────────────
// inviteManager
// ─────────────────────────────────────────────────────────────

describe("inviteManagerCore", () => {
  const auth = () => ({
    createUser: jest.fn(async () => ({uid: "new-uid"})),
    generatePasswordResetLink: jest.fn(async () => "https://reset.link/x"),
  });

  test("rejects non-admin caller", async () => {
    await expectHttpsError(
      inviteManagerCore(db(), auth(), "nobody", {
        email: "a@b.co",
        role: "support",
      }),
      "permission-denied"
    );
  });

  test("rejects invalid email", async () => {
    await expectHttpsError(
      inviteManagerCore(db(ADMIN), auth(), "admin-uid", {
        email: "not-an-email",
        role: "support",
      }),
      "invalid-argument"
    );
  });

  test("rejects invalid role", async () => {
    await expectHttpsError(
      inviteManagerCore(db(ADMIN), auth(), "admin-uid", {
        email: "a@b.co",
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        role: "boss" as any,
      }),
      "invalid-argument"
    );
  });

  test("creates a support user without admin flag", async () => {
    const d = db(ADMIN);
    const res = await inviteManagerCore(d, auth(), "admin-uid", {
      email: "sup@ya.mz",
      role: "support",
      name: "Suporte",
    });
    expect(res).toEqual({uid: "new-uid", resetLink: "https://reset.link/x"});
    expect(d.store.users["new-uid"]).toMatchObject({
      type: "support",
      email: "sup@ya.mz",
      name: "Suporte",
      status: "active",
    });
    expect(d.store.admins["new-uid"]).toBeUndefined();
  });

  test("creates an admin user and sets the admin flag", async () => {
    const d = db(ADMIN);
    await inviteManagerCore(d, auth(), "admin-uid", {
      email: "novo@ya.mz",
      role: "admin",
    });
    expect(d.store.admins["new-uid"]).toBe(true);
  });

  test("writes an audit entry", async () => {
    const d = db(ADMIN);
    await inviteManagerCore(d, auth(), "admin-uid", {
      email: "novo@ya.mz",
      role: "admin",
    });
    const entries = Object.values(d.store.audit as Record<string, unknown>);
    expect(entries[0]).toMatchObject({
      action: "inviteManager",
      actorUid: "admin-uid",
      targetId: "new-uid",
    });
  });
});

describe("setUserRoleCore admins sync", () => {
  test("granting admin sets /admins/{uid}", async () => {
    const d = db(ADMIN);
    await setUserRoleCore(d, "admin-uid", {uid: "u9", role: "admin"});
    expect(d.store.admins.u9).toBe(true);
  });

  test("demoting from admin clears /admins/{uid}", async () => {
    const d = db({admins: {"admin-uid": true, u9: true}});
    await setUserRoleCore(d, "admin-uid", {uid: "u9", role: "support"});
    expect(d.store.admins.u9).toBeUndefined();
  });
});

describe("revokeUserSessionsCore", () => {
  const auth = () => ({revokeRefreshTokens: jest.fn(async () => undefined)});

  test("rejects non-admin caller", async () => {
    await expectHttpsError(
      revokeUserSessionsCore(db(), auth(), "nobody", {uid: "u1"}),
      "permission-denied"
    );
  });

  test("rejects missing uid", async () => {
    await expectHttpsError(
      revokeUserSessionsCore(db(ADMIN), auth(), "admin-uid", {uid: ""}),
      "invalid-argument"
    );
  });

  test("revokes tokens and writes audit", async () => {
    const a = auth();
    const d = db(ADMIN);
    const res = await revokeUserSessionsCore(d, a, "admin-uid", {uid: "u1"});
    expect(res).toEqual({success: true, uid: "u1"});
    expect(a.revokeRefreshTokens).toHaveBeenCalledWith("u1");
    const entries = Object.values(d.store.audit as Record<string, unknown>);
    expect(entries[0]).toMatchObject({action: "revokeUserSessions", targetId: "u1"});
  });
});

// ─────────────────────────────────────────────────────────────
// createPartnerWithOwner
// ─────────────────────────────────────────────────────────────

describe("createPartnerWithOwnerCore", () => {
  const auth = () => ({
    createUser: jest.fn(async () => ({uid: "owner-uid"})),
    generatePasswordResetLink: jest.fn(async () => "https://reset/x"),
  });

  const valid = {
    name: "Costa do Sol, Lda",
    nuit: "400238517",
    city: "Maputo",
    ownerEmail: "dono@exemplo.co.mz",
    ownerName: "Dono Exemplo",
  };

  test("rejects non-admin caller", async () => {
    await expectHttpsError(
      createPartnerWithOwnerCore(db(), auth(), "nobody", valid),
      "permission-denied"
    );
  });

  test("rejects missing partner fields", async () => {
    await expectHttpsError(
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      createPartnerWithOwnerCore(db(ADMIN), auth(), "admin-uid", {
        ownerEmail: "a@b.co",
      } as any),
      "invalid-argument"
    );
  });

  test("rejects invalid owner email", async () => {
    await expectHttpsError(
      createPartnerWithOwnerCore(db(ADMIN), auth(), "admin-uid", {
        ...valid,
        ownerEmail: "not-an-email",
      }),
      "invalid-argument"
    );
  });

  test("creates partner (pending) + owner (partner_owner) and returns link", async () => {
    const d = db(ADMIN);
    const res = await createPartnerWithOwnerCore(d, auth(), "admin-uid", valid);
    expect(res.ownerUid).toBe("owner-uid");
    expect(res.resetLink).toBe("https://reset/x");
    expect(d.store.partners[res.partnerId]).toMatchObject({
      name: "Costa do Sol, Lda",
      nuit: "400238517",
      city: "Maputo",
      status: "pending",
    });
    expect(d.store.users["owner-uid"]).toMatchObject({
      type: "partner_owner",
      partnerId: res.partnerId,
      email: "dono@exemplo.co.mz",
      status: "active",
    });
  });

  test("does not grant /admins to the owner", async () => {
    const d = db(ADMIN);
    await createPartnerWithOwnerCore(d, auth(), "admin-uid", valid);
    expect(d.store.admins["owner-uid"]).toBeUndefined();
  });

  test("omits wallet-settlement fields by default", async () => {
    const d = db(ADMIN);
    const res = await createPartnerWithOwnerCore(d, auth(), "admin-uid", valid);
    expect(d.store.partners[res.partnerId].requiresWalletSettlement).toBeUndefined();
  });

  test("sets requiresWalletSettlement + commissionFloatMtn when requested (YA Direct)", async () => {
    const d = db(ADMIN);
    const res = await createPartnerWithOwnerCore(d, auth(), "admin-uid", {
      ...valid,
      requiresWalletSettlement: true,
      commissionFloatMtn: 400,
    });
    expect(d.store.partners[res.partnerId]).toMatchObject({
      requiresWalletSettlement: true,
      commissionFloatMtn: 400,
    });
  });

  test("defaults commissionFloatMtn to 0 when requiresWalletSettlement is set without it", async () => {
    const d = db(ADMIN);
    const res = await createPartnerWithOwnerCore(d, auth(), "admin-uid", {
      ...valid,
      requiresWalletSettlement: true,
    });
    expect(d.store.partners[res.partnerId].commissionFloatMtn).toBe(0);
  });

  test("rejects negative commissionFloatMtn", async () => {
    await expectHttpsError(
      createPartnerWithOwnerCore(db(ADMIN), auth(), "admin-uid", {
        ...valid,
        commissionFloatMtn: -5,
      }),
      "invalid-argument"
    );
  });
});

// ─────────────────────────────────────────────────────────────
// invitePartnerStaff
// ─────────────────────────────────────────────────────────────

describe("invitePartnerStaffCore", () => {
  const auth = () => ({
    createUser: jest.fn(async () => ({uid: "staff-uid"})),
    generatePasswordResetLink: jest.fn(async () => "https://reset/staff"),
  });

  const OWNER = {
    partners: {p1: {name: "Costa do Sol, Lda"}},
    users: {"owner-uid": {type: "partner_owner", partnerId: "p1"}},
  };

  const valid = {
    partnerId: "p1",
    email: "staff@exemplo.co.mz",
    name: "Staff Exemplo",
  };

  test("rejects a caller who is neither admin nor this partner's owner", async () => {
    await expectHttpsError(
      invitePartnerStaffCore(db(OWNER), auth(), "nobody", valid),
      "permission-denied"
    );
  });

  test("rejects an owner of a DIFFERENT partner", async () => {
    const d = db({
      partners: {p1: {name: "Costa do Sol"}},
      users: {"other-owner": {type: "partner_owner", partnerId: "p2"}},
    });
    await expectHttpsError(
      invitePartnerStaffCore(d, auth(), "other-owner", valid),
      "permission-denied"
    );
  });

  test("rejects an invalid email", async () => {
    await expectHttpsError(
      invitePartnerStaffCore(db(OWNER), auth(), "owner-uid", {
        ...valid,
        email: "not-an-email",
      }),
      "invalid-argument"
    );
  });

  test("rejects an unknown partner", async () => {
    await expectHttpsError(
      invitePartnerStaffCore(db(ADMIN), auth(), "admin-uid", {
        ...valid,
        partnerId: "ghost",
      }),
      "not-found"
    );
  });

  test("admin can invite staff for any partner", async () => {
    const d = db({...ADMIN, partners: {p1: {name: "Costa do Sol"}}});
    const res = await invitePartnerStaffCore(d, auth(), "admin-uid", valid);
    expect(res.uid).toBe("staff-uid");
    expect(res.resetLink).toBe("https://reset/staff");
    expect(d.store.users["staff-uid"]).toMatchObject({
      type: "partner_staff",
      partnerId: "p1",
      email: "staff@exemplo.co.mz",
      status: "active",
    });
    expect(d.store.partners.p1.staff["staff-uid"]).toBe("partner_staff");
  });

  test("the partner's own owner can invite their own staff", async () => {
    const d = db(OWNER);
    const res = await invitePartnerStaffCore(d, auth(), "owner-uid", valid);
    expect(res.uid).toBe("staff-uid");
    expect(d.store.partners.p1.staff["staff-uid"]).toBe("partner_staff");
  });

  test("does not grant /admins to the new staff member", async () => {
    const d = db(OWNER);
    await invitePartnerStaffCore(d, auth(), "owner-uid", valid);
    expect(d.store.admins?.["staff-uid"]).toBeUndefined();
  });
});

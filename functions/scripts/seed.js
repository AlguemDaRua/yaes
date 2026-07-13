/* eslint-disable */
// Demo seed for the Ya Realtime Database — populates a coherent B2B partner-fleet
// dataset that both the mobile app and the backoffice panel can read.
//
// Runs against the LOCAL EMULATOR only (writes via the Admin SDK, which bypasses
// security rules). Never point this at production.
//
//   firebase emulators:start            # in one terminal
//   npm run seed                         # in another
//
// Override the RTDB target with FIREBASE_DATABASE_EMULATOR_HOST / DATABASE_URL.

const admin = require("firebase-admin");

// All data lives in the `ya-app-z-default-rtdb` namespace — the default RTDB
// instance where triggers, rules and the functions' admin.database() all
// attach (same as production). The app and panel point here too under
// USE_EMULATORS. The bare `ya-app-z` namespace is a separate instance that the
// DB triggers never observe, so seeding there leaves onUserCreated et al. dead.
//
// `--panel`: additionally create Firebase Auth accounts so you can log into
// the running panel (admin / partner / support).
const PANEL = process.argv.includes("--panel");

const EMULATOR_HOST =
  process.env.FIREBASE_DATABASE_EMULATOR_HOST || "127.0.0.1:9000";
process.env.FIREBASE_DATABASE_EMULATOR_HOST = EMULATOR_HOST;
if (PANEL) {
  process.env.FIREBASE_AUTH_EMULATOR_HOST =
    process.env.FIREBASE_AUTH_EMULATOR_HOST || "127.0.0.1:9099";
}

const DATABASE_URL =
  process.env.DATABASE_URL ||
  "http://" + EMULATOR_HOST + "/?ns=ya-app-z-default-rtdb";

admin.initializeApp({projectId: "ya-app-z", databaseURL: DATABASE_URL});

const db = admin.database();
const now = new Date().toISOString();
const daysAgo = (n) =>
  new Date(Date.now() - n * 86400000).toISOString();

// ── Identities ───────────────────────────────────────────────
const ADMIN_UID = "demo-admin";
const OWNER_UID = "demo-owner";
const SUPPORT_UID = "demo-support";
const DRIVER_UID = "demo-driver";
const DRIVER2_UID = "demo-driver-2";
const PASSENGER_UID = "demo-passenger";
const PARTNER_ID = "demo-partner";
const VEHICLE_ID = "demo-vehicle";
const VEHICLE2_ID = "demo-vehicle-2";

const data = {
  admins: {[ADMIN_UID]: true},

  users: {
    [ADMIN_UID]: {phone: "+258840000001", type: "admin", name: "Admin Ya", email: "admin@ya.co.mz", createdAt: daysAgo(120)},
    [SUPPORT_UID]: {phone: "+258840000002", type: "support", name: "Suporte Ya", email: "support@ya.co.mz", createdAt: daysAgo(90)},
    [OWNER_UID]: {phone: "+258840000003", type: "partner_owner", partnerId: PARTNER_ID, name: "Carlos Tembe", email: "carlos@maputoexec.co.mz", createdAt: daysAgo(80)},
    [DRIVER_UID]: {phone: "+258841234567", type: "driver", partnerId: PARTNER_ID, vehicleId: VEHICLE_ID, name: "Joao Mucavel", rating: 4.8, ratingCount: 132, tripsCount: 134, totalEarningsMtn: 86400, online: true, createdAt: daysAgo(70)},
    [DRIVER2_UID]: {phone: "+258849999999", type: "driver", partnerId: PARTNER_ID, vehicleId: VEHICLE2_ID, name: "Ana Sitoe", rating: 4.9, ratingCount: 88, tripsCount: 90, totalEarningsMtn: 61200, online: false, createdAt: daysAgo(60)},
    [PASSENGER_UID]: {phone: "+258845555555", type: "passenger", name: "Maria Cossa", email: "maria@example.mz", rating: 4.7, ratingCount: 12, createdAt: daysAgo(40)},
  },

  drivers: {
    [DRIVER_UID]: {online: true, vehicleId: VEHICLE_ID, location: {lat: -25.9665, lng: 32.5832, angle: 45, updatedAt: now}},
    [DRIVER2_UID]: {online: false, vehicleId: VEHICLE2_ID, location: {lat: -25.9218, lng: 32.5734, angle: 120, updatedAt: daysAgo(1)}},
  },

  partners: {
    [PARTNER_ID]: {
      name: "Maputo Executive",
      nuit: "400123456",
      city: "Maputo",
      status: "active",
      email: "geral@maputoexec.co.mz",
      phone: "+258840000003",
      createdAt: daysAgo(80),
      fleet: {id: "fleet-" + PARTNER_ID, name: "Frota Principal"},
      drivers: {[DRIVER_UID]: true, [DRIVER2_UID]: true},
      vehicles: {
        [VEHICLE_ID]: {plate: "AAA-111-MP", model: "Toyota Corolla", type: "Sedan", status: "available", driverId: DRIVER_UID, year: 2021, seats: 4, odometerKm: 84200},
        [VEHICLE2_ID]: {plate: "BBB-222-MP", model: "Hyundai Tucson", type: "SUV", status: "in_trip", driverId: DRIVER2_UID, year: 2022, seats: 5, odometerKm: 51200},
      },
    },
  },

  trips: {
    "demo-trip-1": {
      passenger: PASSENGER_UID, passengerId: PASSENGER_UID, passengerName: "Maria Cossa",
      driver: DRIVER_UID, driverId: DRIVER_UID, partnerId: PARTNER_ID, vehicleId: VEHICLE_ID,
      origin: {name: "Zimpeto", lat: -25.9665, lng: 32.5832},
      destination: {name: "Aeroporto de Maputo", lat: -25.9218, lng: 32.5734},
      status: "completed", tipo: "airport", tripType: "airport", paymentMethod: "mpesa",
      estimatedPrice: 850, amountMtn: 850, partnerNetMtn: 723, distanceKm: 14, durationMinutes: 24,
      createdAt: daysAgo(2), startedAt: daysAgo(2), completedAt: daysAgo(2), updatedAt: daysAgo(2),
      timestamps: {created: daysAgo(2), accepted: daysAgo(2), started: daysAgo(2), completed: daysAgo(2)},
    },
    "demo-trip-2": {
      passenger: PASSENGER_UID, passengerId: PASSENGER_UID, passengerName: "Maria Cossa",
      driver: DRIVER2_UID, driverId: DRIVER2_UID, partnerId: PARTNER_ID, vehicleId: VEHICLE2_ID,
      origin: {name: "Baixa", lat: -25.9700, lng: 32.5730},
      destination: {name: "Costa do Sol", lat: -25.9400, lng: 32.6100},
      status: "started", tipo: "regular", tripType: "regular", paymentMethod: "cash",
      estimatedPrice: 420,
      createdAt: now, startedAt: now, updatedAt: now,
      timestamps: {created: now, accepted: now, started: now},
    },
  },

  alerts: {
    "demo-alert-1": {title: "Documento a expirar", description: "Carta de conducao do motorista Joao expira em 15 dias", severity: "warning", resolved: false, partnerId: PARTNER_ID, driverId: DRIVER_UID, createdAt: daysAgo(1)},
    "demo-alert-2": {title: "Veiculo em manutencao", description: "Hyundai Tucson agendado para revisao", severity: "info", resolved: false, partnerId: PARTNER_ID, vehicleId: VEHICLE2_ID, createdAt: daysAgo(3)},
  },

  tickets: {
    "demo-ticket-1": {subject: "Cobranca indevida", preview: "Fui cobrado duas vezes na viagem ao aeroporto", authorUid: PASSENGER_UID, authorName: "Maria Cossa", authorEmail: "maria@example.mz", authorRole: "passenger", role: "passenger", priority: "high", status: "open", tripId: "demo-trip-1", createdAt: daysAgo(1), lastMessageAt: daysAgo(1),
      messages: {m1: {author: "Maria Cossa", text: "Fui cobrado duas vezes.", createdAt: daysAgo(1), role: "passenger"}}},
  },

  disputes: {
    "demo-trip-1": {tripId: "demo-trip-1", from: "Zimpeto", to: "Aeroporto de Maputo", passengerName: "Maria Cossa", driverName: "Joao Mucavel", rating: 2, comment: "Disputa sobre o valor cobrado", status: "open", amountMtn: 850, createdAt: daysAgo(1)},
  },

  commissions: {
    [PARTNER_ID]: {"demo-comm-1": {rate: 0.12, status: "active", createdAt: daysAgo(80)}},
  },

  payouts: {
    [PARTNER_ID]: {
      "demo-payout-1": {label: "Payout M-Pesa", amountMtn: 45000, method: "mpesa", status: "paid", reference: "MP-2026-001", createdAt: daysAgo(7)},
      "demo-payout-2": {label: "Payout M-Pesa", amountMtn: 38000, method: "mpesa", status: "pending", createdAt: daysAgo(1)},
    },
  },

  incentives: {
    "demo-incentive-1": {title: "100 viagens este mes", target: "100 viagens completas", rewardMtn: 5000, reward: 5000, progress: 0.62, status: "active", endsAt: daysAgo(-10)},
  },

  ratings: {
    "demo-rating-1": {driverId: DRIVER_UID, tripId: "demo-trip-1", value: 5, comment: "Excelente!", createdAt: daysAgo(2)},
  },

  support: {
    leaderboard: {
      [SUPPORT_UID]: {position: 1, name: "Suporte Ya", email: "support@ya.co.mz", resolved: 48, csat: 4.6, averageResponse: "2h 15m", current: true},
    },
  },

  // Espelha a producao (Nampula): passageiro so ve moto + economico.
  // multiplier da moto (0.214) deriva do preco real da gasolina (93.86 MT/L,
  // Jun/2026): ~15 MT bandeirada + ~7.5 MT/km sobre a tarifa regular (150
  // base + 35/km) = 0.214x — ver Downloads/YA-Plano-Fecho.md B2.3.
  config: {
    pricing: {
      categories: {
        moto: {label: "Moto", multiplier: 0.214, seats: 1, order: 0},
        txopela: {label: "Txopela", multiplier: 0.7, seats: 3, order: 1},
        economico: {label: "Económico", multiplier: 1.0, seats: 5, order: 2},
      },
    },
  },
};

const LOGINS = [
  {uid: ADMIN_UID, email: "admin@ya.co.mz", role: "admin"},
  {uid: OWNER_UID, email: "carlos@maputoexec.co.mz", role: "partner"},
  {uid: SUPPORT_UID, email: "support@ya.co.mz", role: "support"},
];
const PASSWORD = "demo1234";

async function createAuthAccounts() {
  for (const a of LOGINS) {
    try {
      await admin.auth().deleteUser(a.uid);
    } catch (_) {}
    await admin.auth().createUser({uid: a.uid, email: a.email, password: PASSWORD, emailVerified: true});
  }
}

async function main() {
  console.log("Seeding RTDB at " + DATABASE_URL);
  await db.ref("/").update(data);

  if (PANEL) {
    await createAuthAccounts();
    console.log("\nLogin accounts (password: " + PASSWORD + "):");
    for (const a of LOGINS) {
      console.log("  " + a.role.padEnd(8) + a.email);
    }
  } else {
    console.log("Done. Demo identities:");
    console.log("  admin   uid=" + ADMIN_UID + "  (admins/" + ADMIN_UID + "=true)");
    console.log("  owner   uid=" + OWNER_UID + "  partner=" + PARTNER_ID);
    console.log("  support uid=" + SUPPORT_UID);
    console.log("  driver  uid=" + DRIVER_UID + "  phone=+258841234567");
    console.log("  pax     uid=" + PASSENGER_UID);
  }
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

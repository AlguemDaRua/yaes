import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import {dispatchWebhooks} from "./webhooks";
import {applyTripWalletSettlementCore} from "./wallet";
import {recordNotification} from "./notify";

const db = admin.database();
const messaging = admin.messaging();

/**
 * Calculates distance between two points in km using Haversine formula.
 */
function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const p = 0.017453292519943295; // Math.PI / 180
  const c = Math.cos;
  const a = 0.5 - c((lat2 - lat1) * p) / 2 +
            c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p)) / 2;
  return 12742 * Math.asin(Math.sqrt(a)); // 2 * R; R = 6371 km
}

/**
 * Helper to get FCM token for a user.
 */
async function getFcmToken(uid: string): Promise<string | null> {
  const snap = await db.ref(`users/${uid}/fcmToken`).get();
  return snap.exists() ? (snap.val() as string) : null;
}

/**
 * Helper to wait for trip acceptance or timeout.
 */
async function waitForAcceptance(tripId: string, seconds: number): Promise<boolean> {
  const checkIntervalMs = 2000;
  const loops = Math.floor((seconds * 1000) / checkIntervalMs);
  
  for (let i = 0; i < loops; i++) {
    await new Promise(resolve => setTimeout(resolve, checkIntervalMs));
    const snap = await db.ref(`trips/${tripId}/status`).get();
    const currentStatus = snap.exists() ? snap.val() : null;
    
    if (currentStatus === "accepted") return true;
    if (currentStatus === "cancelled" || currentStatus === "completed") return false;
  }
  return false;
}

/**
 * Trigger: when a new trip is created (status = pending).
 * Sequential notification based on proximity.
 */
export const onTripCreated = functions.runWith({
  timeoutSeconds: 540, // Max timeout to allow sequential retries
  memory: "256MB",
}).database
  .ref("/trips/{tripId}")
  .onCreate(async (snapshot: admin.database.DataSnapshot, context: functions.EventContext) => {
    const tripId = context.params.tripId;
    const trip = snapshot.val() as Record<string, any>;

    console.log(`[START] Processing new trip: ${tripId}`);
    if (!trip || trip.status !== "pending") {
      console.log(`[EXIT] Trip ${tripId} status is not pending or data is missing.`);
      return;
    }

    // Marks when the trip actually became available to drivers — used to
    // compute acceptance rate / time-to-accept metrics. Cash trips are
    // created already 'pending' so this equals createdAt; digital trips are
    // created 'awaiting_payment' and only reach 'pending' later (see the
    // onTripStatusChanged case below), so offeredAt genuinely lags createdAt.
    if (!trip.offeredAt) {
      await db.ref(`trips/${tripId}/offeredAt`).set(new Date().toISOString());
    }

    // 1. Get pickup coordinates
    const origin = trip.origin as Record<string, any>;
    if (!origin || typeof origin.lat !== "number" || typeof origin.lng !== "number") {
      console.log(`[ERROR] Trip ${tripId} has invalid origin coordinates.`);
      return;
    }

    // 2. Find online drivers
    console.log("[STEP] Fetching online drivers...");
    const driversSnap = await db.ref("drivers").orderByChild("online").equalTo(true).get();
    if (!driversSnap.exists()) {
      console.log("[EXIT] No online drivers found in database.");
      return;
    }

    // 3. Calculate distances and sort
    const potentialDrivers: any[] = [];
    driversSnap.forEach((child) => {
      const driverData = child.val() as Record<string, any>;
      
      // Skip drivers who are busy in an active trip
      if (driverData.busy === true) {
        return;
      }
      
      const location = driverData.location;
      
      if (location && typeof location.lat === "number" && typeof location.lng === "number") {
        const dist = calculateDistance(origin.lat, origin.lng, location.lat, location.lng);
        potentialDrivers.push({
          uid: child.key,
          location: location,
          distance: dist,
        });
      }
    });

    if (potentialDrivers.length === 0) {
      console.log("[EXIT] No drivers with valid locations found.");
      return;
    }

    // Sort by distance ascending
    potentialDrivers.sort((a, b) => a.distance - b.distance);
    console.log(`[INFO] Found ${potentialDrivers.length} nearby drivers. Sorted by proximity.`);

    // 4. Sequential notification loop
    // Notify top 10 closest drivers one by one
    const driversToNotify = potentialDrivers.slice(0, 10);
    const originName = origin.name ?? "Origem";
    const destName = (trip.destination as any)?.name ?? "Destino";

    for (let i = 0; i < driversToNotify.length; i++) {
      const driver = driversToNotify[i];
      
      // Re-verify trip status before notifying next driver
      const currentTripSnap = await db.ref(`trips/${tripId}/status`).get();
      const currentStatus = currentTripSnap.val();
      
      if (currentStatus !== "pending") {
        console.log(`[STOP] Trip ${tripId} is no longer pending (current status: ${currentStatus}). Ending loop.`);
        break;
      }

      console.log(`[PROXIMITY] ${i + 1}/${driversToNotify.length}: Attempting to notify driver ${driver.uid} (Distance: ${driver.distance.toFixed(2)} km)`);

      const token = await getFcmToken(driver.uid);
      if (!token) {
        console.log(`[SKIP] Driver ${driver.uid} has no FCM token.`);
        continue;
      }

      try {
        await messaging.send({
          token: token,
          notification: {
            title: "Nova Viagem Disponível!",
            body: `De: ${originName} → ${destName}`,
          },
          data: {
            type: "new_trip",
            tripId: tripId,
          },
          android: {
            priority: "high",
            notification: { sound: "default", channelId: "trips" },
          },
          apns: {
            payload: { aps: { sound: "default", badge: 1 } },
          },
        });
        await recordNotification(db, driver.uid, {
          title: "Nova Viagem Disponível!",
          body: `De: ${originName} → ${destName}`,
          type: "new_trip",
          tripId,
        });
        console.log(`[SUCCESS] Notification sent to driver ${driver.uid}.`);
      } catch (err) {
        console.error(`[ERROR] Failed to send notification to driver ${driver.uid}:`, err);
        continue;
      }

      // Wait 20 seconds for this driver to accept
      console.log(`[WAIT] Waiting 20 seconds for response from ${driver.uid}...`);
      const isAccepted = await waitForAcceptance(tripId, 20);
      
      if (isAccepted) {
        console.log(`[ACCEPTED] Driver ${driver.uid} accepted the trip ${tripId}.`);
        return;
      } else {
        console.log(`[TIMEOUT] Driver ${driver.uid} did not respond within 20s.`);
      }
    }

    console.log(`[END] Notification sequence finished for trip ${tripId}. No driver accepted.`);
  });

/**
 * Trigger: when the status of a trip changes.
 */
export const onTripStatusChanged = functions.database
  .ref("/trips/{tripId}/status")
  .onUpdate(async (
    change: functions.Change<admin.database.DataSnapshot>,
    context: functions.EventContext,
  ) => {
    const newStatus = change.after.val() as string;
    const oldStatus = change.before.val() as string;

    if (newStatus === oldStatus) return;

    const tripSnap = await db.ref(`trips/${context.params.tripId}`).get();
    if (!tripSnap.exists()) return;
    const trip = tripSnap.val() as Record<string, unknown>;

    console.log(`[STATUS] Trip ${context.params.tripId} changed from ${oldStatus} to ${newStatus}`);

    await dispatchWebhooks(db, "trip.status", {
      tripId: context.params.tripId as string,
      status: newStatus,
      previousStatus: oldStatus,
    });

    const passengerUid = trip.passenger as string | undefined;
    const driverUid = trip.driver as string | undefined;
    const passengerToken = passengerUid ? await getFcmToken(passengerUid) : null;
    const driverToken = driverUid ? await getFcmToken(driverUid) : null;

    const sendTo = async (
      uid: string | undefined,
      token: string | null,
      title: string,
      body: string,
      type: string,
    ) => {
      if (token) {
        try {
          await messaging.send({
            token,
            notification: { title, body },
            data: { type, tripId: context.params.tripId as string },
            android: { priority: "high", notification: { sound: "default", channelId: "trips" } },
            apns: { payload: { aps: { sound: "default" } } },
          });
        } catch (err) {
          console.error("[ERROR] Failed to send status notification:", err);
        }
      }
      if (uid) {
        await recordNotification(db, uid, { title, body, type, tripId: context.params.tripId as string });
      }
    };

    switch (newStatus) {
    case "pending":
      // Digital trips are created 'awaiting_payment' and only become
      // offerable once payment confirms — onTripCreated (status already
      // 'pending' at creation) never fires for them, so offeredAt is set here.
      if (!trip.offeredAt) {
        await db.ref(`trips/${context.params.tripId}/offeredAt`).set(new Date().toISOString());
      }
      break;
    case "accepted":
      await db.ref(`trips/${context.params.tripId}/acceptedAt`).set(new Date().toISOString());
      await sendTo(passengerUid, passengerToken, "Motorista a caminho!", "O seu motorista aceitou a viagem.", "trip_accepted");
      if (trip.driver) await db.ref(`drivers/${trip.driver}`).update({ busy: true });
      break;
    case "started":
      await sendTo(passengerUid, passengerToken, "Viagem iniciada", "Sua viagem começou. Tenha uma boa viagem!", "trip_started");
      break;
    case "completed":
      await sendTo(passengerUid, passengerToken, "Viagem concluída", "Você chegou ao destino. Obrigado por usar a Ya!", "trip_completed");
      await sendTo(driverUid, driverToken, "Viagem concluída", "Viagem concluída com sucesso.", "trip_completed");
      if (trip.driver) await db.ref(`drivers/${trip.driver}`).update({ busy: false });
      try {
        await applyTripWalletSettlementCore(db, context.params.tripId as string);
      } catch (err) {
        console.error("[ERROR] Failed to apply wallet settlement:", err);
      }
      break;
    case "cancelled":
      if (oldStatus === "pending" || oldStatus === "accepted") {
        await sendTo(driverUid, driverToken, "Viagem cancelada", "O passageiro cancelou a viagem.", "trip_cancelled");
        await sendTo(passengerUid, passengerToken, "Viagem cancelada", "Sua viagem foi cancelada.", "trip_cancelled");
      }
      if (trip.driver) await db.ref(`drivers/${trip.driver}`).update({ busy: false });
      break;
    }
  });

export const onNewChatMessage = functions.database
  .ref("chats/{tripId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const message = snapshot.val();
    const { tripId } = context.params;

    // Fetch trip to find recipient
    const tripSnap = await admin.database().ref(`trips/${tripId}`).once("value");
    const trip = tripSnap.val();
    if (!trip) return null;

    const recipientUid = message.senderType === "driver" ?
      trip.passenger :
      trip.driver;

    if (!recipientUid) return null;

    const senderTitle = message.senderType === "driver" ? "Motorista" : "Passageiro";
    await recordNotification(db, recipientUid, {
      title: senderTitle,
      body: message.text,
      type: "chat_message",
      tripId,
    });

    // Fetch recipient's FCM token
    const userSnap = await admin.database().ref(`users/${recipientUid}/fcmToken`).once("value");
    const fcmToken = userSnap.val();
    if (!fcmToken) return null;

    const payload: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title: senderTitle,
        body: message.text,
      },
      data: {
        tripId: tripId,
        type: "chat_message",
      },
    };

    return admin.messaging().send(payload);
  });

/**
 * Trigger: when a new schedule is created.
 */
export const onScheduleCreated = functions.database
  .ref("/schedules/{uid}/{scheduleId}")
  .onCreate(async (snapshot, context) => {
    const uid = context.params.uid;
    const schedule = snapshot.val();

    const time = new Date(schedule.time).toLocaleTimeString("pt-BR", {
      hour: "2-digit",
      minute: "2-digit",
    });
    const title = "Viagem Agendada!";
    const body = `Sua viagem para às ${time} foi agendada com sucesso.`;

    await recordNotification(db, uid, { title, body, type: "schedule_created" });

    const token = await getFcmToken(uid);
    if (!token) return;
    try {
      await messaging.send({
        token,
        notification: { title, body },
        data: {
          type: "schedule_created",
          scheduleId: context.params.scheduleId,
        },
      });
      console.log(`[SCHEDULE] Notification sent to ${uid} for new schedule.`);
    } catch (err) {
      console.error("[ERROR] Failed to send schedule notification:", err);
    }
  });

/**
 * Trigger: when a schedule time is updated.
 */
export const onScheduleTimeChanged = functions.database
  .ref("/schedules/{uid}/{scheduleId}/time")
  .onUpdate(async (change, context) => {
    const uid = context.params.uid;
    const newTimeStr = change.after.val();

    const time = new Date(newTimeStr).toLocaleTimeString("pt-BR", {
      hour: "2-digit",
      minute: "2-digit",
    });
    const title = "Horário de Agenda Alterado";
    const body = `O horário da sua viagem foi atualizado para às ${time}.`;

    await recordNotification(db, uid, { title, body, type: "schedule_time_changed" });

    const token = await getFcmToken(uid);
    if (!token) return;
    try {
      await messaging.send({
        token,
        notification: { title, body },
        data: {
          type: "schedule_time_changed",
          scheduleId: context.params.scheduleId,
        },
      });
      console.log(`[SCHEDULE] Notification sent to ${uid} for time change.`);
    } catch (err) {
      console.error("[ERROR] Failed to send schedule update notification:", err);
    }
  });


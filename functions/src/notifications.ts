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

/** Driver categories are mirrored to /drivers/{uid} by onVehicleChanged. */
function vehicleSupportsCategory(
  driver: Record<string, any>,
  category: string,
): boolean {
  const categories = driver.categories;
  if (Array.isArray(categories) && categories.includes(category)) return true;
  if (categories && typeof categories === "object" && categories[category] === true) {
    return true;
  }
  return driver.category === category;
}

/**
 * Helper to get FCM token for a user.
 */
async function getFcmToken(uid: string): Promise<string | null> {
  const snap = await db.ref(`users/${uid}/fcmToken`).get();
  return snap.exists() ? (snap.val() as string) : null;
}

async function markNoDriverAvailable(
  tripId: string,
  passengerUid: string,
): Promise<void> {
  const statusRef = db.ref(`trips/${tripId}/status`);
  let observedStatus: unknown;
  const result = await statusRef.transaction((status) => {
    if (status === null) {
      // RTDB may call the updater with null before it has loaded the server
      // value. Returning null lets the transaction reconcile and retry with
      // the current server value instead of aborting this first attempt.
      observedStatus = "null local; a aguardar reconciliação do servidor";
      return null;
    }
    observedStatus = status;
    return status === "pending" ? "no_driver_available" : undefined;
  });
  const finalStatus = result.snapshot.val();
  if (!result.committed || finalStatus !== "no_driver_available") {
    console.log(`[onTripCreated][${tripId}][FINAL] Estado não alterado para no_driver_available; estado observado=${observedStatus ?? "ausente"}; estado final=${finalStatus ?? "ausente"}.`);
    return;
  }
  console.log(`[onTripCreated][${tripId}][FINAL] Nenhum motorista aceitou. Estado alterado para no_driver_available.`);

  const payload = {
    title: "Nenhum motorista disponível",
    body: "Não encontrámos um motorista livre nesta categoria. Tenta novamente ou escolhe outra.",
    type: "no_driver_available",
    tripId,
  };
  try {
    const token = await getFcmToken(passengerUid);
    if (token) {
      await messaging.send({
        token,
        notification: {title: payload.title, body: payload.body},
        data: {type: payload.type, tripId},
      });
    }
  } catch (err) {
    console.error(
      `[ERROR] Failed to notify passenger that trip ${tripId} has no matching driver:`,
      err,
    );
  }
  await recordNotification(db, passengerUid, payload);
}

async function setOfferedDriver(tripId: string, driverUid: string): Promise<boolean> {
  let abortReason = "desconhecido";
  let observedStatus: unknown;
  let driverAlreadyAssigned = false;
  const result = await db.ref(`trips/${tripId}`).transaction((trip) => {
    if (trip === null) {
      // A null first call can mean the trip is not locally cached yet.
      // Returning null lets RTDB retry the updater with its server value.
      abortReason = "dado local nulo; a aguardar reconciliação do servidor";
      return null;
    }
    observedStatus = trip?.status;
    driverAlreadyAssigned = Boolean(trip?.driver);
    if (trip.status !== "pending") {
      abortReason = "estado deixou de ser pending";
      return undefined;
    }
    if (trip.driver) {
      abortReason = "já existe um motorista atribuído";
      return undefined;
    }
    if (trip.offeredTo && trip.offeredTo !== driverUid) {
      abortReason = `oferta já atribuída a outro motorista (${trip.offeredTo})`;
      return undefined;
    }
    abortReason = "nenhum; transação pronta para gravar offeredTo";
    return {...trip, offeredTo: driverUid};
  });
  const finalTrip = result.snapshot.val() as Record<string, any> | null;
  const offerWasWritten = result.committed &&
    finalTrip?.status === "pending" &&
    finalTrip.offeredTo === driverUid;
  if (!offerWasWritten) {
    console.log(`[onTripCreated][${tripId}][OFERTA NÃO GRAVADA] Motorista=${driverUid}; motivo=${abortReason}; estado observado=${observedStatus ?? "ausente"}; driver já atribuído=${driverAlreadyAssigned}; estado final=${finalTrip?.status ?? "ausente"}; offeredTo final=${finalTrip?.offeredTo ?? "ausente"}.`);
  }
  return offerWasWritten;
}

async function clearOfferedDriver(tripId: string, driverUid: string): Promise<void> {
  await db.ref(`trips/${tripId}`).transaction((trip) => {
    if (trip === null) return null;
    if (!trip || trip.status !== "pending" || trip.offeredTo !== driverUid) {
      return undefined;
    }
    return {...trip, offeredTo: null};
  });
}

/**
 * Helper to wait for trip acceptance or timeout.
 */
async function waitForAcceptance(
  tripId: string,
  seconds: number,
): Promise<boolean> {
  const checkIntervalMs = 2000;
  const loops = Math.floor((seconds * 1000) / checkIntervalMs);
  
  for (let i = 0; i < loops; i++) {
    await new Promise((resolve) => setTimeout(resolve, checkIntervalMs));
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
  .onWrite(async (
    change: functions.Change<admin.database.DataSnapshot>,
    context: functions.EventContext,
  ) => {
    const snapshot = change.after;
    const tripId = context.params.tripId;
    const trip = snapshot.val() as Record<string, any>;

    // Dispatch when the trip first becomes offerable. This covers cash trips
    // created as pending and digital trips that become pending after payment.
    const previousStatus = change.before.child("status").val();
    const currentStatus = change.after.child("status").val();
    console.log(`[onTripCreated][${tripId}][TRIGGER] Alteração recebida. Estado anterior=${previousStatus ?? "ausente"}; estado atual=${currentStatus ?? "ausente"}.`);

    if (previousStatus === "pending") {
      console.log(`[onTripCreated][${tripId}][IGNORADO] A viagem já estava pending antes desta alteração; não é uma nova oferta.`);
      return;
    }
    if (!trip || trip.status !== "pending") {
      console.log(`[onTripCreated][${tripId}][IGNORADO] A viagem não está pronta para despacho: status=${trip?.status ?? "sem dados"}. Esperado: pending.`);
      return;
    }
    console.log(`[onTripCreated][${tripId}][INÍCIO] Viagem elegível para despacho. Categoria=${trip.carCategory ?? "economico (padrão)"}; passageiro=${trip.passenger ?? "ausente"}.`);

    // Marks when the trip actually became available to drivers — used to
    // compute acceptance rate / time-to-accept metrics. Cash trips are
    // created already 'pending' so this equals createdAt; digital trips are
    // created 'awaiting_payment' and only reach 'pending' later (see the
    // onTripStatusChanged case below), so offeredAt genuinely lags createdAt.
    if (!trip.offeredAt) {
      await db.ref(`trips/${tripId}/offeredAt`).set(new Date().toISOString());
      console.log(`[onTripCreated][${tripId}][REGISTO] offeredAt gravado.`);
    }

    // 1. Get pickup coordinates
    const origin = trip.origin as Record<string, any>;
    const requestedCategory = typeof trip.carCategory === "string" ? trip.carCategory : "economico";
    if (!origin || typeof origin.lat !== "number" || typeof origin.lng !== "number") {
      console.error(`[onTripCreated][${tripId}][ERRO] Origem inválida. São necessárias coordenadas numéricas lat/lng.`);
      return;
    }
    console.log(`[onTripCreated][${tripId}][ORIGEM] Coordenadas válidas.`);

    // 2. Find online drivers
    console.log(`[onTripCreated][${tripId}][BUSCA] A procurar motoristas com online=true.`);
    const driversSnap = await db.ref("drivers").orderByChild("online").equalTo(true).get();
    if (!driversSnap.exists()) {
      console.log(`[onTripCreated][${tripId}][SEM CANDIDATOS] Não há motoristas online em /drivers.`);
      if (typeof trip.passenger === "string") {
        await markNoDriverAvailable(tripId, trip.passenger);
      }
      return;
    }

    // 3. Calculate distances and sort
    const onlineDrivers: Array<{
      uid: string;
      location: Record<string, any>;
    }> = [];
    let skippedBusy = 0;
    let skippedCategory = 0;
    let skippedLocation = 0;
    driversSnap.forEach((child) => {
      const driverData = child.val() as Record<string, any>;
      
      // Skip drivers who are busy in an active trip
      if (driverData.busy === true) {
        skippedBusy++;
        return;
      }

      if (!vehicleSupportsCategory(driverData, requestedCategory)) {
        skippedCategory++;
        return;
      }
      
      const location = driverData.location;
      
      if (
        child.key &&
        location &&
        typeof location.lat === "number" &&
        typeof location.lng === "number"
      ) {
        onlineDrivers.push({
          uid: child.key,
          location: location,
        });
      } else {
        skippedLocation++;
      }
    });
    console.log(`[onTripCreated][${tripId}][FILTRO] Online analisados=${driversSnap.numChildren()}; ocupados=${skippedBusy}; categoria incompatível=${skippedCategory}; localização inválida/ausente=${skippedLocation}; compatíveis=${onlineDrivers.length}.`);

    const potentialDrivers = onlineDrivers.map((driver) => ({
      ...driver,
      distance: calculateDistance(
        origin.lat,
        origin.lng,
        driver.location.lat,
        driver.location.lng,
      ),
    }));

    if (potentialDrivers.length === 0) {
      console.log(`[onTripCreated][${tripId}][SEM CANDIDATOS] Nenhum motorista online, livre, compatível com ${requestedCategory} e com localização válida.`);
      if (typeof trip.passenger === "string") {
        await markNoDriverAvailable(tripId, trip.passenger);
      }
      return;
    }

    // Sort by distance ascending
    potentialDrivers.sort((a, b) => a.distance - b.distance);
    console.log(`[onTripCreated][${tripId}][PROXIMIDADE] ${potentialDrivers.length} candidatos ordenados por distância. Mais próximo=${potentialDrivers[0].uid} (${potentialDrivers[0].distance.toFixed(2)} km).`);

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
        console.log(`[onTripCreated][${tripId}][PARAGEM] Estado mudou para ${currentStatus ?? "ausente"} antes da próxima oferta.`);
        break;
      }

      console.log(`[onTripCreated][${tripId}][MOTORISTA ${i + 1}/${driversToNotify.length}] A verificar ${driver.uid}; distância=${driver.distance.toFixed(2)} km.`);

      const token = await getFcmToken(driver.uid);
      if (!token) {
        console.log(`[onTripCreated][${tripId}][TOKEN AUSENTE] Motorista ${driver.uid} não tem /users/${driver.uid}/fcmToken; será ignorado.`);
        continue;
      }
      console.log(`[onTripCreated][${tripId}][TOKEN OK] Token FCM encontrado para ${driver.uid} (valor ocultado).`);

      if (!(await setOfferedDriver(tripId, driver.uid))) {
        console.log(`[onTripCreated][${tripId}][PARAGEM] Não foi possível gravar offeredTo=${driver.uid}; a viagem deixou de estar disponível.`);
        break;
      }
      console.log(`[onTripCreated][${tripId}][OFERTA ATRIBUÍDA] offeredTo=${driver.uid}. A enviar FCM.`);

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
      } catch (err) {
        console.error(`[onTripCreated][${tripId}][ERRO FCM] Falha ao enviar para ${driver.uid}:`, err);
        await clearOfferedDriver(tripId, driver.uid);
        console.log(`[onTripCreated][${tripId}][OFERTA LIMPA] offeredTo removido após falha FCM; será tentado o próximo motorista.`);
        continue;
      }
      try {
        await recordNotification(db, driver.uid, {
          title: "Nova Viagem Disponível!",
          body: `De: ${originName} → ${destName}`,
          type: "new_trip",
          tripId,
        });
      } catch (err) {
        console.error(`[onTripCreated][${tripId}][ERRO HISTÓRICO] FCM enviado, mas não foi possível guardar a notificação de ${driver.uid}:`, err);
      }
      console.log(`[onTripCreated][${tripId}][FCM ENVIADO] Oferta enviada ao FCM para ${driver.uid}. Isto confirma aceitação pelo FCM, não reprodução no telefone.`);

      // Wait 20 seconds for this driver to accept
      console.log(`[onTripCreated][${tripId}][AGUARDA ACEITAÇÃO] A aguardar até 20 segundos pela resposta de ${driver.uid}.`);
      const isAccepted = await waitForAcceptance(tripId, 20);
      
      if (isAccepted) {
        console.log(`[onTripCreated][${tripId}][ACEITE] Motorista ${driver.uid} aceitou a viagem.`);
        return;
      } else {
        const statusAfterWait = (await db.ref(`trips/${tripId}/status`).get()).val();
        console.log(`[onTripCreated][${tripId}][SEM RESPOSTA] ${driver.uid} não aceitou em 20 segundos; estado atual=${statusAfterWait ?? "ausente"}.`);
        await clearOfferedDriver(tripId, driver.uid);
        console.log(`[onTripCreated][${tripId}][OFERTA EXPIRADA] offeredTo limpo para ${driver.uid}; será tentado o próximo candidato.`);
      }
    }

    console.log(`[onTripCreated][${tripId}][FIM] Terminaram as tentativas para os candidatos disponíveis sem aceitação.`);
    if (typeof trip.passenger === "string") {
      await markNoDriverAvailable(tripId, trip.passenger);
    }
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
      if (oldStatus === "pending" || oldStatus === "accepted" || oldStatus === "started") {
        if (trip.cancelledBy === "driver") {
          await sendTo(passengerUid, passengerToken, "Viagem cancelada", "O motorista cancelou a viagem. Pode solicitar outro veículo.", "trip_cancelled");
        } else if (trip.cancelledBy === "passenger") {
          await sendTo(driverUid, driverToken, "Viagem cancelada", "O passageiro cancelou a viagem.", "trip_cancelled");
        } else {
          await sendTo(driverUid, driverToken, "Viagem cancelada", "Esta viagem foi cancelada.", "trip_cancelled");
          await sendTo(passengerUid, passengerToken, "Viagem cancelada", "A viagem foi cancelada. Pode solicitar outro veículo.", "trip_cancelled");
        }
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


import * as admin from "firebase-admin";

admin.initializeApp();

export {calculatePrice} from "./pricing";
export {
  onTripCreated,
  onTripStatusChanged,
  onNewChatMessage,
  onScheduleCreated,
  onScheduleTimeChanged,
} from "./notifications";
export {setUserType} from "./drivers";
export {
  setUserRole,
  createPartner,
  approvePartner,
  suspendPartner,
  processPayout,
  inviteDriver,
  assignVehicle,
  onUserCreated,
  setCommission,
  reviewDocument,
  setUserStatus,
  inviteManager,
  createPartnerWithOwner,
  invitePartnerStaff,
  revokeUserSessions,
} from "./painel";
export {
  assignTicket,
  replyTicket,
  closeTicket,
  resolveDispute,
  createTicket,
} from "./support";
export {initiatePayment, paymentCallback} from "./payments";
export {onVehicleChanged} from "./vehicles";
export {submitRating} from "./ratings";
export {
  initiateWalletTopup,
  walletTopupCallback,
  adjustDriverWallet,
} from "./wallet";
export {sendBroadcast} from "./broadcast";

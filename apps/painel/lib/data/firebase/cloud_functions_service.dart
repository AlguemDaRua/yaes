import 'package:cloud_functions/cloud_functions.dart';

/// Wrapper das callable Cloud Functions usadas pelo painel.
/// As funções estão definidas em `ya-app/functions/src/painel.ts` e são
/// expostas via `firebase deploy --only functions`.
///
/// Todas as funções (excepto triggers automáticos) requerem que o caller
/// seja admin (`/admins/{uid}: true`).
class CloudFunctionsService {
  CloudFunctionsService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Promove um user para um determinado role. Admin only.
  /// Roles que requerem `partnerId`: `driver`, `partner_owner`,
  /// `partner_staff`.
  Future<void> setUserRole({
    required String uid,
    required String role,
    String? partnerId,
  }) async {
    await _functions.httpsCallable('setUserRole').call<dynamic>({
      'uid': uid,
      'role': role,
      if (partnerId != null) 'partnerId': partnerId,
    });
  }

  /// Cria um novo partner e promove o `ownerUid` para `partner_owner`.
  /// O user com `ownerUid` deve já existir (ter feito login OTP antes).
  Future<String> createPartner({
    required String name,
    required String nuit,
    required String city,
    required String ownerUid,
    String? email,
    String? phone,
  }) async {
    final HttpsCallableResult<dynamic> result =
        await _functions.httpsCallable('createPartner').call<dynamic>({
      'name': name,
      'nuit': nuit,
      'city': city,
      'ownerUid': ownerUid,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    });
    final Map<dynamic, dynamic> data =
        Map<dynamic, dynamic>.from(result.data as Map);
    return data['partnerId'] as String;
  }

  /// Cria um partner E a conta de login do dono (email/password) numa só
  /// operação. Devolve partnerId, ownerUid e um link de reset para o dono
  /// definir a password e entrar no painel. Admin only.
  Future<({String partnerId, String ownerUid, String resetLink})>
      createPartnerWithOwner({
    required String name,
    required String nuit,
    required String city,
    required String ownerEmail,
    String? ownerName,
    String? email,
    String? phone,
    bool requiresWalletSettlement = false,
    int? commissionFloatMtn,
  }) async {
    final HttpsCallableResult<dynamic> result =
        await _functions.httpsCallable('createPartnerWithOwner').call<dynamic>({
      'name': name,
      'nuit': nuit,
      'city': city,
      'ownerEmail': ownerEmail,
      if (ownerName != null) 'ownerName': ownerName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (requiresWalletSettlement) ...{
        'requiresWalletSettlement': true,
        'commissionFloatMtn': commissionFloatMtn ?? 0,
      },
    });
    final Map<dynamic, dynamic> data =
        Map<dynamic, dynamic>.from(result.data as Map);
    return (
      partnerId: data['partnerId'] as String,
      ownerUid: data['ownerUid'] as String,
      resetLink: data['resetLink'] as String,
    );
  }

  /// Cria uma conta de login (email/password) para um membro da equipa de um
  /// partner (`partner_staff`). Admin ou o partner_owner do próprio partner.
  /// Devolve o uid e um link de reset para partilhar manualmente.
  Future<({String uid, String resetLink})> invitePartnerStaff({
    required String partnerId,
    required String email,
    String? name,
    String? phone,
  }) async {
    final HttpsCallableResult<dynamic> result =
        await _functions.httpsCallable('invitePartnerStaff').call<dynamic>({
      'partnerId': partnerId,
      'email': email,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
    });
    final Map<dynamic, dynamic> data =
        Map<dynamic, dynamic>.from(result.data as Map);
    return (
      uid: data['uid'] as String,
      resetLink: data['resetLink'] as String,
    );
  }

  /// Marca partner como `active`. Admin only.
  Future<void> approvePartner(String partnerId) async {
    await _functions.httpsCallable('approvePartner').call<dynamic>({
      'partnerId': partnerId,
    });
  }

  /// Marca partner como `suspended`. Admin only.
  Future<void> suspendPartner({
    required String partnerId,
    String? reason,
  }) async {
    await _functions.httpsCallable('suspendPartner').call<dynamic>({
      'partnerId': partnerId,
      if (reason != null) 'reason': reason,
    });
  }

  /// Convida um motorista por telefone. Admin ou o partner_owner do próprio
  /// partner. Se o telefone já existir como user, vincula-o de imediato;
  /// caso contrário cria um convite pendente aplicado no primeiro login.
  /// Devolve `'linked'` ou `'invited'`.
  Future<String> inviteDriver({
    required String partnerId,
    required String phone,
    String? name,
    String? vehicleId,
  }) async {
    final HttpsCallableResult<dynamic> result =
        await _functions.httpsCallable('inviteDriver').call<dynamic>({
      'partnerId': partnerId,
      'phone': phone,
      if (name != null) 'name': name,
      if (vehicleId != null) 'vehicleId': vehicleId,
    });
    final Map<dynamic, dynamic> data =
        Map<dynamic, dynamic>.from(result.data as Map);
    return data['status'] as String;
  }

  /// Liga (ou desliga) um motorista a um veículo. Admin ou partner_owner do
  /// partner. `driverUid` a `null` desfaz a atribuição.
  Future<void> assignVehicle({
    required String partnerId,
    required String vehicleId,
    String? driverUid,
  }) async {
    await _functions.httpsCallable('assignVehicle').call<dynamic>({
      'partnerId': partnerId,
      'vehicleId': vehicleId,
      'driverUid': driverUid,
    });
  }

  /// Regista um payout (M-Pesa ou banco) para o partner. Admin only.
  Future<String> processPayout({
    required String partnerId,
    required int amountMtn,
    required String method, // 'mpesa' | 'bank'
    String? reference,
  }) async {
    final HttpsCallableResult<dynamic> result =
        await _functions.httpsCallable('processPayout').call<dynamic>({
      'partnerId': partnerId,
      'amountMtn': amountMtn,
      'method': method,
      if (reference != null) 'reference': reference,
    });
    final Map<dynamic, dynamic> data =
        Map<dynamic, dynamic>.from(result.data as Map);
    return data['payoutId'] as String;
  }

  /// Define a comissão de um partner (`rate` é fração, ex. 0.12). Admin only.
  Future<void> setCommission({
    required String partnerId,
    required double rate,
    String? label,
  }) async {
    await _functions.httpsCallable('setCommission').call<dynamic>({
      'partnerId': partnerId,
      'rate': rate,
      if (label != null) 'label': label,
    });
  }

  /// Aprova/rejeita um documento submetido. Admin only.
  Future<void> reviewDocument({
    required String ownerType,
    required String ownerId,
    required String docId,
    required String status, // 'approved' | 'rejected' | 'pending'
    String? reason,
  }) async {
    await _functions.httpsCallable('reviewDocument').call<dynamic>({
      'ownerType': ownerType,
      'ownerId': ownerId,
      'docId': docId,
      'status': status,
      if (reason != null) 'reason': reason,
    });
  }

  /// Suspende/reativa um utilizador (`status`: 'active' | 'suspended'). Admin only.
  Future<void> setUserStatus({
    required String uid,
    required String status,
    String? reason,
  }) async {
    await _functions.httpsCallable('setUserStatus').call<dynamic>({
      'uid': uid,
      'status': status,
      if (reason != null) 'reason': reason,
    });
  }

  /// Cria uma conta de gestor (admin|support) com email verificado e devolve
  /// o uid e um link de reset de password para partilhar manualmente.
  /// Admin only.
  Future<({String uid, String resetLink})> inviteManager({
    required String email,
    required String role, // 'admin' | 'support'
    String? name,
  }) async {
    final HttpsCallableResult<dynamic> result =
        await _functions.httpsCallable('inviteManager').call<dynamic>({
      'email': email,
      'role': role,
      if (name != null) 'name': name,
    });
    final Map<dynamic, dynamic> data =
        Map<dynamic, dynamic>.from(result.data as Map);
    return (
      uid: data['uid'] as String,
      resetLink: data['resetLink'] as String,
    );
  }

  /// Invalida os refresh tokens de um utilizador (força novo login em todos
  /// os dispositivos). Admin only.
  Future<void> revokeUserSessions(String uid) async {
    await _functions.httpsCallable('revokeUserSessions').call<dynamic>({
      'uid': uid,
    });
  }

  /// Envia um push broadcast via FCM topic
  /// (`audience`: 'all' | 'drivers' | 'passengers'). Admin only.
  Future<String> sendBroadcast({
    required String title,
    required String body,
    required String audience,
  }) async {
    final HttpsCallableResult<dynamic> result =
        await _functions.httpsCallable('sendBroadcast').call<dynamic>({
      'title': title,
      'body': body,
      'audience': audience,
    });
    final Map<dynamic, dynamic> data =
        Map<dynamic, dynamic>.from(result.data as Map);
    return data['broadcastId'] as String;
  }

  /// Ajusta manualmente o saldo da carteira de comissão de um motorista
  /// (crédito ou débito). Definido em `wallet.ts`. Admin only.
  Future<int> adjustDriverWallet({
    required String partnerId,
    required String driverId,
    required int amountMtn,
    String? note,
  }) async {
    final HttpsCallableResult<dynamic> result =
        await _functions.httpsCallable('adjustDriverWallet').call<dynamic>({
      'partnerId': partnerId,
      'driverId': driverId,
      'amountMtn': amountMtn,
      if (note != null) 'note': note,
    });
    final Map<dynamic, dynamic> data =
        Map<dynamic, dynamic>.from(result.data as Map);
    return (data['balance'] as num).toInt();
  }

  // ─── Support ───────────────────────────────────────────────────────────────

  /// Atribui um ticket a um agente. Admin ou support.
  Future<void> assignTicket({
    required String ticketId,
    required String agentUid,
  }) async {
    await _functions.httpsCallable('assignTicket').call<dynamic>({
      'ticketId': ticketId,
      'agentUid': agentUid,
    });
  }

  /// Responde a um ticket (anexa mensagem). Admin ou support.
  Future<void> replyTicket({
    required String ticketId,
    required String text,
    String? authorName,
  }) async {
    await _functions.httpsCallable('replyTicket').call<dynamic>({
      'ticketId': ticketId,
      'text': text,
      if (authorName != null) 'authorName': authorName,
    });
  }

  /// Fecha (resolve) um ticket. Admin ou support.
  Future<void> closeTicket(String ticketId) async {
    await _functions.httpsCallable('closeTicket').call<dynamic>({
      'ticketId': ticketId,
    });
  }

  /// Resolve uma disputa de uma viagem. Admin ou support.
  Future<void> resolveDispute({
    required String tripId,
    required String resolution,
    String? status, // 'resolved' | 'rejected'
  }) async {
    await _functions.httpsCallable('resolveDispute').call<dynamic>({
      'tripId': tripId,
      'resolution': resolution,
      if (status != null) 'status': status,
    });
  }

  /// Cria um novo ticket de suporte. Admin ou support. Devolve o id.
  Future<String> createTicket({
    required String subject,
    String? priority,
    String? authorUid,
    String? authorName,
    String? tripId,
    String? text,
  }) async {
    final HttpsCallableResult<dynamic> result =
        await _functions.httpsCallable('createTicket').call<dynamic>({
      'subject': subject,
      if (priority != null) 'priority': priority,
      if (authorUid != null) 'authorUid': authorUid,
      if (authorName != null) 'authorName': authorName,
      if (tripId != null) 'tripId': tripId,
      if (text != null) 'text': text,
    });
    final Map<dynamic, dynamic> data =
        Map<dynamic, dynamic>.from(result.data as Map);
    return data['ticketId'] as String;
  }
}

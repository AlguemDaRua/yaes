import 'mock_types.dart';

abstract class MockSupport {
  static const String agentName = 'Antonio Massango';
  static const String agentEmail = 'antonio.support@ya.co.mz';
  static final DateTime referenceNow = DateTime(2026, 5, 5, 15, 10);

  static final List<SupportTicket> tickets = <SupportTicket>[
    SupportTicket(
      id: 'TKT-2891',
      subject: 'Cobranca duplicada em corrida de 1 800 MTn',
      preview: 'Apareceu 1 800 MTn no extrato e mais 1 800 MTn separadamente.',
      authorName: 'A. Macuvele',
      authorEmail: 'amacuvele@driver.ya.mz',
      authorPhone: '+258 84 332 8910',
      role: SupportActorRole.driver,
      priority: SupportTicketPriority.urgent,
      status: SupportTicketStatus.open,
      createdAt: referenceNow.subtract(const Duration(minutes: 5)),
      lastMessageAt: referenceNow.subtract(const Duration(minutes: 5)),
      tripId: 'TRP-2832X',
      amount: 1800,
      internalNotes: 'Confirmar dupla captura no gateway antes do reembolso.',
      messages: <SupportMessage>[
        SupportMessage(
          author: 'A. Macuvele',
          role: SupportActorRole.driver,
          createdAt: referenceNow.subtract(const Duration(minutes: 38)),
          text:
              'Ola, fui cobrado duas vezes na corrida TRP-2832X. Apareceu 1 800 MTn no extrato e mais 1 800 MTn separadamente.',
        ),
        SupportMessage(
          author: 'A. Macuvele',
          role: SupportActorRole.driver,
          createdAt: referenceNow.subtract(const Duration(minutes: 35)),
          text: 'Segue o comprovativo do extrato.',
          attachmentLabel: 'extrato-bim.png',
        ),
        SupportMessage(
          author: agentName,
          role: SupportActorRole.agent,
          agent: true,
          createdAt: referenceNow.subtract(const Duration(minutes: 34)),
          text:
              'Obrigado pelo report. Estou a investigar agora. Aguarda 5 minutos.',
        ),
      ],
    ),
    _ticket(
      id: 'TKT-2890',
      subject: 'Driver nao apareceu, preciso reembolso',
      preview: 'Esperei no ponto de recolha por 18 minutos.',
      authorName: 'Helena Nhaca',
      role: SupportActorRole.passenger,
      priority: SupportTicketPriority.high,
      status: SupportTicketStatus.open,
      minutesAgo: 12,
      tripId: 'TRP-2831F',
    ),
    _ticket(
      id: 'TKT-2889',
      subject: 'App mostra estatisticas erradas para minha frota',
      preview: 'A pagina de performance nao bate com os valores exportados.',
      authorName: 'MZ Fleet Lda',
      role: SupportActorRole.partner,
      priority: SupportTicketPriority.high,
      status: SupportTicketStatus.inProgress,
      minutesAgo: 23,
      assignee: 'Maria Silva',
    ),
    _ticket(
      id: 'TKT-2888',
      subject: 'Como mudo metodo de pagamento padrao?',
      preview: 'Quero trocar de carteira movel para cartao.',
      authorName: 'Celso Mabunda',
      role: SupportActorRole.passenger,
      priority: SupportTicketPriority.medium,
      status: SupportTicketStatus.open,
      minutesAgo: 41,
    ),
    _ticket(
      id: 'TKT-2887',
      subject: 'Rating injusto, passageiro nao compareceu',
      preview: 'Fiquei no local, tentei ligar, mas recebi uma estrela.',
      authorName: 'J. Chauque',
      role: SupportActorRole.driver,
      priority: SupportTicketPriority.medium,
      status: SupportTicketStatus.inProgress,
      minutesAgo: 65,
      assignee: agentName,
      tripId: 'TRP-2829K',
    ),
    _ticket(
      id: 'TKT-2886',
      subject: 'Sugestao de feature',
      preview: 'Seria bom poder guardar enderecos favoritos por categoria.',
      authorName: 'C. Sitoe',
      role: SupportActorRole.passenger,
      priority: SupportTicketPriority.low,
      status: SupportTicketStatus.open,
      minutesAgo: 121,
    ),
    for (var i = 0; i < 28; i++)
      _ticket(
        id: 'TKT-${2885 - i}',
        subject: _subjects[i % _subjects.length],
        preview: _previews[i % _previews.length],
        authorName: _authors[i % _authors.length],
        role: SupportActorRole.values[i % 3],
        priority: SupportTicketPriority.values[i % 4],
        status: SupportTicketStatus.values[i % 4],
        minutesAgo: 140 + i * 37,
        assignee: i % 3 == 0 ? agentName : (i % 5 == 0 ? 'Maria Silva' : null),
        tripId: i % 2 == 0 ? 'TRP-${2820 - i}A' : null,
      ),
  ];

  static final List<SupportDispute> disputes = <SupportDispute>[
    SupportDispute(
      tripId: 'TRP-2832X',
      from: 'Baixa',
      to: 'Matola Gare',
      passengerName: 'A. Macuvele',
      driverName: 'J. Chauque',
      rating: 1,
      comment: 'Driver foi rude e cancelou no meio da corrida',
      status: SupportDisputeStatus.open,
      createdAt: referenceNow.subtract(const Duration(minutes: 18)),
      amount: 1800,
    ),
    SupportDispute(
      tripId: 'TRP-2831F',
      from: 'Polana',
      to: 'Costa do Sol',
      passengerName: 'J. Mondlane',
      driverName: 'R. Bila',
      rating: 2,
      comment: 'Carro sujo, cheirava mal',
      status: SupportDisputeStatus.investigating,
      createdAt: referenceNow.subtract(const Duration(minutes: 43)),
      amount: 620,
    ),
    SupportDispute(
      tripId: 'TRP-2830C',
      from: 'Museu',
      to: 'Aeroporto',
      passengerName: 'C. Sitoe',
      driverName: 'A. Tembe',
      rating: 1,
      comment: 'Cobrou mais que o estimado sem aviso',
      status: SupportDisputeStatus.open,
      createdAt: referenceNow.subtract(const Duration(hours: 2)),
      amount: 980,
    ),
    for (var i = 0; i < 14; i++)
      SupportDispute(
        tripId: 'TRP-${2829 - i}${String.fromCharCode(65 + i)}',
        from: _places[i % _places.length],
        to: _places[(i + 3) % _places.length],
        passengerName: _authors[(i + 2) % _authors.length],
        driverName: _drivers[i % _drivers.length],
        rating: i.isEven ? 1 : 2,
        comment: _disputeComments[i % _disputeComments.length],
        status: SupportDisputeStatus.values[i % 3],
        createdAt: referenceNow.subtract(Duration(hours: 3 + i * 2)),
        amount: 400 + i * 95,
      ),
  ];

  static const List<SupportQuickResult> quickResults = <SupportQuickResult>[
    SupportQuickResult(
      id: 'USR-1142',
      title: 'Celso Mabunda',
      subtitle: '+258 84 992 1122 / celso@email.com / activo',
      type: SupportQuickResultType.passenger,
      route: '/admin/users/USR-1142',
    ),
    SupportQuickResult(
      id: 'DRV-001',
      title: 'A. Macuvele',
      subtitle: 'Driver / +258 84 332 8910 / online',
      type: SupportQuickResultType.driver,
      route: '/admin/drivers/DRV-001',
    ),
    SupportQuickResult(
      id: 'PAR-001',
      title: 'MZ Fleet Lda',
      subtitle: 'NUIT 400123456 / 42 veiculos / activo',
      type: SupportQuickResultType.partner,
      route: '/admin/partners/PAR-001',
    ),
    SupportQuickResult(
      id: 'TRP-2832X',
      title: 'Baixa -> Matola Gare',
      subtitle: '1 800 MTn / completo / disputa aberta',
      type: SupportQuickResultType.trip,
      route: '/admin/trips/TRP-2832X',
    ),
  ];

  static const List<SupportAgentPerformance> leaderboard =
      <SupportAgentPerformance>[
    SupportAgentPerformance(
      position: 1,
      name: agentName,
      email: agentEmail,
      resolved: 247,
      csat: 4.6,
      averageResponse: '2min 12s',
      current: true,
      trend: <double>[18, 21, 23, 22, 25, 27, 31],
    ),
    SupportAgentPerformance(
      position: 2,
      name: 'Maria Silva',
      email: 'maria.support@ya.co.mz',
      resolved: 231,
      csat: 4.7,
      averageResponse: '2min 20s',
      trend: <double>[14, 16, 17, 18, 22, 21, 26],
    ),
    SupportAgentPerformance(
      position: 3,
      name: 'Luis Nhampossa',
      email: 'luis.support@ya.co.mz',
      resolved: 218,
      csat: 4.4,
      averageResponse: '2min 38s',
      trend: <double>[12, 14, 18, 16, 19, 21, 22],
    ),
    SupportAgentPerformance(
      position: 4,
      name: 'Fatima Mucavele',
      email: 'fatima.support@ya.co.mz',
      resolved: 209,
      csat: 4.5,
      averageResponse: '2min 46s',
      trend: <double>[11, 13, 13, 17, 18, 18, 20],
    ),
    SupportAgentPerformance(
      position: 5,
      name: 'Nuno Bila',
      email: 'nuno.support@ya.co.mz',
      resolved: 196,
      csat: 4.3,
      averageResponse: '3min 02s',
      trend: <double>[10, 11, 15, 14, 17, 16, 18],
    ),
    SupportAgentPerformance(
      position: 6,
      name: 'Sara Dlamini',
      email: 'sara.support@ya.co.mz',
      resolved: 184,
      csat: 4.2,
      averageResponse: '3min 15s',
      trend: <double>[9, 12, 12, 15, 15, 16, 17],
    ),
    SupportAgentPerformance(
      position: 7,
      name: 'Edson Nhantumbo',
      email: 'edson.support@ya.co.mz',
      resolved: 171,
      csat: 4.1,
      averageResponse: '3min 28s',
      trend: <double>[8, 9, 11, 12, 13, 14, 16],
    ),
    SupportAgentPerformance(
      position: 8,
      name: 'Lina Macamo',
      email: 'lina.support@ya.co.mz',
      resolved: 156,
      csat: 4.0,
      averageResponse: '3min 44s',
      trend: <double>[7, 8, 10, 10, 12, 13, 14],
    ),
  ];

  static final List<SupportChatThread> chatThreads = <SupportChatThread>[
    SupportChatThread(
      id: 'CHT-1042',
      contactName: 'A. Macuvele',
      contactPhone: '+258 84 332 8910',
      role: SupportActorRole.driver,
      priority: SupportTicketPriority.urgent,
      status: SupportChatStatus.waiting,
      startedAt: referenceNow.subtract(const Duration(minutes: 14)),
      unread: 2,
      tripId: 'TRP-2832X',
      tripFrom: 'Baixa',
      tripTo: 'Matola Gare',
      tripAmount: 1800,
      recentTickets: <String>['TKT-2891', 'TKT-2774', 'TKT-2615'],
      messages: <SupportMessage>[
        SupportMessage(
          author: 'A. Macuvele',
          role: SupportActorRole.driver,
          createdAt: referenceNow.subtract(const Duration(minutes: 14)),
          text:
              'Estou parado no ponto de recolha ha 8 minutos e o passageiro nao aparece.',
        ),
        SupportMessage(
          author: 'A. Macuvele',
          role: SupportActorRole.driver,
          createdAt: referenceNow.subtract(const Duration(minutes: 12)),
          text: 'Tentei ligar duas vezes, ninguem atende.',
        ),
        SupportMessage(
          author: agentName,
          role: SupportActorRole.agent,
          agent: true,
          createdAt: referenceNow.subtract(const Duration(minutes: 10)),
          text:
              'Ola Antonio. Estou a verificar com o passageiro agora. Aguarda 2 minutos.',
        ),
        SupportMessage(
          author: 'A. Macuvele',
          role: SupportActorRole.driver,
          createdAt: referenceNow.subtract(const Duration(minutes: 4)),
          text: 'Ja passaram 4 minutos. Posso cancelar a corrida?',
        ),
        SupportMessage(
          author: 'A. Macuvele',
          role: SupportActorRole.driver,
          createdAt: referenceNow.subtract(const Duration(minutes: 1)),
          text: 'Preciso de uma resposta urgente.',
        ),
      ],
    ),
    SupportChatThread(
      id: 'CHT-1041',
      contactName: 'Helena Nhaca',
      contactPhone: '+258 84 117 4032',
      role: SupportActorRole.passenger,
      priority: SupportTicketPriority.high,
      status: SupportChatStatus.active,
      startedAt: referenceNow.subtract(const Duration(minutes: 22)),
      unread: 0,
      tripId: 'TRP-2831F',
      tripFrom: 'Polana',
      tripTo: 'Costa do Sol',
      tripAmount: 620,
      recentTickets: <String>['TKT-2890'],
      messages: <SupportMessage>[
        SupportMessage(
          author: 'Helena Nhaca',
          createdAt: referenceNow.subtract(const Duration(minutes: 22)),
          text:
              'Boa tarde, o driver nao apareceu para a corrida e fui cobrada na mesma.',
        ),
        SupportMessage(
          author: agentName,
          role: SupportActorRole.agent,
          agent: true,
          createdAt: referenceNow.subtract(const Duration(minutes: 20)),
          text: 'Boa tarde Helena. Vou verificar o estado da corrida agora.',
        ),
        SupportMessage(
          author: agentName,
          role: SupportActorRole.agent,
          agent: true,
          createdAt: referenceNow.subtract(const Duration(minutes: 17)),
          text:
              'Confirmei que o driver cancelou tarde. Vou processar o reembolso integral.',
        ),
        SupportMessage(
          author: 'Helena Nhaca',
          createdAt: referenceNow.subtract(const Duration(minutes: 15)),
          text: 'Obrigada, quanto tempo demora?',
        ),
        SupportMessage(
          author: agentName,
          role: SupportActorRole.agent,
          agent: true,
          createdAt: referenceNow.subtract(const Duration(minutes: 13)),
          text: 'Entre 24 a 48 horas no metodo de pagamento original.',
        ),
      ],
    ),
    SupportChatThread(
      id: 'CHT-1040',
      contactName: 'MZ Fleet Lda',
      contactPhone: '+258 84 800 1100',
      role: SupportActorRole.partner,
      priority: SupportTicketPriority.medium,
      status: SupportChatStatus.typing,
      startedAt: referenceNow.subtract(const Duration(minutes: 35)),
      unread: 1,
      recentTickets: <String>['TKT-2889', 'TKT-2701'],
      messages: <SupportMessage>[
        SupportMessage(
          author: 'MZ Fleet Lda',
          role: SupportActorRole.partner,
          createdAt: referenceNow.subtract(const Duration(minutes: 35)),
          text:
              'Os relatorios financeiros que descarrego nao batem com o painel.',
        ),
        SupportMessage(
          author: agentName,
          role: SupportActorRole.agent,
          agent: true,
          createdAt: referenceNow.subtract(const Duration(minutes: 30)),
          text:
              'Boa tarde. Pode partilhar o periodo exacto e a diferenca aproximada?',
        ),
        SupportMessage(
          author: 'MZ Fleet Lda',
          role: SupportActorRole.partner,
          createdAt: referenceNow.subtract(const Duration(minutes: 27)),
          text: 'Abril 2026. Diferenca de cerca de 12 000 MTn no liquido.',
        ),
        SupportMessage(
          author: 'MZ Fleet Lda',
          role: SupportActorRole.partner,
          createdAt: referenceNow.subtract(const Duration(minutes: 2)),
          text: 'Acabei de enviar o CSV exportado por email.',
          attachmentLabel: 'export-abril-2026.csv',
        ),
      ],
    ),
    SupportChatThread(
      id: 'CHT-1039',
      contactName: 'Celso Mabunda',
      contactPhone: '+258 84 992 1122',
      role: SupportActorRole.passenger,
      priority: SupportTicketPriority.medium,
      status: SupportChatStatus.active,
      startedAt: referenceNow.subtract(const Duration(minutes: 48)),
      unread: 0,
      messages: <SupportMessage>[
        SupportMessage(
          author: 'Celso Mabunda',
          createdAt: referenceNow.subtract(const Duration(minutes: 48)),
          text: 'Como mudo o metodo de pagamento padrao?',
        ),
        SupportMessage(
          author: agentName,
          role: SupportActorRole.agent,
          agent: true,
          createdAt: referenceNow.subtract(const Duration(minutes: 46)),
          text:
              'Em Definicoes / Pagamentos. Toca no metodo desejado e marca como predefinido.',
        ),
        SupportMessage(
          author: 'Celso Mabunda',
          createdAt: referenceNow.subtract(const Duration(minutes: 44)),
          text: 'Funcionou, obrigado.',
        ),
      ],
    ),
    SupportChatThread(
      id: 'CHT-1038',
      contactName: 'J. Chauque',
      contactPhone: '+258 84 555 0090',
      role: SupportActorRole.driver,
      priority: SupportTicketPriority.low,
      status: SupportChatStatus.waiting,
      startedAt: referenceNow.subtract(const Duration(hours: 1, minutes: 12)),
      unread: 1,
      tripId: 'TRP-2829K',
      tripFrom: 'Museu',
      tripTo: 'Magoanine',
      tripAmount: 940,
      recentTickets: <String>['TKT-2887'],
      messages: <SupportMessage>[
        SupportMessage(
          author: 'J. Chauque',
          role: SupportActorRole.driver,
          createdAt: referenceNow.subtract(const Duration(hours: 1, minutes: 12)),
          text: 'Recebi rating de 1 estrela e o passageiro nao apareceu sequer.',
        ),
        SupportMessage(
          author: 'J. Chauque',
          role: SupportActorRole.driver,
          createdAt: referenceNow.subtract(const Duration(minutes: 5)),
          text: 'Pode rever este caso?',
        ),
      ],
    ),
    SupportChatThread(
      id: 'CHT-1037',
      contactName: 'Paula Matavele',
      contactPhone: '+258 84 220 9911',
      role: SupportActorRole.passenger,
      priority: SupportTicketPriority.low,
      status: SupportChatStatus.active,
      startedAt: referenceNow.subtract(const Duration(hours: 2)),
      unread: 0,
      messages: <SupportMessage>[
        SupportMessage(
          author: 'Paula Matavele',
          createdAt: referenceNow.subtract(const Duration(hours: 2)),
          text: 'Posso pedir factura para uma corrida da semana passada?',
        ),
        SupportMessage(
          author: agentName,
          role: SupportActorRole.agent,
          agent: true,
          createdAt: referenceNow.subtract(const Duration(hours: 1, minutes: 58)),
          text: 'Sim. Indica-me por favor o ID da corrida.',
        ),
      ],
    ),
  ];

  static const List<String> chatQuickReplies = <String>[
    'Estou a verificar agora.',
    'Pode confirmar o ID da corrida?',
    'Vou processar o reembolso.',
    'Aguarda 2 minutos.',
    'Ja resolvido. Algo mais?',
    'Vou encaminhar para o admin.',
  ];

  static List<SupportTicket> get activeTickets => tickets
      .where(
        (ticket) =>
            ticket.status == SupportTicketStatus.open ||
            ticket.status == SupportTicketStatus.inProgress,
      )
      .toList()
    ..sort(_ticketSorter);

  static SupportTicket ticketById(String id) {
    return tickets.firstWhere(
      (ticket) => ticket.id == id,
      orElse: () => tickets.first,
    );
  }

  static SupportDispute disputeByTripId(String id) {
    return disputes.firstWhere(
      (dispute) => dispute.tripId == id,
      orElse: () => disputes.first,
    );
  }

  static SupportTicket _ticket({
    required String id,
    required String subject,
    required String preview,
    required String authorName,
    required SupportActorRole role,
    required SupportTicketPriority priority,
    required SupportTicketStatus status,
    required int minutesAgo,
    String? assignee,
    String? tripId,
  }) {
    final DateTime time = referenceNow.subtract(Duration(minutes: minutesAgo));
    return SupportTicket(
      id: id,
      subject: subject,
      preview: preview,
      authorName: authorName,
      authorEmail: '${authorName.toLowerCase().replaceAll(' ', '.')}@ya.mz',
      authorPhone: '+258 84 ${100 + minutesAgo % 899} ${2000 + minutesAgo}',
      role: role,
      priority: priority,
      status: status,
      createdAt: time.subtract(const Duration(minutes: 8)),
      lastMessageAt: time,
      assignee: assignee,
      tripId: tripId,
      messages: <SupportMessage>[
        SupportMessage(
          author: authorName,
          role: role,
          createdAt: time.subtract(const Duration(minutes: 6)),
          text: preview,
        ),
        if (status == SupportTicketStatus.inProgress)
          SupportMessage(
            author: assignee ?? agentName,
            role: SupportActorRole.agent,
            agent: true,
            createdAt: time,
            text: 'Recebido. Vou confirmar os dados e volto ja com resposta.',
          ),
      ],
    );
  }

  static int _ticketSorter(SupportTicket a, SupportTicket b) {
    final int priorityCompare = a.priority.index.compareTo(b.priority.index);
    if (priorityCompare != 0) return priorityCompare;
    return b.lastMessageAt.compareTo(a.lastMessageAt);
  }

  static const List<String> _subjects = <String>[
    'Pagamento nao confirmado na app',
    'Driver cancelou depois de aceitar',
    'Partner pede revisao de comissao',
    'Passageiro nao consegue adicionar cartao',
    'Documento do driver ficou pendente',
    'Erro ao fechar corrida',
  ];

  static const List<String> _previews = <String>[
    'A app ficou presa no ecran de pagamento.',
    'Preciso de ajuda para reabrir o caso.',
    'O valor liquidado nao coincide com o relatorio.',
    'A validacao falha mesmo com dados correctos.',
    'Ja carreguei o ficheiro duas vezes.',
    'A corrida terminou, mas continua activa.',
  ];

  static const List<String> _authors = <String>[
    'Helena Nhaca',
    'Celso Mabunda',
    'Paula Matavele',
    'Mateus Tembe',
    'Sonia Manjate',
    'Rui Chemane',
    'Dina Chongo',
  ];

  static const List<String> _drivers = <String>[
    'J. Chauque',
    'R. Bila',
    'A. Tembe',
    'M. Nhantumbo',
    'C. Macamo',
  ];

  static const List<String> _places = <String>[
    'Baixa',
    'Polana',
    'Museu',
    'Matola',
    'Costa do Sol',
    'Aeroporto',
    'Magoanine',
  ];

  static const List<String> _disputeComments = <String>[
    'Driver recusou seguir a rota sugerida.',
    'Cancelamento suspeito depois de aceitar.',
    'Veiculo diferente do mostrado na app.',
    'Valor cobrado acima do estimado.',
    'Conduta pouco profissional reportada.',
  ];
}

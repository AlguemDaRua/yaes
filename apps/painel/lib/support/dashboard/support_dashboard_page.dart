import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/kpi/kpi_card.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/mock_types.dart';
import '../widgets/support_common.dart';

class SupportDashboardPage extends ConsumerWidget {
  const SupportDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<SupportTicket> allTickets =
        ref.watch(supportTicketsProvider).asData?.value ?? <SupportTicket>[];
    final List<SupportTicket> active =
        ref.watch(supportActiveTicketsProvider).asData?.value ??
            <SupportTicket>[];
    final List<SupportDispute> allDisputes =
        ref.watch(supportDisputesProvider).asData?.value ?? <SupportDispute>[];

    final List<SupportTicket> urgentTickets = active
        .where(
          (SupportTicket ticket) =>
              ticket.priority == SupportTicketPriority.urgent,
        )
        .toList();
    final List<SupportTicket> priorityTickets = active.take(7).toList();
    final List<SupportDispute> disputes = allDisputes.take(3).toList();

    final int openCount = allTickets
        .where((SupportTicket t) => t.status == SupportTicketStatus.open)
        .length;
    final int inProgressCount = allTickets
        .where((SupportTicket t) => t.status == SupportTicketStatus.inProgress)
        .length;
    final int resolvedCount = allTickets
        .where(
          (SupportTicket t) =>
              t.status == SupportTicketStatus.resolved ||
              t.status == SupportTicketStatus.closed,
        )
        .length;
    final int openDisputes = allDisputes
        .where((SupportDispute d) => d.status == SupportDisputeStatus.open)
        .length;

    final DateTime now = DateTime.now();
    final String turno = now.hour < 12
        ? 'manhã'
        : now.hour < 18
            ? 'tarde'
            : 'noite';
    final String headerDesc =
        '${DateFormat("d/MM/y · HH:mm", 'pt_PT').format(now)} · turno: $turno';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        UrgentSupportBanner(tickets: urgentTickets),
        if (urgentTickets.isNotEmpty) const SizedBox(height: YaSpacing.xxl),
        PageHeader(
          title: S.of(context).supportDashboardTitle,
          description: headerDesc,
          actions: <Widget>[
            const SupportServicePill(),
            YaButton.primary(
              label: 'Novo ticket',
              icon: LucideIcons.plus,
              onPressed: () => openNewSupportTicketDialog(context),
            ),
          ],
        ),
        const SizedBox(height: YaSpacing.xxl),
        KpiRow(
          children: <Widget>[
            KpiCard(
              label: 'Abertos',
              value: '$openCount',
              icon: LucideIcons.inbox,
              onTap: () => context.go('/support/queue'),
            ),
            KpiCard(
              label: 'Em atendimento',
              value: '$inProgressCount',
              icon: LucideIcons.headphones,
            ),
            KpiCard(
              label: 'Resolvidos',
              value: '$resolvedCount',
              icon: LucideIcons.circleCheck,
            ),
            KpiCard(
              label: 'Disputas abertas',
              value: '$openDisputes',
              icon: LucideIcons.scale,
              onTap: () => context.go('/support/disputes'),
            ),
          ],
        ),
        const SizedBox(height: YaSpacing.xxl),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 920;
            final Widget tickets =
                _PriorityTicketsCard(tickets: priorityTickets);
            final Widget disputesCard = _RecentDisputesCard(disputes: disputes);

            if (compact) {
              return Column(
                children: <Widget>[
                  tickets,
                  const SizedBox(height: YaSpacing.xxl),
                  disputesCard,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 3, child: tickets),
                const SizedBox(width: YaSpacing.xxl),
                Expanded(flex: 2, child: disputesCard),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PriorityTicketsCard extends StatelessWidget {
  const _PriorityTicketsCard({required this.tickets});

  final List<SupportTicket> tickets;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    return SupportCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(YaSpacing.xl),
            child: SupportSectionTitle(
              title: 'Tickets prioritários',
              action: YaButton.ghost(
                label: 'Ver todos',
                icon: LucideIcons.arrowRight,
                size: YaButtonSize.sm,
                onPressed: () => context.go('/support/tickets'),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 480),
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  for (final SupportTicket ticket in tickets)
                    SupportTicketListItem(
                      ticket: ticket,
                      onTap: () => context.go('/support/tickets/${ticket.id}'),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: YaSpacing.xl,
              vertical: YaSpacing.md,
            ),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              border: Border(top: BorderSide(color: colors.borderSubtle)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: YaButton.link(
                label: 'Ver todos os tickets',
                icon: LucideIcons.arrowRight,
                onPressed: () => context.go('/support/tickets'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentDisputesCard extends StatelessWidget {
  const _RecentDisputesCard({required this.disputes});

  final List<SupportDispute> disputes;

  @override
  Widget build(BuildContext context) {
    return SupportCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.all(YaSpacing.xl),
            child: SupportSectionTitle(title: 'Disputas recentes'),
          ),
          for (final SupportDispute dispute in disputes)
            DisputeMiniCard(dispute: dispute),
          Padding(
            padding: const EdgeInsets.all(YaSpacing.xl),
            child: Text(
              'Rating igual ou inferior a 2 estrelas entra na fila de investigação.',
              style: YaText.sm.copyWith(
                color: YaColors.of(context).textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

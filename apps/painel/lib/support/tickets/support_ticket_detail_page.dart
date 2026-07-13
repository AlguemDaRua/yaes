import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/empty_state.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/feedback/timeline.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../shared/widgets/table/cells.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/mock_types.dart';
import '../widgets/support_common.dart';

class SupportTicketDetailPage extends ConsumerWidget {
  const SupportTicketDetailPage({
    required this.id,
    super.key,
  });

  final String id;

  Future<void> _resolve(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(cloudFunctionsServiceProvider).closeTicket(id);
      ref.invalidate(supportTicketByIdProvider(id));
      ref.invalidate(supportActiveTicketsProvider);
      ref.invalidate(supportTicketsProvider);
      if (!context.mounted) return;
      supportToast(context, 'Ticket resolvido');
      context.go('/support/tickets');
    } catch (e) {
      if (!context.mounted) return;
      supportToast(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SupportTicket?> ticketAsync =
        ref.watch(supportTicketByIdProvider(id));
    final List<SupportDispute> allDisputes =
        ref.watch(supportDisputesProvider).asData?.value ?? <SupportDispute>[];

    return AsyncView<SupportTicket?>(
      value: ticketAsync,
      onRetry: () => ref.invalidate(supportTicketByIdProvider(id)),
      data: (SupportTicket? ticket) {
        if (ticket == null) {
          return const EmptyState(
            icon: LucideIcons.ticket,
            title: 'Ticket não encontrado',
            description: 'O ticket pode ter sido removido.',
          );
        }
        final List<SupportDispute> matchingDisputes = ticket.tripId == null
            ? <SupportDispute>[]
            : allDisputes
                .where((SupportDispute item) => item.tripId == ticket.tripId)
                .toList();
        final SupportDispute? dispute =
            matchingDisputes.isEmpty ? null : matchingDisputes.first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PageHeader(
              title: ticket.id,
              description: ticket.subject,
              actions: <Widget>[
                YaButton.secondary(
                  label: 'Voltar',
                  icon: LucideIcons.arrowLeft,
                  onPressed: () => context.go('/support/tickets'),
                ),
                YaButton.primary(
                  label: 'Resolver',
                  icon: LucideIcons.check,
                  onPressed: () => _resolve(context, ref),
                ),
              ],
            ),
            const SizedBox(height: YaSpacing.xxl),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxWidth < 1000;
                final Widget thread = SupportTicketThreadCard(ticket: ticket);
                final Widget info = _TicketInfoColumn(
                  ticket: ticket,
                  dispute: dispute,
                );

                if (compact) {
                  return Column(
                    children: <Widget>[
                      thread,
                      const SizedBox(height: YaSpacing.xxl),
                      info,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 3, child: thread),
                    const SizedBox(width: YaSpacing.xxl),
                    Expanded(flex: 2, child: info),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _TicketInfoColumn extends StatelessWidget {
  const _TicketInfoColumn({
    required this.ticket,
    required this.dispute,
  });

  final SupportTicket ticket;
  final SupportDispute? dispute;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SupportCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SupportSectionTitle(title: 'Autor'),
              const SizedBox(height: YaSpacing.lg),
              PersonCell(
                name: ticket.authorName,
                subtitle: ticket.authorEmail,
                avatarSize: 44,
              ),
              const SizedBox(height: YaSpacing.md),
              Wrap(
                spacing: YaSpacing.sm,
                runSpacing: YaSpacing.sm,
                children: <Widget>[
                  StatusBadge(
                    variant: StatusVariant.brand,
                    label: supportRoleLabel(ticket.role),
                    size: StatusBadgeSize.sm,
                  ),
                  StatusBadge.fromMapping(
                    supportTicketStatusMapping(ticket.status),
                    size: StatusBadgeSize.sm,
                  ),
                ],
              ),
              const SizedBox(height: YaSpacing.md),
              Text(
                ticket.authorPhone,
                style: YaText.sm.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: YaSpacing.md),
              YaButton.link(
                label: 'Ver perfil',
                icon: LucideIcons.externalLink,
                onPressed: () => supportToast(
                  context,
                  'Perfil aberto',
                  variant: StatusVariant.info,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: YaSpacing.xxl),
        if (ticket.tripId != null)
          SupportCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SupportSectionTitle(title: 'Trip relacionada'),
                const SizedBox(height: YaSpacing.lg),
                IdCell(ticket.tripId!),
                const SizedBox(height: YaSpacing.sm),
                Text(
                  dispute == null
                      ? 'Detalhes operacionais indisponiveis no mock.'
                      : '${dispute!.from} -> ${dispute!.to}',
                  style: YaText.sm.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: YaSpacing.sm),
                Text(
                  supportMoney(dispute?.amount ?? ticket.amount ?? 0),
                  style: YaText.monoBase.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: YaSpacing.md),
                YaButton.secondary(
                  label: 'Abrir trip',
                  icon: LucideIcons.route,
                  onPressed: () => context.go('/admin/trips/${ticket.tripId}'),
                ),
              ],
            ),
          ),
        if (ticket.tripId != null) const SizedBox(height: YaSpacing.xxl),
        SupportCard(
          child: Timeline(
            events: <TimelineEvent>[
              TimelineEvent(
                label: 'Ticket criado por ${ticket.authorName}',
                timestamp: supportRelativeWhen(ticket.createdAt),
                variant: StatusVariant.warning,
              ),
              TimelineEvent(
                label: ticket.assignee == null
                    ? 'A aguardar atribuicao'
                    : 'Atribuido a ${ticket.assignee}',
                timestamp: supportRelativeWhen(ticket.lastMessageAt),
                variant: StatusVariant.info,
              ),
              const TimelineEvent(
                label: 'Comentario interno adicionado',
                timestamp: 'agora',
              ),
            ],
          ),
        ),
        const SizedBox(height: YaSpacing.xxl),
        SupportCard(
          backgroundColor: colors.warningSubtle,
          borderColor: colors.warningBorder,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Notas internas',
                style: YaText.smMedium.copyWith(color: colors.warning),
              ),
              const SizedBox(height: YaSpacing.sm),
              Text(
                ticket.internalNotes ??
                    'Sem notas internas. Mantém o resumo objetivo para o próximo agente.',
                style: YaText.mono(size: 12, height: 18)
                    .copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

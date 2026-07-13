import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_user.dart';
import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/empty_state.dart';
import '../../shared/widgets/filters/filter_bar.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/mock_types.dart';
import '../widgets/support_common.dart';

class SupportQueuePage extends ConsumerStatefulWidget {
  const SupportQueuePage({
    this.initialTicketId,
    super.key,
  });

  final String? initialTicketId;

  @override
  ConsumerState<SupportQueuePage> createState() => _SupportQueuePageState();
}

class _SupportQueuePageState extends ConsumerState<SupportQueuePage> {
  String? _selectedId;
  String _activeFilter = 'all';
  bool _autoRefresh = true;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialTicketId;
  }

  @override
  void didUpdateWidget(covariant SupportQueuePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTicketId != widget.initialTicketId &&
        widget.initialTicketId != null) {
      setState(() => _selectedId = widget.initialTicketId);
    }
  }

  List<SupportTicket> _filteredTickets(
    List<SupportTicket> tickets,
    String agentName,
  ) {
    return tickets.where((SupportTicket ticket) {
      return switch (_activeFilter) {
        'mine' => ticket.assignee == agentName,
        'unassigned' => ticket.assignee == null,
        'urgent' => ticket.priority == SupportTicketPriority.urgent,
        _ => true,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final AuthUser? user = ref.watch(authStateProvider);
    final String agentName = user?.name ?? '';
    final AsyncValue<List<SupportTicket>> ticketsAsync =
        ref.watch(supportActiveTicketsProvider);

    return AsyncView<List<SupportTicket>>(
      value: ticketsAsync,
      onRetry: () => ref.invalidate(supportActiveTicketsProvider),
      data: (List<SupportTicket> tickets) {
        final String? effectiveId =
            _selectedId ?? (tickets.isEmpty ? null : tickets.first.id);
        final List<SupportTicket> visibleTickets =
            _filteredTickets(tickets, agentName);
        final SupportTicket? selected = tickets
            .where((SupportTicket ticket) => ticket.id == effectiveId)
            .firstOrNull;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PageHeader(
              title: S.of(context).supportQueueTitle,
              description:
                  '${tickets.length} tickets ativos · ordenados por prioridade',
              actions: <Widget>[
                YaButton.secondary(
                  label: _autoRefresh ? 'Auto-refresh' : 'Pausado',
                  icon:
                      _autoRefresh ? LucideIcons.refreshCcw : LucideIcons.pause,
                  onPressed: () => setState(() => _autoRefresh = !_autoRefresh),
                ),
                YaButton.primary(
                  label: 'Novo ticket',
                  icon: LucideIcons.plus,
                  onPressed: () => openNewSupportTicketDialog(context),
                ),
              ],
            ),
            const SizedBox(height: YaSpacing.xxl),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxWidth < 960;
                final Widget list = _QueueListCard(
                  tickets: visibleTickets,
                  selectedId: effectiveId,
                  activeFilter: _activeFilter,
                  onFilterChanged: (String id) =>
                      setState(() => _activeFilter = id),
                  onSelect: _selectTicket,
                );
                final Widget detail = selected == null
                    ? const _NoTicketSelectedCard()
                    : _TicketDetailWithBanner(
                        ticket: selected,
                        agentName: agentName,
                        onReassign: () => _reassign(selected),
                      );

                if (compact) {
                  return Column(
                    children: <Widget>[
                      list,
                      const SizedBox(height: YaSpacing.xxl),
                      detail,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 2, child: list),
                    const SizedBox(width: YaSpacing.lg),
                    Expanded(flex: 3, child: detail),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _selectTicket(SupportTicket ticket) {
    setState(() => _selectedId = ticket.id);
    context.go('/support/queue?ticket=${ticket.id}');
  }

  Future<void> _reassign(SupportTicket ticket) async {
    final AuthUser? user = ref.read(authStateProvider);
    if (user == null) return;
    try {
      await ref.read(cloudFunctionsServiceProvider).assignTicket(
            ticketId: ticket.id,
            agentUid: user.uid,
          );
      if (!mounted) return;
      ref.invalidate(supportActiveTicketsProvider);
      supportToast(context, 'Ticket reatribuído a si');
    } catch (e) {
      if (!mounted) return;
      supportToast(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }
}

class _QueueListCard extends StatelessWidget {
  const _QueueListCard({
    required this.tickets,
    required this.selectedId,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.onSelect,
  });

  final List<SupportTicket> tickets;
  final String? selectedId;
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<SupportTicket> onSelect;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    return SupportCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(YaSpacing.lg),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.borderSubtle)),
            ),
            child: FilterBar(
              searchPlaceholder: 'Pesquisar fila...',
              activeChipId: activeFilter,
              onChipSelected: onFilterChanged,
              chips: <FilterChipSpec>[
                FilterChipSpec(
                  id: 'all',
                  label: 'Todos',
                  count: tickets.length,
                ),
                const FilterChipSpec(
                  id: 'mine',
                  label: 'Atribuidos a mim',
                  variant: StatusVariant.info,
                ),
                const FilterChipSpec(
                  id: 'unassigned',
                  label: 'Não atribuídos',
                  variant: StatusVariant.neutral,
                ),
                const FilterChipSpec(
                  id: 'urgent',
                  label: 'Urgentes',
                  variant: StatusVariant.danger,
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 640),
            child: tickets.isEmpty
                ? const EmptyState(
                    icon: LucideIcons.inbox,
                    title: 'Tudo em dia',
                    description: 'Sem tickets na fila.',
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        for (final SupportTicket ticket in tickets)
                          SupportTicketListItem(
                            ticket: ticket,
                            compact: true,
                            selected: ticket.id == selectedId,
                            onTap: () => onSelect(ticket),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TicketDetailWithBanner extends StatelessWidget {
  const _TicketDetailWithBanner({
    required this.ticket,
    required this.agentName,
    required this.onReassign,
  });

  final SupportTicket ticket;
  final String agentName;
  final VoidCallback onReassign;

  @override
  Widget build(BuildContext context) {
    final bool assignedToOther =
        ticket.assignee != null && ticket.assignee != agentName;

    if (!assignedToOther) {
      return SupportTicketThreadCard(ticket: ticket);
    }

    final YaColors colors = YaColors.of(context);
    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(YaSpacing.md),
          decoration: BoxDecoration(
            color: colors.warningSubtle,
            borderRadius: YaRadius.brLg,
            border: Border.all(color: colors.warningBorder),
          ),
          child: Wrap(
            spacing: YaSpacing.sm,
            runSpacing: YaSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Icon(LucideIcons.triangleAlert, size: 16, color: colors.warning),
              Text(
                'Atribuido a ${ticket.assignee}',
                style: YaText.smMedium.copyWith(color: colors.warning),
              ),
              YaButton.secondary(
                label: 'Reatribuir',
                size: YaButtonSize.sm,
                onPressed: onReassign,
              ),
            ],
          ),
        ),
        const SizedBox(height: YaSpacing.lg),
        SupportTicketThreadCard(ticket: ticket),
      ],
    );
  }
}

class _NoTicketSelectedCard extends StatelessWidget {
  const _NoTicketSelectedCard();

  @override
  Widget build(BuildContext context) {
    return const SupportCard(
      child: EmptyState(
        icon: LucideIcons.inbox,
        title: 'Selecciona um ticket',
        description: 'Escolhe um ticket a esquerda para abrir a conversa.',
      ),
    );
  }
}

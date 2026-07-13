import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_user.dart';
import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/filters/filter_bar.dart';
import '../../shared/widgets/forms/ya_select.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../shared/widgets/table/cells.dart';
import '../../shared/widgets/table/data_table.dart';
import '../../theme/tokens/dimensions.dart';
import '../data/mock_types.dart';
import '../widgets/support_common.dart';

class SupportTicketsPage extends ConsumerStatefulWidget {
  const SupportTicketsPage({super.key});

  @override
  ConsumerState<SupportTicketsPage> createState() => _SupportTicketsPageState();
}

class _SupportTicketsPageState extends ConsumerState<SupportTicketsPage> {
  String _activeStatus = 'all';
  String _priority = 'all';
  String _assignee = 'all';
  String _period = '30d';

  List<SupportTicket> _filterRows(
    List<SupportTicket> source,
    String agentName,
  ) {
    return source.where((SupportTicket ticket) {
      final bool statusOk = switch (_activeStatus) {
        'open' => ticket.status == SupportTicketStatus.open,
        'in_progress' => ticket.status == SupportTicketStatus.inProgress,
        'resolved' => ticket.status == SupportTicketStatus.resolved,
        'closed' => ticket.status == SupportTicketStatus.closed,
        _ => true,
      };
      final bool priorityOk =
          _priority == 'all' || ticket.priority.name == _priority;
      final bool assigneeOk = switch (_assignee) {
        'me' => ticket.assignee == agentName,
        'none' => ticket.assignee == null,
        _ => true,
      };
      return statusOk && priorityOk && assigneeOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final AuthUser? user = ref.watch(authStateProvider);
    final String agentName = user?.name ?? '';
    final AsyncValue<List<SupportTicket>> ticketsAsync =
        ref.watch(supportTicketsProvider);

    return AsyncView<List<SupportTicket>>(
      value: ticketsAsync,
      onRetry: () => ref.invalidate(supportTicketsProvider),
      data: (List<SupportTicket> source) {
        final List<SupportTicket> rows = _filterRows(source, agentName);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PageHeader(
              title: S.of(context).supportTicketsTitle,
              description: 'Historico completo de tickets',
              actions: <Widget>[
                YaSelect<String>(
                  width: 180,
                  items: const <YaSelectItem<String>>[
                    YaSelectItem(value: 'all', label: 'Prioridade: todas'),
                    YaSelectItem(value: 'urgent', label: 'Urgente'),
                    YaSelectItem(value: 'high', label: 'Alta'),
                    YaSelectItem(value: 'medium', label: 'Media'),
                    YaSelectItem(value: 'low', label: 'Baixa'),
                  ],
                  value: _priority,
                  onChanged: (String value) =>
                      setState(() => _priority = value),
                ),
                YaSelect<String>(
                  width: 190,
                  items: const <YaSelectItem<String>>[
                    YaSelectItem(value: 'all', label: 'Atribuido a: todos'),
                    YaSelectItem(value: 'me', label: 'A mim'),
                    YaSelectItem(value: 'none', label: 'Sem agente'),
                  ],
                  value: _assignee,
                  onChanged: (String value) =>
                      setState(() => _assignee = value),
                ),
                YaSelect<String>(
                  width: 150,
                  items: const <YaSelectItem<String>>[
                    YaSelectItem(value: '7d', label: 'Periodo: 7d'),
                    YaSelectItem(value: '30d', label: 'Periodo: 30d'),
                    YaSelectItem(value: '90d', label: 'Periodo: 90d'),
                  ],
                  value: _period,
                  onChanged: (String value) => setState(() => _period = value),
                ),
              ],
            ),
            const SizedBox(height: YaSpacing.xxl),
            FilterBar(
              searchPlaceholder: 'ID, assunto ou autor',
              activeChipId: _activeStatus,
              onChipSelected: (String id) => setState(() => _activeStatus = id),
              chips: const <FilterChipSpec>[
                FilterChipSpec(id: 'all', label: 'Todos'),
                FilterChipSpec(
                  id: 'open',
                  label: 'Abertos',
                  variant: StatusVariant.warning,
                ),
                FilterChipSpec(
                  id: 'in_progress',
                  label: 'Em atendimento',
                  variant: StatusVariant.info,
                ),
                FilterChipSpec(
                  id: 'resolved',
                  label: 'Resolvidos',
                  variant: StatusVariant.success,
                ),
                FilterChipSpec(
                  id: 'closed',
                  label: 'Fechados',
                  variant: StatusVariant.neutral,
                ),
              ],
            ),
            const SizedBox(height: YaSpacing.xxl),
            YaDataTable<SupportTicket>(
              rows: rows,
              keyExtractor: (SupportTicket row) => row.id,
              onRowTap: (SupportTicket row) =>
                  context.go('/support/tickets/${row.id}'),
              onRowMore: (SupportTicket row) => supportToast(
                context,
                'Menu de ações para ${row.id}',
                variant: StatusVariant.info,
              ),
              columns: <YaColumn<SupportTicket>>[
                YaColumn<SupportTicket>(
                  key: 'id',
                  label: 'ID',
                  width: 100,
                  cellBuilder: (SupportTicket row) => IdCell(row.id),
                ),
                YaColumn<SupportTicket>(
                  key: 'subject',
                  label: 'Assunto',
                  width: 280,
                  cellBuilder: (SupportTicket row) => TextCell(row.subject),
                ),
                YaColumn<SupportTicket>(
                  key: 'author',
                  label: 'Autor',
                  width: 210,
                  cellBuilder: (SupportTicket row) => PersonCell(
                    name: row.authorName,
                    subtitle: supportRoleLabel(row.role),
                  ),
                ),
                YaColumn<SupportTicket>(
                  key: 'priority',
                  label: 'Prioridade',
                  width: 110,
                  cellBuilder: (SupportTicket row) =>
                      PriorityBadge(row.priority),
                ),
                YaColumn<SupportTicket>(
                  key: 'status',
                  label: 'Status',
                  width: 140,
                  cellBuilder: (SupportTicket row) => StatusBadge.fromMapping(
                    supportTicketStatusMapping(row.status),
                    size: StatusBadgeSize.sm,
                  ),
                ),
                YaColumn<SupportTicket>(
                  key: 'assignee',
                  label: 'Atribuido a',
                  width: 170,
                  cellBuilder: (SupportTicket row) => row.assignee == null
                      ? const TextCell('-', muted: true)
                      : PersonCell(name: row.assignee!, subtitle: 'support'),
                ),
                YaColumn<SupportTicket>(
                  key: 'last',
                  label: 'Ultima msg',
                  width: 110,
                  cellBuilder: (SupportTicket row) =>
                      WhenCell(supportRelativeWhen(row.lastMessageAt)),
                ),
              ],
              footer: YaTablePagination(
                currentPage: 1,
                totalPages: 1,
                onPageChange: (_) {},
                summary: 'A mostrar ${rows.length} de ${source.length}',
              ),
            ),
          ],
        );
      },
    );
  }
}

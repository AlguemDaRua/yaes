import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../shared/widgets/table/cells.dart';
import '../../shared/widgets/table/data_table.dart';
import '../../theme/tokens/dimensions.dart';
import '../data/types.dart';

/// Alterações de comissão registadas na trilha de auditoria (`/audit`,
/// action `setCommission`).
class CommissionsHistoryPage extends ConsumerWidget {
  const CommissionsHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(adminAuditLogsProvider);

    return AsyncView<List<AdminAuditLog>>(
      value: logsAsync,
      onRetry: () => ref.invalidate(adminAuditLogsProvider),
      data: (logs) {
        final rows =
            logs.where((l) => l.action == 'setCommission').toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: S.of(context).adminNavCommissions,
              breadcrumb: const [
                BreadcrumbItem(label: 'Comissões', route: '/admin/commissions'),
                BreadcrumbItem(label: 'Histórico'),
              ],
            ),
            const SizedBox(height: YaSpacing.xxl),
            YaDataTable<AdminAuditLog>(
              columns: [
                YaColumn(
                  key: 'when',
                  label: 'Quando',
                  width: 150,
                  cellBuilder: (l) => WhenCell(
                    DateFormat('dd/MM/yyyy HH:mm').format(l.createdAt),
                  ),
                ),
                YaColumn(
                  key: 'target',
                  label: 'Partner',
                  width: 220,
                  cellBuilder: (l) => TextCell(
                    l.targetPath?.split('/').last ?? '-',
                  ),
                ),
                YaColumn(
                  key: 'rate',
                  label: 'Nova taxa',
                  width: 110,
                  align: Alignment.centerRight,
                  cellBuilder: (l) {
                    final rate = l.metadata['rate'];
                    final pct = rate is num
                        ? '${(rate * 100).round()}%'
                        : '-';
                    return TextCell(pct, alignEnd: true);
                  },
                ),
                YaColumn(
                  key: 'by',
                  label: 'Por',
                  cellBuilder: (l) => TextCell(l.actorUid, muted: true),
                ),
              ],
              rows: rows,
              keyExtractor: (l) => l.id,
              emptyIcon: LucideIcons.history,
              emptyTitle: 'Sem histórico',
              emptyDescription:
                  'As alterações de comissão feitas no painel aparecem aqui.',
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/snack.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/filters/filter_bar.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../shared/widgets/table/cells.dart';
import '../../shared/widgets/table/data_table.dart';
import '../../shared/widgets/table/row_context_menu.dart';
import '../../theme/tokens/dimensions.dart';
import '../data/types.dart';

class FleetsPage extends ConsumerStatefulWidget {
  const FleetsPage({super.key});

  @override
  ConsumerState<FleetsPage> createState() => _FleetsPageState();
}

class _FleetsPageState extends ConsumerState<FleetsPage> {
  String _activeChip = 'all';

  // Cada partner tem exactamente uma frota — números espelham os do partner.
  List<_Fleet> _rowsFrom(List<AdminFleet> fleets) {
    return fleets.map(_Fleet.fromAdmin).toList();
  }

  List<FilterChipSpec> _chipsFor(List<_Fleet> rows) {
    final active = rows.where((row) => row.status == 'active').length;
    final inactive = rows.length - active;
    return [
      FilterChipSpec(id: 'all', label: 'Todas', count: rows.length),
      FilterChipSpec(
        id: 'active',
        label: 'Activas',
        count: active,
        variant: StatusVariant.success,
      ),
      FilterChipSpec(
        id: 'inactive',
        label: 'Inactivas',
        count: inactive,
        variant: StatusVariant.neutral,
      ),
    ];
  }

  List<_Fleet> _filteredRows(List<_Fleet> rows) {
    if (_activeChip == 'all') return rows;
    return rows.where((row) => row.status == _activeChip).toList();
  }

  List<Object> _menuFor(_Fleet row) => [
        YaMenuItem(
          label: 'Ver detalhe',
          icon: LucideIcons.eye,
          onTap: () => context.go('/admin/fleets/${row.id}'),
        ),
        const YaMenuDivider(),
        YaMenuItem(
          label: 'Copiar nome',
          icon: LucideIcons.copy,
          onTap: () {
            Clipboard.setData(ClipboardData(text: row.name));
            yaSnack(context, 'Nome copiado');
          },
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final fleetsAsync = ref.watch(adminFleetsProvider);

    return AsyncView<List<AdminFleet>>(
      value: fleetsAsync,
      onRetry: () => ref.invalidate(adminFleetsProvider),
      data: (fleets) {
        final rows = _rowsFrom(fleets);
        final filtered = _filteredRows(rows);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: S.of(context).adminNavFleets,
              description:
                  'Cada partner tem uma frota — gerida na página do partner',
            ),
            const SizedBox(height: YaSpacing.xxl),
            FilterBar(
              chips: _chipsFor(rows),
              activeChipId: _activeChip,
              onChipSelected: (id) => setState(() => _activeChip = id),
              searchPlaceholder: 'Pesquisar por frota, partner ou cidade...',
            ),
            const SizedBox(height: YaSpacing.lg),
            YaDataTable<_Fleet>(
              columns: [
                YaColumn(
                  key: 'name',
                  label: 'Frota',
                  width: 200,
                  cellBuilder: (row) => PersonCell(
                    name: row.name,
                    subtitle: row.city,
                  ),
                ),
                YaColumn(
                  key: 'partner',
                  label: 'Partner',
                  width: 180,
                  cellBuilder: (row) => TextCell(row.partner),
                ),
                YaColumn(
                  key: 'vehicles',
                  label: 'Veículos',
                  width: 90,
                  align: Alignment.centerRight,
                  cellBuilder: (row) => TextCell(
                    row.vehicles.toString(),
                    alignEnd: true,
                  ),
                ),
                YaColumn(
                  key: 'drivers',
                  label: 'Drivers',
                  width: 80,
                  align: Alignment.centerRight,
                  cellBuilder: (row) => TextCell(
                    row.drivers.toString(),
                    alignEnd: true,
                  ),
                ),
                YaColumn(
                  key: 'revenue',
                  label: 'Receita (mês)',
                  width: 140,
                  align: Alignment.centerRight,
                  cellBuilder: (row) => MoneyCell(
                    amount: row.revenue == 0
                        ? '-'
                        : '${(row.revenue / 1000).toStringAsFixed(0)}K',
                  ),
                ),
                YaColumn(
                  key: 'status',
                  label: 'Estado',
                  width: 140,
                  cellBuilder: (row) => StatusBadge.fromMapping(
                    row.status == 'active'
                        ? YaStatus.partnerActive
                        : const StatusMapping(
                            StatusVariant.neutral,
                            'Inactiva',
                          ),
                  ),
                ),
                YaColumn(
                  key: 'more',
                  label: '',
                  width: 48,
                  cellBuilder: (row) => RowContextMenu(items: _menuFor(row)),
                ),
              ],
              rows: filtered,
              keyExtractor: (row) => row.id,
              onRowTap: (row) => context.go('/admin/fleets/${row.id}'),
              emptyIcon: LucideIcons.layers,
              emptyTitle: 'Sem frotas',
              emptyDescription: 'Cada partner pode criar frotas no seu painel.',
              footer: YaTablePagination(
                currentPage: 1,
                totalPages: 1,
                onPageChange: (_) {},
                summary: 'A mostrar ${filtered.length} de ${rows.length}',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Fleet {
  const _Fleet(
    this.id,
    this.name,
    this.city,
    this.partner,
    this.vehicles,
    this.drivers,
    this.revenue,
    this.status,
  );

  final String id;
  final String name;
  final String city;
  final String partner;
  final int vehicles;
  final int drivers;
  final int revenue;
  final String status;

  factory _Fleet.fromAdmin(AdminFleet fleet) {
    return _Fleet(
      fleet.id,
      fleet.name,
      '',
      fleet.partnerId,
      fleet.vehiclesCount,
      fleet.driversCount,
      0,
      fleet.vehiclesCount == 0 && fleet.driversCount == 0
          ? 'inactive'
          : 'active',
    );
  }
}

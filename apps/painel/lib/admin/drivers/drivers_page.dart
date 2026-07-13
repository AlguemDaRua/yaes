import 'package:flutter/material.dart';
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
import '../../shared/widgets/kpi/kpi_card.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../shared/widgets/table/cells.dart';
import '../../shared/widgets/table/data_table.dart';
import '../../shared/widgets/table/row_context_menu.dart';
import '../../theme/tokens/dimensions.dart';
import '../data/types.dart';

class DriversPage extends ConsumerStatefulWidget {
  const DriversPage({super.key});

  @override
  ConsumerState<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends ConsumerState<DriversPage> {
  String _activeChip = 'all';

  List<_Driver> _rowsFrom(List<AdminDriver> drivers) {
    return drivers.map(_Driver.fromAdmin).toList();
  }

  Future<void> _setStatus(_Driver row) async {
    final bool suspending = row.status != 'suspended';
    try {
      await ref.read(cloudFunctionsServiceProvider).setUserStatus(
            uid: row.id,
            status: suspending ? 'suspended' : 'active',
          );
      if (!mounted) return;
      ref.invalidate(adminDriversProvider);
      yaSnack(context, suspending ? 'Driver suspenso' : 'Driver reativado');
    } catch (e) {
      if (!mounted) return;
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  List<FilterChipSpec> _chipsFor(List<_Driver> rows) {
    int count(bool Function(_Driver row) test) => rows.where(test).length;
    return [
      FilterChipSpec(id: 'all', label: 'Todos', count: rows.length),
      FilterChipSpec(
        id: 'active_online',
        label: 'Online',
        count: count((row) => row.status == 'active' && row.online),
        variant: StatusVariant.success,
      ),
      FilterChipSpec(
        id: 'active_offline',
        label: 'Offline',
        count: count((row) => row.status == 'active' && !row.online),
      ),
      FilterChipSpec(
        id: 'pending',
        label: 'Pendentes',
        count: count((row) => row.status == 'pending'),
        variant: StatusVariant.warning,
      ),
      FilterChipSpec(
        id: 'suspended',
        label: 'Suspensos',
        count: count((row) => row.status == 'suspended'),
        variant: StatusVariant.danger,
      ),
    ];
  }

  List<_Driver> _filteredRows(List<_Driver> rows) {
    return switch (_activeChip) {
      'active_online' =>
        rows.where((row) => row.status == 'active' && row.online).toList(),
      'active_offline' =>
        rows.where((row) => row.status == 'active' && !row.online).toList(),
      'all' => rows,
      _ => rows.where((row) => row.status == _activeChip).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(adminDriversProvider);

    return AsyncView<List<AdminDriver>>(
      value: driversAsync,
      onRetry: () => ref.invalidate(adminDriversProvider),
      data: (drivers) {
        final rows = _rowsFrom(drivers);
        final filtered = _filteredRows(rows);
        final online =
            rows.where((row) => row.status == 'active' && row.online).length;
        final pending = rows.where((row) => row.status == 'pending').length;
        final suspended = rows.where((row) => row.status == 'suspended').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: S.of(context).adminDriversTitle,
              description: 'Motoristas registados na plataforma. O onboarding '
                  'de drivers faz-se na frota do partner.',
            ),
            const SizedBox(height: YaSpacing.xxl),
            KpiRow(
              children: [
                KpiCard(
                  label: 'Total',
                  value: rows.length.toString(),
                  icon: LucideIcons.users,
                ),
                KpiCard(
                  label: 'Online',
                  value: online.toString(),
                  icon: LucideIcons.circleCheck,
                ),
                KpiCard(
                  label: 'Pendentes',
                  value: pending.toString(),
                  icon: LucideIcons.clock,
                ),
                KpiCard(
                  label: 'Suspensos',
                  value: suspended.toString(),
                  icon: LucideIcons.ban,
                ),
              ],
            ),
            const SizedBox(height: YaSpacing.xxl),
            FilterBar(
              chips: _chipsFor(rows),
              activeChipId: _activeChip,
              onChipSelected: (id) => setState(() => _activeChip = id),
              searchPlaceholder: 'Pesquisar por nome, telefone ou partner...',
            ),
            const SizedBox(height: YaSpacing.lg),
            YaDataTable<_Driver>(
              columns: [
                YaColumn(
                  key: 'driver',
                  label: 'Driver',
                  width: 220,
                  cellBuilder: (row) => PersonCell(
                    name: row.name,
                    subtitle: row.phone,
                  ),
                ),
                YaColumn(
                  key: 'partner',
                  label: 'Partner',
                  width: 160,
                  cellBuilder: (row) => TextCell(row.partner, muted: true),
                ),
                YaColumn(
                  key: 'status',
                  label: 'Estado',
                  width: 220,
                  cellBuilder: (row) => StatusBadge.fromMapping(
                    YaStatus.fromDriverStatus(row.status, online: row.online),
                  ),
                ),
                YaColumn(
                  key: 'rating',
                  label: 'Rating',
                  width: 130,
                  align: Alignment.centerRight,
                  cellBuilder: (row) => TextCell(
                    '${row.rating} ★ (${row.totalRatings})',
                    alignEnd: true,
                  ),
                ),
                YaColumn(
                  key: 'trips',
                  label: 'Corridas',
                  width: 90,
                  align: Alignment.centerRight,
                  cellBuilder: (row) => TextCell(
                    row.trips.toString(),
                    alignEnd: true,
                  ),
                ),
                YaColumn(
                  key: 'lastActive',
                  label: 'Última actividade',
                  width: 140,
                  cellBuilder: (row) => WhenCell(row.lastActive),
                ),
                YaColumn(
                  key: 'more',
                  label: '',
                  width: 48,
                  cellBuilder: (row) => RowContextMenu(
                    items: [
                      YaMenuItem(
                        label: 'Ver perfil',
                        icon: LucideIcons.user,
                        onTap: () => context.go('/admin/drivers/${row.id}'),
                      ),
                      const YaMenuDivider(),
                      YaMenuItem(
                        label: row.status == 'suspended'
                            ? 'Reativar'
                            : 'Suspender',
                        icon: row.status == 'suspended'
                            ? LucideIcons.circleCheck
                            : LucideIcons.ban,
                        destructive: row.status != 'suspended',
                        onTap: () => _setStatus(row),
                      ),
                    ],
                  ),
                ),
              ],
              rows: filtered,
              keyExtractor: (row) => row.id,
              onRowTap: (row) => context.go('/admin/drivers/${row.id}'),
              emptyIcon: LucideIcons.user,
              emptyTitle: 'Sem drivers',
              emptyDescription: 'Ajusta os filtros ou convida um novo driver.',
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

class _Driver {
  const _Driver(
    this.id,
    this.name,
    this.phone,
    this.partner,
    this.status,
    this.online,
    this.rating,
    this.totalRatings,
    this.trips,
    this.lastActive,
  );

  final String id;
  final String name;
  final String phone;
  final String partner;
  final String status;
  final bool online;
  final String rating;
  final int totalRatings;
  final int trips;
  final String lastActive;

  factory _Driver.fromAdmin(AdminDriver driver) {
    return _Driver(
      driver.id,
      driver.name,
      driver.phone ?? '-',
      driver.partnerId ?? '-',
      driver.status,
      driver.online,
      driver.rating.toStringAsFixed(2).replaceAll('.', ','),
      0,
      driver.tripsCount,
      '-',
    );
  }
}

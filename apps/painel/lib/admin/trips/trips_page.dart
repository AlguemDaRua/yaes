import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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

class TripsPage extends ConsumerStatefulWidget {
  const TripsPage({super.key});

  @override
  ConsumerState<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends ConsumerState<TripsPage> {
  String _activeChip = 'all';

  List<_Trip> _rowsFrom(List<AdminTrip> trips) {
    return trips.map(_Trip.fromAdmin).toList();
  }

  List<FilterChipSpec> _chipsFor(List<_Trip> rows) {
    int count(String status) =>
        rows.where((row) => row.status == status).length;
    return [
      FilterChipSpec(id: 'all', label: 'Todas', count: rows.length),
      FilterChipSpec(
        id: 'started',
        label: 'A decorrer',
        count: count('started'),
        variant: StatusVariant.warning,
      ),
      FilterChipSpec(
        id: 'completed',
        label: 'Completas',
        count: count('completed'),
        variant: StatusVariant.success,
      ),
      FilterChipSpec(
        id: 'cancelled',
        label: 'Canceladas',
        count: count('cancelled'),
        variant: StatusVariant.danger,
      ),
      FilterChipSpec(
        id: 'accepted',
        label: 'Aceites',
        count: count('accepted'),
        variant: StatusVariant.info,
      ),
    ];
  }

  List<_Trip> _filteredRows(List<_Trip> rows) {
    if (_activeChip == 'all') return rows;
    return rows.where((row) => row.status == _activeChip).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(adminTripsProvider);

    return AsyncView<List<AdminTrip>>(
      value: tripsAsync,
      onRetry: () => ref.invalidate(adminTripsProvider),
      data: (trips) {
        final rows = _rowsFrom(trips);
        final filtered = _filteredRows(rows);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: S.of(context).adminTripsTitle,
              description: 'Histórico e estado das operações',
            ),
            const SizedBox(height: YaSpacing.xxl),
            FilterBar(
              chips: _chipsFor(rows),
              activeChipId: _activeChip,
              onChipSelected: (id) => setState(() => _activeChip = id),
              searchPlaceholder: 'Pesquisar por ID, driver ou rota...',
            ),
            const SizedBox(height: YaSpacing.lg),
            RepaintBoundary(
              child: YaDataTable<_Trip>(
                columns: [
                  YaColumn(
                    key: 'id',
                    label: 'ID',
                    width: 100,
                    cellBuilder: (row) => IdCell(row.id),
                  ),
                  YaColumn(
                    key: 'route',
                    label: 'Rota',
                    cellBuilder: (row) => RouteCell(from: row.from, to: row.to),
                  ),
                  YaColumn(
                    key: 'driver',
                    label: 'Driver',
                    width: 180,
                    cellBuilder: (row) =>
                        PersonCell(name: row.driver, subtitle: ''),
                  ),
                  YaColumn(
                    key: 'type',
                    label: 'Tipo',
                    width: 100,
                    cellBuilder: (row) => TextCell(row.type),
                  ),
                  YaColumn(
                    key: 'amount',
                    label: 'Valor',
                    width: 100,
                    align: Alignment.centerRight,
                    cellBuilder: (row) => MoneyCell(amount: row.amount),
                  ),
                  YaColumn(
                    key: 'status',
                    label: 'Estado',
                    width: 180,
                    cellBuilder: (row) => StatusBadge.fromMapping(
                      YaStatus.fromTripStatus(row.status),
                    ),
                  ),
                  YaColumn(
                    key: 'when',
                    label: 'Quando',
                    width: 100,
                    cellBuilder: (row) => WhenCell(row.when),
                  ),
                  YaColumn(
                    key: 'more',
                    label: '',
                    width: 48,
                    cellBuilder: (row) => RowContextMenu(
                      items: [
                        YaMenuItem(
                          label: 'Ver detalhe',
                          icon: LucideIcons.eye,
                          onTap: () => context.go('/admin/trips/${row.id}'),
                        ),
                        const YaMenuDivider(),
                        YaMenuItem(
                          label: 'Copiar ID',
                          icon: LucideIcons.copy,
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: row.id));
                            yaSnack(context, 'ID copiado');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                rows: filtered,
                keyExtractor: (row) => row.id,
                onRowTap: (row) => context.go('/admin/trips/${row.id}'),
                emptyIcon: LucideIcons.route,
                emptyTitle: 'Sem corridas',
                emptyDescription:
                    'Ajusta os filtros para encontrares corridas.',
                footer: YaTablePagination(
                  currentPage: 1,
                  totalPages: 1,
                  onPageChange: (_) {},
                  summary: 'A mostrar ${filtered.length} de ${rows.length}',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Trip {
  const _Trip(
    this.id,
    this.from,
    this.to,
    this.driver,
    this.type,
    this.amount,
    this.status,
    this.when,
  );

  final String id;
  final String from;
  final String to;
  final String driver;
  final String type;
  final String amount;
  final String status;
  final String when;

  factory _Trip.fromAdmin(AdminTrip trip) {
    return _Trip(
      trip.id,
      trip.origin ?? '-',
      trip.destination ?? '-',
      trip.driverId ?? '-',
      trip.vehicleId ?? '-',
      trip.amountMtn.toString(),
      trip.status,
      DateFormat('dd/MM HH:mm').format(trip.createdAt),
    );
  }
}

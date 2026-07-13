import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/empty_state.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_tabs.dart';
import '../../shared/widgets/kpi/kpi_card.dart';
import '../../shared/widgets/shell/detail_header.dart';
import '../../shared/widgets/table/cells.dart';
import '../../shared/widgets/table/data_table.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/types.dart';

// 1 partner = 1 frota: esta página agrega os dados do partner correspondente.
class FleetDetailPage extends ConsumerStatefulWidget {
  const FleetDetailPage({required this.id, super.key});

  final String id;

  @override
  ConsumerState<FleetDetailPage> createState() => _FleetDetailPageState();
}

class _FleetDetailPageState extends ConsumerState<FleetDetailPage> {
  int _tab = 0;

  static const _tabs = [
    YaTabItem(label: 'Visão geral'),
    YaTabItem(label: 'Drivers'),
    YaTabItem(label: 'Veículos'),
    YaTabItem(label: 'Corridas'),
  ];

  @override
  Widget build(BuildContext context) {
    final fleetAsync = ref.watch(adminFleetByIdProvider(widget.id));

    return AsyncView<AdminFleet?>(
      value: fleetAsync,
      onRetry: () => ref.invalidate(adminFleetByIdProvider(widget.id)),
      data: (fleet) {
        if (fleet == null) {
          return const EmptyState(
            icon: LucideIcons.users,
            title: 'Frota não encontrada',
            description: 'Esta frota pode ter sido removida.',
          );
        }
        return _buildDetail(context, fleet);
      },
    );
  }

  Widget _buildDetail(BuildContext context, AdminFleet fleet) {
    final partner =
        ref.watch(adminPartnerByIdProvider(fleet.partnerId)).asData?.value;
    final partnerName =
        partner?.name ?? fleet.name.replaceFirst(RegExp(r'\s*Fleet$'), '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailHeader(
          name: fleet.name,
          statusBadge: StatusBadge.fromMapping(YaStatus.partnerActive),
          subtitle: 'Partner: $partnerName',
          breadcrumb: _Breadcrumb(
            onBack: () => context.go('/admin/fleets'),
            name: fleet.name,
          ),
          actions: [
            YaButton.secondary(
              label: 'Ver partner',
              icon: LucideIcons.building2,
              onPressed: () => context.go('/admin/partners/${fleet.partnerId}'),
            ),
          ],
          tabs: YaTabs(
            items: _tabs,
            activeIndex: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
        ),
        const SizedBox(height: YaSpacing.xxl),
        switch (_tab) {
          0 => _TabGeral(fleet: fleet),
          1 => _TabDrivers(partnerId: fleet.partnerId),
          2 => _TabVehicles(partnerId: fleet.partnerId),
          3 => _TabTrips(partnerId: fleet.partnerId),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }
}

class _TabGeral extends ConsumerWidget {
  const _TabGeral({required this.fleet});
  final AdminFleet fleet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips =
        ref.watch(adminTripsProvider).asData?.value ?? const <AdminTrip>[];
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final monthTrips = trips
        .where(
          (t) =>
              t.partnerId == fleet.partnerId &&
              t.status == 'completed' &&
              !t.createdAt.isBefore(monthStart),
        )
        .toList();
    final revenue = monthTrips.fold<int>(0, (sum, t) => sum + t.amountMtn);

    return KpiRow(
      children: [
        KpiCard(
          label: 'Drivers',
          value: fleet.driversCount.toString(),
          icon: LucideIcons.user,
        ),
        KpiCard(
          label: 'Veículos',
          value: fleet.vehiclesCount.toString(),
          icon: LucideIcons.car,
        ),
        KpiCard(
          label: 'Corridas (mês)',
          value: monthTrips.length.toString(),
          icon: LucideIcons.route,
        ),
        KpiCard(
          label: 'Receita (mês)',
          value: '${NumberFormat('#,##0', 'pt_PT').format(revenue)} MTn',
          icon: LucideIcons.trendingUp,
        ),
      ],
    );
  }
}

class _TabDrivers extends ConsumerWidget {
  const _TabDrivers({required this.partnerId});
  final String partnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drivers =
        ref.watch(adminDriversProvider).asData?.value ?? const <AdminDriver>[];
    final rows = drivers.where((d) => d.partnerId == partnerId).toList();
    return YaDataTable<AdminDriver>(
      columns: [
        YaColumn(
          key: 'name',
          label: 'Driver',
          width: 240,
          cellBuilder: (d) => PersonCell(name: d.name, subtitle: ''),
        ),
        YaColumn(
          key: 'status',
          label: 'Estado',
          width: 140,
          cellBuilder: (d) => StatusBadge.fromMapping(
            YaStatus.fromDriverStatus(d.status, online: d.online),
          ),
        ),
        YaColumn(
          key: 'trips',
          label: 'Corridas',
          width: 90,
          align: Alignment.centerRight,
          cellBuilder: (d) => TextCell(d.tripsCount.toString(), alignEnd: true),
        ),
      ],
      rows: rows,
      keyExtractor: (d) => d.id,
      onRowTap: (d) => context.go('/admin/drivers/${d.id}'),
      emptyIcon: LucideIcons.user,
      emptyTitle: 'Sem drivers',
      emptyDescription: 'Esta frota ainda não tem drivers.',
    );
  }
}

class _TabVehicles extends ConsumerWidget {
  const _TabVehicles({required this.partnerId});
  final String partnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(adminVehiclesProvider).asData?.value ??
        const <AdminVehicle>[];
    final rows = vehicles.where((v) => v.partnerId == partnerId).toList();
    return YaDataTable<AdminVehicle>(
      columns: [
        YaColumn(
          key: 'plate',
          label: 'Matrícula',
          width: 140,
          cellBuilder: (v) => IdCell(v.plate),
        ),
        YaColumn(
          key: 'model',
          label: 'Modelo',
          cellBuilder: (v) => TextCell(v.model),
        ),
        YaColumn(
          key: 'status',
          label: 'Estado',
          width: 140,
          cellBuilder: (v) => StatusBadge.fromMapping(
            YaStatus.fromVehicleStatus(v.status),
          ),
        ),
      ],
      rows: rows,
      keyExtractor: (v) => v.id,
      emptyIcon: LucideIcons.car,
      emptyTitle: 'Sem veículos',
      emptyDescription: 'Esta frota ainda não tem veículos.',
    );
  }
}

class _TabTrips extends ConsumerWidget {
  const _TabTrips({required this.partnerId});
  final String partnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips =
        ref.watch(adminTripsProvider).asData?.value ?? const <AdminTrip>[];
    final rows = trips.where((t) => t.partnerId == partnerId).toList();
    return YaDataTable<AdminTrip>(
      density: YaTableDensity.compact,
      columns: [
        YaColumn(
          key: 'id',
          label: 'ID',
          width: 100,
          cellBuilder: (t) => IdCell(t.id),
        ),
        YaColumn(
          key: 'route',
          label: 'Rota',
          cellBuilder: (t) => RouteCell(
            from: t.origin ?? '-',
            to: t.destination ?? '-',
          ),
        ),
        YaColumn(
          key: 'amount',
          label: 'Valor',
          width: 100,
          align: Alignment.centerRight,
          cellBuilder: (t) => MoneyCell(amount: t.amountMtn.toString()),
        ),
        YaColumn(
          key: 'status',
          label: 'Estado',
          width: 160,
          cellBuilder: (t) => StatusBadge.fromMapping(
            YaStatus.fromTripStatus(t.status),
          ),
        ),
      ],
      rows: rows,
      keyExtractor: (t) => t.id,
      onRowTap: (t) => context.go('/admin/trips/${t.id}'),
      emptyIcon: LucideIcons.route,
      emptyTitle: 'Sem corridas',
      emptyDescription: 'Esta frota ainda não fez corridas.',
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.onBack, required this.name});

  final VoidCallback onBack;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onBack,
          child: Text(
            'Frotas',
            style: YaText.sm.copyWith(color: colors.textMuted),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('›', style: YaText.sm.copyWith(color: colors.textMuted)),
        ),
        Text(
          name,
          style: YaText.sm.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

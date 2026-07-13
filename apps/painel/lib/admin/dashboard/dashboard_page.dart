import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/charts/bar_chart.dart';
import '../../shared/widgets/charts/chart_card.dart';
import '../../shared/utils/csv_export.dart';
import '../../shared/widgets/charts/line_chart.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/empty_state.dart';
import '../../shared/widgets/feedback/live_pill.dart';
import '../../shared/widgets/feedback/snack.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/kpi/kpi_card.dart';
import '../../shared/widgets/layout/responsive.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../shared/widgets/table/cells.dart';
import '../../shared/widgets/table/data_table.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/types.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = YaColors.of(context);
    final partnersAsync = ref.watch(adminPartnersProvider);
    final driversAsync = ref.watch(adminDriversProvider);
    final tripsAsync = ref.watch(adminTripsProvider);

    if (partnersAsync.isLoading ||
        driversAsync.isLoading ||
        tripsAsync.isLoading) {
      return const AsyncViewSkeleton();
    }

    final error = partnersAsync.error ?? driversAsync.error ?? tripsAsync.error;
    if (error != null) {
      return EmptyState(
        icon: LucideIcons.triangleAlert,
        title: S.of(context).commonError,
        description: error.toString(),
        ctaLabel: S.of(context).commonRetry,
        onCta: () {
          ref
            ..invalidate(adminPartnersProvider)
            ..invalidate(adminDriversProvider)
            ..invalidate(adminTripsProvider);
        },
      );
    }

    final partners = partnersAsync.requireValue;
    final drivers = driversAsync.requireValue;
    final trips = tripsAsync.requireValue;
    final activePartners =
        partners.where((partner) => partner.status == 'active').length;
    final onlineDrivers = drivers
        .where((driver) => driver.status == 'active' && driver.online)
        .length;
    final totalDrivers = drivers.length;
    final activeTrips = trips.where((trip) {
      return trip.status == 'pending' ||
          trip.status == 'accepted' ||
          trip.status == 'started';
    }).length;
    final now = DateTime.now();
    final dateStr =
        DateFormat("d 'de' MMMM 'de' y · HH:mm", 'pt_PT').format(now);

    bool isCompletedIn(AdminTrip trip, DateTime from, DateTime to) {
      return trip.status == 'completed' &&
          !trip.createdAt.isBefore(from) &&
          trip.createdAt.isBefore(to);
    }

    final monthStart = DateTime(now.year, now.month);
    final nextMonthStart = DateTime(now.year, now.month + 1);
    final monthRevenueMtn = trips
        .where((trip) => isCompletedIn(trip, monthStart, nextMonthStart))
        .fold<int>(0, (sum, trip) => sum + trip.amountMtn);

    final revenueLabels = <String>[];
    final revenueValues = <double>[];
    for (var i = 11; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i);
      final nextMonth = DateTime(monthDate.year, monthDate.month + 1);
      final monthSum = trips
          .where((trip) => isCompletedIn(trip, monthDate, nextMonth))
          .fold<int>(0, (sum, trip) => sum + trip.amountMtn);
      final label = DateFormat('MMM', 'pt_PT').format(monthDate);
      revenueLabels.add(
        label.isEmpty
            ? label
            : '${label[0].toUpperCase()}${label.substring(1)}',
      );
      revenueValues.add(monthSum / 1000000);
    }

    final weekdayCutoff = now.subtract(const Duration(days: 30));
    final weekdayCounts = List<int>.filled(7, 0);
    for (final trip in trips) {
      if (trip.createdAt.isAfter(weekdayCutoff)) {
        weekdayCounts[trip.createdAt.weekday - 1] += 1;
      }
    }
    final weekdayValues =
        weekdayCounts.map((count) => count.toDouble()).toList();

    // Taxa de aceitação / tempo até aceite: só viagens que já ficaram
    // disponíveis a motoristas (offeredAt definido) contam como "oferecidas".
    final offeredTrips = trips.where((trip) => trip.offeredAt != null);
    final acceptedTrips =
        offeredTrips.where((trip) => trip.acceptedAt != null).toList();
    final double acceptanceRate = offeredTrips.isEmpty
        ? 0
        : acceptedTrips.length / offeredTrips.length * 100;
    final double avgAcceptSeconds = acceptedTrips.isEmpty
        ? 0
        : acceptedTrips
                .map(
                  (trip) =>
                      trip.acceptedAt!.difference(trip.offeredAt!).inSeconds,
                )
                .fold<int>(0, (sum, s) => sum + s) /
            acceptedTrips.length;

    final acceptanceLabels = <String>[];
    final acceptanceValues = <double>[];
    for (var i = 11; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i);
      final nextMonth = DateTime(monthDate.year, monthDate.month + 1);
      final monthOffered = trips.where(
        (trip) =>
            trip.offeredAt != null &&
            !trip.offeredAt!.isBefore(monthDate) &&
            trip.offeredAt!.isBefore(nextMonth),
      );
      final monthAccepted =
          monthOffered.where((trip) => trip.acceptedAt != null).length;
      final label = DateFormat('MMM', 'pt_PT').format(monthDate);
      acceptanceLabels.add(
        label.isEmpty
            ? label
            : '${label[0].toUpperCase()}${label.substring(1)}',
      );
      acceptanceValues.add(
        monthOffered.isEmpty ? 0 : monthAccepted / monthOffered.length * 100,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: S.of(context).adminDashboardTitle,
          description: 'Visão geral da plataforma · $dateStr',
          actions: [
            YaButton.secondary(
              label: 'Exportar relatório',
              icon: LucideIcons.download,
              onPressed: () {
                final stamp =
                    DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
                downloadCsv('dashboard-$stamp.csv', <List<Object?>>[
                  <Object?>['metrica', 'valor'],
                  <Object?>['partners_activos', activePartners],
                  <Object?>['drivers_online', onlineDrivers],
                  <Object?>['drivers_total', totalDrivers],
                  <Object?>['corridas_activas', activeTrips],
                  <Object?>['receita_mes_mtn', monthRevenueMtn],
                  <Object?>['', ''],
                  <Object?>['mes', 'receita_milhoes_mtn'],
                  for (var i = 0; i < revenueLabels.length; i++)
                    <Object?>[revenueLabels[i], revenueValues[i]],
                ]);
                yaSnack(context, 'Relatório exportado');
              },
            ),
            const LivePill(),
          ],
        ),
        const SizedBox(height: YaSpacing.xxl),
        KpiRow(
          children: [
            KpiCard(
              label: 'Partners activos',
              value: activePartners.toString(),
              icon: LucideIcons.building2,
            ),
            KpiCard(
              label: 'Drivers online',
              value: onlineDrivers.toString(),
              valueSuffix: '/ $totalDrivers',
              icon: LucideIcons.users,
            ),
            KpiCard(
              label: 'Corridas activas',
              value: activeTrips.toString(),
              icon: LucideIcons.route,
              trend: const KpiTrend(
                value: 'em curso agora',
                direction: TrendDirection.flat,
                semantic: TrendSemantic.neutral,
                label: '',
              ),
            ),
            KpiCard(
              label: 'Receita (mês)',
              value: _compactMtn(monthRevenueMtn),
              valueSuffix: 'MTn',
              icon: LucideIcons.trendingUp,
            ),
            KpiCard(
              label: 'Taxa de aceitação',
              value: acceptanceRate.toStringAsFixed(0),
              valueSuffix: '%',
              icon: LucideIcons.checkCheck,
              empty: offeredTrips.isEmpty,
              trend: KpiTrend(
                value: '${acceptedTrips.length} de ${offeredTrips.length}',
                direction: TrendDirection.flat,
                semantic: acceptanceRate >= 70
                    ? TrendSemantic.positive
                    : TrendSemantic.negative,
                label: 'oferecidas',
              ),
            ),
            KpiCard(
              label: 'Tempo até aceite',
              value: acceptedTrips.isEmpty
                  ? '—'
                  : (avgAcceptSeconds / 60).toStringAsFixed(1),
              valueSuffix: acceptedTrips.isEmpty ? '' : 'min',
              icon: LucideIcons.timer,
              empty: acceptedTrips.isEmpty,
            ),
          ],
        ),
        const SizedBox(height: YaSpacing.xxl),
        YaResponsiveStack(
          children: [
            ChartCard(
              title: 'Receita mensal',
              subtitle: 'Últimos 12 meses · em milhões MTn',
              chartHeight: 200,
              child: YaLineChart(
                labels: revenueLabels,
                series: [
                  YaLineSeries(
                    values: revenueValues,
                    color: colors.brand,
                  ),
                ],
              ),
            ),
            ChartCard(
              title: 'Corridas por dia',
              subtitle: 'Média semanal · últimos 30 dias',
              chartHeight: 200,
              child: YaBarChart(
                labels: const [
                  'Seg',
                  'Ter',
                  'Qua',
                  'Qui',
                  'Sex',
                  'Sáb',
                  'Dom',
                ],
                values: weekdayValues,
                primaryColor: colors.brand,
              ),
            ),
            ChartCard(
              title: 'Taxa de aceitação mensal',
              subtitle: 'Últimos 12 meses · % de viagens oferecidas aceites',
              chartHeight: 200,
              child: YaLineChart(
                labels: acceptanceLabels,
                series: [
                  YaLineSeries(
                    values: acceptanceValues,
                    color: colors.success,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: YaSpacing.xxl),
        _RecentTrips(trips: trips),
      ],
    );
  }
}

class _RecentTrips extends StatelessWidget {
  const _RecentTrips({required this.trips});

  final List<AdminTrip>? trips;

  static List<_Trip> _rowsFrom(List<AdminTrip>? trips) {
    if (trips == null) return const <_Trip>[];
    return trips.take(5).map(_Trip.fromAdmin).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final rows = _rowsFrom(trips);
    return ChartCard(
      title: 'Corridas recentes',
      chartHeight: 320,
      action: GestureDetector(
        onTap: () => context.go('/admin/trips'),
        child: Text(
          'Ver todas →',
          style: YaText.sans(
            size: 12,
            height: 16,
            weight: FontWeight.w500,
          ).copyWith(color: colors.brand),
        ),
      ),
      child: YaDataTable<_Trip>(
        density: YaTableDensity.compact,
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
            cellBuilder: (row) => PersonCell(name: row.driver, subtitle: ''),
          ),
          YaColumn(
            key: 'amount',
            label: 'Valor',
            width: 100,
            align: Alignment.centerRight,
            cellBuilder: (row) => MoneyCell(amount: row.amount.toString()),
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
            width: 90,
            cellBuilder: (row) => WhenCell(row.when),
          ),
        ],
        rows: rows,
        keyExtractor: (row) => row.id,
        onRowTap: (row) => context.go('/admin/trips/${row.id}'),
      ),
    );
  }
}

class _Trip {
  const _Trip(
    this.id,
    this.from,
    this.to,
    this.driver,
    this.amount,
    this.status,
    this.when,
  );

  final String id;
  final String from;
  final String to;
  final String driver;
  final int amount;
  final String status;
  final String when;

  factory _Trip.fromAdmin(AdminTrip trip) {
    return _Trip(
      trip.id,
      trip.origin ?? '-',
      trip.destination ?? '-',
      trip.driverId ?? '-',
      trip.amountMtn,
      trip.status,
      DateFormat('dd/MM HH:mm').format(trip.createdAt),
    );
  }
}

String _compactMtn(int mtn) {
  if (mtn >= 1000000) {
    return '${(mtn / 1000000).toStringAsFixed(1).replaceAll('.', ',')}M';
  }
  if (mtn >= 1000) {
    return '${(mtn / 1000).round()}K';
  }
  return mtn.toString();
}

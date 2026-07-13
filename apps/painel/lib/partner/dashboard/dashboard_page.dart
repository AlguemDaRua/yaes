import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../data/providers.dart';
import '../../shared/widgets/charts/bar_chart.dart';
import '../../shared/widgets/charts/chart_card.dart';
import '../../shared/widgets/feedback/info_banner.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/forms/ya_avatar.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/kpi/kpi_card.dart';
import '../../shared/widgets/layout/responsive.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../shared/widgets/table/cells.dart';
import '../../shared/widgets/table/data_table.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/mock_partner_data.dart';
import '../data/mock_types.dart';
import '../widgets/partner_common.dart';

class PartnerDashboardPage extends ConsumerWidget {
  const PartnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now = DateTime.now();
    final String dateStr =
        DateFormat("d 'de' MMMM 'de' y · HH:mm", 'pt_PT').format(now);
    final List<MockDriver> drivers =
        ref.watch(driversProvider).value ?? const <MockDriver>[];
    final List<MockVehicle> vehicles =
        ref.watch(vehiclesProvider).value ?? const <MockVehicle>[];
    final List<MockTrip> trips =
        ref.watch(tripsProvider).value ?? const <MockTrip>[];
    final List<MockAlert> criticalAlerts =
        ref.watch(criticalAlertsProvider).value ?? const <MockAlert>[];

    final _PartnerStats stats = _PartnerStats.from(
      now: now,
      drivers: drivers,
      vehicles: vehicles,
      trips: trips,
    );
    final bool hasTrips = trips.isNotEmpty;
    final List<MockTrip> recentTrips = stats.recentTrips;
    final List<MockDriver> topDrivers = stats.topDrivers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (criticalAlerts.isNotEmpty) ...<Widget>[
          InfoBanner(
            message: '${criticalAlerts.length} alertas requerem atenção: '
                '${_inlineSummary(criticalAlerts)}',
            variant: StatusVariant.danger,
            actionLabel: 'Ver todos ->',
            action: () => context.go('/partner/alerts'),
          ),
          const SizedBox(height: YaSpacing.lg),
        ],
        PageHeader(
          title: S.of(context).partnerDashboardTitle,
          description: dateStr,
          actions: <Widget>[
            YaButton.secondary(
              label: 'Convidar motorista',
              icon: LucideIcons.userPlus,
              onPressed: () => openInviteDriverDialog(context),
            ),
            YaButton.primary(
              label: 'Adicionar veículo',
              icon: LucideIcons.plus,
              onPressed: () => openAddVehicleDialog(context),
            ),
          ],
        ),
        const SizedBox(height: YaSpacing.xxl),
        KpiRow(
          children: <Widget>[
            KpiCard(
              label: 'Corridas (semana)',
              value: stats.weeklyTripsCount.toString(),
              valueSuffix: '(${_formatInt(stats.monthlyTripsCount)} mês)',
              icon: LucideIcons.route,
              empty: !hasTrips,
            ),
            KpiCard(
              label: 'Ganhos líquidos',
              value: _formatCompactMtn(stats.weeklyNetEarningsMtn),
              valueSuffix: 'MTn (7d)',
              icon: LucideIcons.trendingUp,
              variant: KpiCardVariant.highlighted,
              empty: !hasTrips,
            ),
            KpiCard(
              label: 'Drivers online',
              value: stats.onlineDriversCount.toString(),
              valueSuffix: '/ ${drivers.length}',
              icon: LucideIcons.users,
              trend: KpiTrend(
                value: stats.availableVehiclesCount.toString(),
                direction: TrendDirection.flat,
                semantic: TrendSemantic.neutral,
                label: 'veículos disponíveis',
              ),
            ),
            KpiCard(
              label: 'Rating médio',
              value: _formatRating(stats.averageRating),
              valueSuffix: '★',
              icon: LucideIcons.star,
              trend: KpiTrend(
                value: 'saudável',
                direction: TrendDirection.flat,
                semantic: TrendSemantic.positive,
                label: '${_formatInt(stats.ratingsCount)} avaliações',
              ),
              empty: stats.ratingsCount == 0,
            ),
          ],
        ),
        const SizedBox(height: YaSpacing.xxl),
        YaResponsiveStack(
          breakpoint: 980,
          children: <Widget>[
            ChartCard(
              title: 'Ganhos diários · últimos 7 dias',
              action: _CardActionText(
                'Total: ${_formatCompactMtn(stats.weeklyNetEarningsMtn)} MTn',
              ),
              chartHeight: 220,
              child: Builder(
                builder: (BuildContext context) {
                  final YaColors colors = YaColors.of(context);
                  return YaBarChart(
                    values: stats.dailyEarningsMtn7d
                        .map((int value) => value / 1000)
                        .toList(),
                    labels: const <String>[
                      'Seg',
                      'Ter',
                      'Qua',
                      'Qui',
                      'Sex',
                      'Sáb',
                      'Dom',
                    ],
                    primaryColor: colors.brand,
                  );
                },
              ),
            ),
            _TopDriversCard(drivers: topDrivers.take(5).toList()),
          ],
        ),
        const SizedBox(height: YaSpacing.xxl),
        _RecentTripsCard(
          trips: recentTrips.take(5).toList(),
          driverNames: <String, String>{
            for (final MockDriver d in drivers) d.id: d.name,
          },
          loading: ref.watch(tripsProvider).isLoading,
        ),
      ],
    );
  }
}

class _TopDriversCard extends StatelessWidget {
  const _TopDriversCard({required this.drivers});

  final List<MockDriver> drivers;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.all(YaSpacing.lg),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: YaRadius.brLg,
        border: Border.all(color: colors.borderSubtle),
        boxShadow: isLight ? YaShadows.sm : YaShadows.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Top motoristas',
            style: YaText.smMedium.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: YaSpacing.md),
          if (drivers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: YaSpacing.xxl),
              child: Center(
                child: Text(
                  'A frota ainda não tem motoristas activos.',
                  textAlign: TextAlign.center,
                  style: YaText.sm.copyWith(color: colors.textMuted),
                ),
              ),
            )
          else
            for (int i = 0; i < drivers.length; i++) ...<Widget>[
              _TopDriverRow(rank: i + 1, driver: drivers[i]),
              if (i < drivers.length - 1)
                Divider(height: 16, color: colors.borderSubtle),
            ],
        ],
      ),
    );
  }
}

class _TopDriverRow extends StatefulWidget {
  const _TopDriverRow({required this.rank, required this.driver});

  final int rank;
  final MockDriver driver;

  @override
  State<_TopDriverRow> createState() => _TopDriverRowState();
}

class _TopDriverRowState extends State<_TopDriverRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () => context.go('/partner/fleet/driver/${widget.driver.id}'),
        child: AnimatedContainer(
          duration: YaDurations.micro,
          padding: const EdgeInsets.symmetric(
            horizontal: YaSpacing.sm,
            vertical: YaSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: _hovering ? colors.bgSubtle : Colors.transparent,
            borderRadius: YaRadius.brMd,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.brandSubtle,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  widget.rank.toString(),
                  style: YaText.mono(size: 11, height: 14)
                      .copyWith(color: colors.brand),
                ),
              ),
              const SizedBox(width: YaSpacing.sm),
              YaAvatar.fromName(widget.driver.name, border: true),
              const SizedBox(width: YaSpacing.sm),
              Expanded(
                child: Text(
                  widget.driver.name,
                  style: YaText.smMedium.copyWith(color: colors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: YaSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '${_formatInt(widget.driver.totalEarningsMtn)} MTn',
                    style: YaText.mono(size: 12, height: 16)
                        .copyWith(color: colors.textPrimary),
                  ),
                  Text(
                    '${widget.driver.tripsCount} corridas',
                    style: YaText.sans(size: 11, height: 14)
                        .copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTripsCard extends StatelessWidget {
  const _RecentTripsCard({
    required this.trips,
    required this.driverNames,
    this.loading = false,
  });

  final List<MockTrip> trips;
  final Map<String, String> driverNames;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ChartCard(
      title: 'Corridas recentes',
      chartHeight: 252,
      action: GestureDetector(
        onTap: () => context.go('/partner/trips'),
        child: const _CardActionText('Ver todas ->'),
      ),
      child: YaDataTable<MockTrip>(
        loading: loading,
        density: YaTableDensity.compact,
        columns: <YaColumn<MockTrip>>[
          YaColumn<MockTrip>(
            key: 'route',
            label: 'Origem -> Destino',
            cellBuilder: (MockTrip row) => RouteCell(
              from: row.origin,
              to: row.destination,
            ),
          ),
          YaColumn<MockTrip>(
            key: 'driver',
            label: 'Driver',
            width: 190,
            cellBuilder: (MockTrip row) => PersonCell(
              name: driverNames[row.driverId] ?? '—',
              subtitle: '',
            ),
          ),
          YaColumn<MockTrip>(
            key: 'amount',
            label: 'Valor',
            width: 110,
            align: Alignment.centerRight,
            cellBuilder: (MockTrip row) => MoneyCell(
              amount: _formatInt(row.partnerNetMtn),
            ),
          ),
          YaColumn<MockTrip>(
            key: 'status',
            label: 'Status',
            width: 120,
            cellBuilder: (MockTrip row) => StatusBadge.fromMapping(
              YaStatus.fromTripStatus(row.status.key),
              size: StatusBadgeSize.sm,
            ),
          ),
          YaColumn<MockTrip>(
            key: 'when',
            label: 'Quando',
            width: 110,
            cellBuilder: (MockTrip row) =>
                WhenCell(_relativeWhen(row.startedAt)),
          ),
        ],
        rows: trips,
        keyExtractor: (MockTrip row) => row.id,
        onRowTap: (MockTrip row) => context.go('/partner/trips/${row.id}'),
        emptyIcon: LucideIcons.route,
        emptyTitle: 'Sem corridas',
        emptyDescription: 'Aguarda a primeira corrida da frota.',
      ),
    );
  }
}

class _CardActionText extends StatelessWidget {
  const _CardActionText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    return Text(
      text,
      style: YaText.sans(size: 12, height: 16, weight: FontWeight.w500)
          .copyWith(color: colors.brand),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

String _inlineSummary(List<MockAlert> alerts) {
  return alerts.take(3).map((MockAlert alert) => alert.title).join(' · ');
}

String _formatCompactMtn(int value) {
  if (value >= 1000000) {
    final double millions = value / 1000000;
    return '${millions.toStringAsFixed(millions >= 10 ? 0 : 1)}M';
  }
  if (value >= 1000) return '${(value / 1000).round()}K';
  return value.toString();
}

String _formatInt(int value) {
  return NumberFormat.decimalPattern('pt_PT').format(value).replaceAll(
        String.fromCharCode(160),
        ' ',
      );
}

String _formatRating(double value) {
  return NumberFormat('0.0', 'pt_PT').format(value);
}

String _relativeWhen(DateTime date) {
  final Duration diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'há ${diff.inHours} h';
  return 'há ${diff.inDays} d';
}

/// Agregados do dashboard calculados a partir dos dados live do partner.
class _PartnerStats {
  _PartnerStats({
    required this.weeklyTripsCount,
    required this.monthlyTripsCount,
    required this.weeklyNetEarningsMtn,
    required this.onlineDriversCount,
    required this.availableVehiclesCount,
    required this.averageRating,
    required this.ratingsCount,
    required this.dailyEarningsMtn7d,
    required this.topDrivers,
    required this.recentTrips,
  });

  final int weeklyTripsCount;
  final int monthlyTripsCount;
  final int weeklyNetEarningsMtn;
  final int onlineDriversCount;
  final int availableVehiclesCount;
  final double averageRating;
  final int ratingsCount;
  final List<int> dailyEarningsMtn7d;
  final List<MockDriver> topDrivers;
  final List<MockTrip> recentTrips;

  factory _PartnerStats.from({
    required DateTime now,
    required List<MockDriver> drivers,
    required List<MockVehicle> vehicles,
    required List<MockTrip> trips,
  }) {
    final DateTime weekAgo = now.subtract(const Duration(days: 7));
    final DateTime monthAgo = now.subtract(const Duration(days: 30));

    final List<MockTrip> completed = trips
        .where((MockTrip t) => t.status == MockTripStatus.completed)
        .toList();
    final List<MockTrip> weekly = completed
        .where((MockTrip t) => t.startedAt.isAfter(weekAgo))
        .toList();
    final int monthlyCount = completed
        .where((MockTrip t) => t.startedAt.isAfter(monthAgo))
        .length;

    int weeklyNet = 0;
    final List<int> daily = List<int>.filled(7, 0);
    for (final MockTrip t in weekly) {
      weeklyNet += t.partnerNetMtn;
      final int dayIndex = 6 - now.difference(t.startedAt).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        daily[dayIndex] += t.partnerNetMtn;
      }
    }

    int ratingsTotal = 0;
    double weightedRating = 0;
    for (final MockDriver d in drivers) {
      ratingsTotal += d.ratingsCount;
      weightedRating += d.rating * d.ratingsCount;
    }

    final List<MockDriver> top = <MockDriver>[...drivers]
      ..sort(
        (MockDriver a, MockDriver b) =>
            b.totalEarningsMtn.compareTo(a.totalEarningsMtn),
      );
    final List<MockTrip> recent = <MockTrip>[...trips]
      ..sort((MockTrip a, MockTrip b) => b.startedAt.compareTo(a.startedAt));

    return _PartnerStats(
      weeklyTripsCount: weekly.length,
      monthlyTripsCount: monthlyCount,
      weeklyNetEarningsMtn: weeklyNet,
      onlineDriversCount: drivers.where((MockDriver d) => d.online).length,
      availableVehiclesCount: vehicles
          .where((MockVehicle v) => v.status == MockVehicleStatus.available)
          .length,
      averageRating: ratingsTotal > 0 ? weightedRating / ratingsTotal : 0,
      ratingsCount: ratingsTotal,
      dailyEarningsMtn7d: daily,
      topDrivers: top,
      recentTrips: recent,
    );
  }
}

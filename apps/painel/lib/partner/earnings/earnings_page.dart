import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../shared/utils/csv_export.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/charts/chart_card.dart';
import '../../shared/widgets/charts/line_chart.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/filters/filter_bar.dart';
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

class PartnerEarningsPage extends ConsumerStatefulWidget {
  const PartnerEarningsPage({super.key});

  @override
  ConsumerState<PartnerEarningsPage> createState() =>
      _PartnerEarningsPageState();
}

class _PartnerEarningsPageState extends ConsumerState<PartnerEarningsPage> {
  String _type = 'all';
  String _status = 'all';

  /// Próxima data (>= hoje) em que cai o `dayOfWeek` (ISO, 1=segunda) de
  /// `/config/platform/payoutSchedule`.
  static DateTime _nextPayoutDate(DateTime now, int dayOfWeek) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    final int diff = (dayOfWeek - today.weekday + 7) % 7;
    return today.add(Duration(days: diff));
  }

  /// Mapeia os payouts reais ([MockEarningsTransaction]) para linhas da tabela.
  List<_TransactionRow> _mapTransactions(List<MockEarningsTransaction> txns) {
    final List<MockEarningsTransaction> sorted =
        <MockEarningsTransaction>[...txns]..sort(
            (MockEarningsTransaction a, MockEarningsTransaction b) =>
                b.date.compareTo(a.date),
          );
    return sorted.map((MockEarningsTransaction t) {
      return _TransactionRow(
        id: t.id,
        date: t.date,
        type: 'payout',
        tripId: null,
        method: t.label.toLowerCase().contains('banc') ? 'Banco' : 'M-Pesa',
        amountMtn: t.amountMtn,
        status: t.status,
      );
    }).toList();
  }

  List<_TransactionRow> _filteredFrom(List<_TransactionRow> source) {
    return source.where((_TransactionRow row) {
      final bool typeOk = _type == 'all' || row.type == _type;
      final bool statusOk = _status == 'all' || row.status.key == _status;
      return typeOk && statusOk;
    }).toList();
  }

  void _exportCsv(BuildContext context, List<_TransactionRow> rows) {
    if (rows.isEmpty) {
      partnerToast(context, 'Nada para exportar');
      return;
    }
    final String stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
    downloadCsv('ganhos-$stamp.csv', <List<Object?>>[
      <Object?>[
        'id',
        'data',
        'tipo',
        'corrida',
        'metodo',
        'valor_mtn',
        'estado',
      ],
      for (final _TransactionRow row in rows)
        <Object?>[
          row.id,
          DateFormat('yyyy-MM-dd').format(row.date),
          _typeLabel(row.type),
          row.tripId ?? '',
          row.method,
          row.amountMtn,
          row.status.key,
        ],
    ]);
    partnerToast(context, 'CSV exportado');
  }

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    final DateTime now = DateTime.now();
    const List<String> monthAbbr = <String>[
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];
    final List<String> chartLabels = <String>[
      for (int i = 11; i >= 0; i--)
        monthAbbr[DateTime(now.year, now.month - i).month - 1],
    ];
    final AsyncValue<List<MockTrip>> tripsAsync = ref.watch(tripsProvider);
    final AsyncValue<List<MockDriver>> driversAsync =
        ref.watch(driversProvider);
    final AsyncValue<List<MockVehicle>> vehiclesAsync =
        ref.watch(vehiclesProvider);
    final List<MockEarningsTransaction> txns =
        ref.watch(earningsTransactionsProvider).value ??
            const <MockEarningsTransaction>[];
    final Map<String, dynamic> platformConfig =
        ref.watch(adminConfigProvider('platform')).value ??
            const <String, dynamic>{};
    final Object? payoutSchedule = platformConfig['payoutSchedule'];
    final Object? payoutDayRaw =
        payoutSchedule is Map ? payoutSchedule['dayOfWeek'] : null;
    final int payoutDayOfWeek =
        payoutDayRaw is num && payoutDayRaw >= 1 && payoutDayRaw <= 7
            ? payoutDayRaw.toInt()
            : DateTime.friday;
    final DateTime nextPayoutDate = _nextPayoutDate(now, payoutDayOfWeek);

    return AsyncView<List<MockTrip>>(
      value: tripsAsync,
      onRetry: () => ref.invalidate(tripsProvider),
      data: (List<MockTrip> trips) => AsyncView<List<MockDriver>>(
        value: driversAsync,
        onRetry: () => ref.invalidate(driversProvider),
        data: (List<MockDriver> drivers) => AsyncView<List<MockVehicle>>(
          value: vehiclesAsync,
          onRetry: () => ref.invalidate(vehiclesProvider),
          data: (List<MockVehicle> vehicles) {
            final List<MockDriver> topDrivers = (<MockDriver>[...drivers]..sort(
                (MockDriver a, MockDriver b) =>
                    b.totalEarningsMtn.compareTo(a.totalEarningsMtn),
              ));
            final List<_TransactionRow> filtered =
                _filteredFrom(_mapTransactions(txns));
            final _EarningsStats stats =
                _EarningsStats.from(now: now, trips: trips);
            final int weeklyNetMtn = stats.weeklyNetMtn;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                PageHeader(
                  title: S.of(context).partnerEarningsTitle,
                  description:
                      'Receita líquida da tua operação após comissão YA',
                  actions: <Widget>[
                    YaButton.secondary(
                      label: 'Exportar CSV',
                      icon: LucideIcons.download,
                      onPressed: () => _exportCsv(context, filtered),
                    ),
                  ],
                ),
                const SizedBox(height: YaSpacing.xxl),
                KpiRow(
                  children: <Widget>[
                    KpiCard(
                      label: 'Receita bruta (mês)',
                      value: partnerCompactMoney(stats.monthGrossMtn),
                      valueSuffix: 'MTn',
                      icon: LucideIcons.wallet,
                    ),
                    KpiCard(
                      label: 'Comissão YA',
                      value: partnerCompactMoney(stats.monthCommissionMtn),
                      valueSuffix: 'MTn',
                      icon: LucideIcons.percent,
                      trend: const KpiTrend(
                        value: 'pago',
                        direction: TrendDirection.flat,
                        semantic: TrendSemantic.neutral,
                        label: 'à plataforma',
                      ),
                    ),
                    KpiCard(
                      label: 'Líquido (mês)',
                      value: partnerCompactMoney(stats.monthNetMtn),
                      valueSuffix: 'MTn',
                      icon: LucideIcons.trendingUp,
                      variant: KpiCardVariant.highlighted,
                    ),
                    KpiCard(
                      label: 'Próximo payout',
                      value: DateFormat('EEE, d MMM', 'pt_PT')
                          .format(nextPayoutDate),
                      icon: LucideIcons.calendarClock,
                      trend: KpiTrend(
                        value: '${partnerCompactMoney(weeklyNetMtn)} MTn',
                        direction: TrendDirection.flat,
                        semantic: TrendSemantic.neutral,
                        label: 'estimado',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: YaSpacing.xxl),
                ChartCard(
                  title: 'Ganhos líquidos por semana',
                  subtitle: 'Últimos 12 meses',
                  chartHeight: 260,
                  child: YaLineChart(
                    labels: chartLabels,
                    series: <YaLineSeries>[
                      YaLineSeries(
                        values: stats.monthlyNetMtn12
                            .map((int v) => v.toDouble())
                            .toList(),
                        color: colors.brand,
                      ),
                    ],
                    area: true,
                  ),
                ),
                const SizedBox(height: YaSpacing.xxl),
                YaResponsiveStack(
                  children: <Widget>[
                    _TopMoneyListCard.drivers(topDrivers),
                    _TopMoneyListCard.vehicles(vehicles),
                  ],
                ),
                const SizedBox(height: YaSpacing.xxl),
                FilterBar(
                  chips: const <FilterChipSpec>[
                    FilterChipSpec(id: 'all', label: 'Todos'),
                    FilterChipSpec(id: 'commission', label: 'Comissão'),
                    FilterChipSpec(id: 'payout', label: 'Payout'),
                    FilterChipSpec(id: 'refund', label: 'Reembolso'),
                    FilterChipSpec(id: 'bonus', label: 'Bónus'),
                  ],
                  activeChipId: _type,
                  onChipSelected: (String id) => setState(() => _type = id),
                  searchPlaceholder: 'Pesquisar transacções...',
                ),
                const SizedBox(height: YaSpacing.md),
                FilterBar(
                  chips: const <FilterChipSpec>[
                    FilterChipSpec(id: 'all', label: 'Todos'),
                    FilterChipSpec(
                      id: 'paid',
                      label: 'Pago',
                      variant: StatusVariant.success,
                    ),
                    FilterChipSpec(
                      id: 'pending',
                      label: 'Pendente',
                      variant: StatusVariant.warning,
                    ),
                    FilterChipSpec(
                      id: 'failed',
                      label: 'Falhado',
                      variant: StatusVariant.danger,
                    ),
                  ],
                  activeChipId: _status,
                  onChipSelected: (String id) => setState(() => _status = id),
                  searchPlaceholder: 'Pesquisar status...',
                ),
                const SizedBox(height: YaSpacing.lg),
                YaDataTable<_TransactionRow>(
                  columns: <YaColumn<_TransactionRow>>[
                    YaColumn<_TransactionRow>(
                      key: 'date',
                      label: 'Data',
                      width: 120,
                      cellBuilder: (_TransactionRow row) => DateCell(row.date),
                    ),
                    YaColumn<_TransactionRow>(
                      key: 'type',
                      label: 'Tipo',
                      width: 130,
                      cellBuilder: (_TransactionRow row) => StatusBadge(
                        variant: row.type == 'payout'
                            ? StatusVariant.success
                            : row.type == 'refund'
                                ? StatusVariant.info
                                : row.type == 'bonus'
                                    ? StatusVariant.brand
                                    : StatusVariant.neutral,
                        label: _typeLabel(row.type),
                        size: StatusBadgeSize.sm,
                      ),
                    ),
                    YaColumn<_TransactionRow>(
                      key: 'trip',
                      label: 'Trip ID',
                      width: 130,
                      cellBuilder: (_TransactionRow row) => row.tripId == null
                          ? const TextCell('-', muted: true)
                          : IdCell(row.tripId!),
                    ),
                    YaColumn<_TransactionRow>(
                      key: 'method',
                      label: 'Método',
                      width: 110,
                      cellBuilder: (_TransactionRow row) =>
                          TextCell(row.method),
                    ),
                    YaColumn<_TransactionRow>(
                      key: 'amount',
                      label: 'Valor',
                      width: 140,
                      align: Alignment.centerRight,
                      cellBuilder: (_TransactionRow row) =>
                          _AmountCell(row.amountMtn),
                    ),
                    YaColumn<_TransactionRow>(
                      key: 'status',
                      label: 'Status',
                      width: 120,
                      cellBuilder: (_TransactionRow row) =>
                          StatusBadge.fromMapping(
                        YaStatus.fromTransactionStatus(row.status.key),
                        size: StatusBadgeSize.sm,
                      ),
                    ),
                  ],
                  rows: filtered,
                  keyExtractor: (_TransactionRow row) => row.id,
                  onRowTap: (_TransactionRow row) {
                    if (row.tripId != null) {
                      context.go('/partner/trips/${row.tripId}');
                    } else {
                      partnerToast(context, 'Detalhe do payout aberto');
                    }
                  },
                  emptyIcon: LucideIcons.wallet,
                  emptyTitle: 'Sem transacções',
                  emptyDescription: 'Ajusta os filtros para veres resultados.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopMoneyListCard extends StatelessWidget {
  const _TopMoneyListCard({
    required this.title,
    required this.items,
    required this.icon,
    required this.showAvatar,
  });

  factory _TopMoneyListCard.drivers(List<MockDriver> source) {
    return _TopMoneyListCard(
      title: 'Por motorista',
      icon: LucideIcons.user,
      showAvatar: true,
      items: source
          .take(5)
          .map(
            (MockDriver driver) => (
              label: driver.name,
              subtitle: '${driver.tripsCount} corridas',
              amount: driver.totalEarningsMtn,
            ),
          )
          .toList(),
    );
  }

  factory _TopMoneyListCard.vehicles(List<MockVehicle> source) {
    return _TopMoneyListCard(
      title: 'Por veículo',
      icon: LucideIcons.car,
      showAvatar: false,
      items: source
          .take(5)
          .map(
            (MockVehicle vehicle) => (
              label: vehicle.plate,
              subtitle: vehicle.model,
              amount: 92000 - source.indexOf(vehicle) * 7000,
            ),
          )
          .toList(),
    );
  }

  final String title;
  final IconData icon;
  final bool showAvatar;
  final List<({int amount, String label, String subtitle})> items;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    final int top = items.isEmpty
        ? 1
        : items
            .map(
              (({int amount, String label, String subtitle}) item) =>
                  item.amount,
            )
            .reduce(
              (int a, int b) => a > b ? a : b,
            );
    return PartnerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PartnerSectionTitle(title: title),
          const SizedBox(height: YaSpacing.md),
          for (final ({int amount, String label, String subtitle}) item
              in items)
            Padding(
              padding: const EdgeInsets.only(bottom: YaSpacing.md),
              child: Row(
                children: <Widget>[
                  if (showAvatar)
                    YaAvatar.fromName(item.label, border: true)
                  else
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.bgSubtle,
                        borderRadius: YaRadius.brMd,
                      ),
                      child: Icon(icon, size: 16, color: colors.textMuted),
                    ),
                  const SizedBox(width: YaSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.label,
                          style: YaText.smMedium
                              .copyWith(color: colors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.subtitle,
                          style: YaText.sans(size: 12, height: 16)
                              .copyWith(color: colors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: ClipRRect(
                      borderRadius: YaRadius.brFull,
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: item.amount / top,
                        backgroundColor: colors.bgSubtle,
                        valueColor: AlwaysStoppedAnimation<Color>(colors.brand),
                      ),
                    ),
                  ),
                  const SizedBox(width: YaSpacing.sm),
                  SizedBox(
                    width: 92,
                    child: Text(
                      '${partnerCompactMoney(item.amount)} MTn',
                      textAlign: TextAlign.right,
                      style: YaText.mono(size: 12, height: 16)
                          .copyWith(color: colors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AmountCell extends StatelessWidget {
  const _AmountCell(this.amount);

  final int amount;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    final Color color = amount < 0
        ? colors.danger
        : amount > 0
            ? colors.success
            : colors.textMuted;
    final String sign = amount > 0 ? '+' : '';
    return Text(
      '$sign${partnerFormatInt(amount)} MTn',
      textAlign: TextAlign.right,
      style: YaText.mono(size: 13, height: 18, weight: FontWeight.w500)
          .copyWith(color: color),
    );
  }
}

/// Agregados de ganhos calculados a partir das viagens completas (live).
class _EarningsStats {
  _EarningsStats({
    required this.weeklyNetMtn,
    required this.monthGrossMtn,
    required this.monthNetMtn,
    required this.monthCommissionMtn,
    required this.monthlyNetMtn12,
  });

  final int weeklyNetMtn;
  final int monthGrossMtn;
  final int monthNetMtn;
  final int monthCommissionMtn;
  final List<int> monthlyNetMtn12;

  factory _EarningsStats.from({
    required DateTime now,
    required List<MockTrip> trips,
  }) {
    final DateTime weekAgo = now.subtract(const Duration(days: 7));
    int weekly = 0;
    int monthGross = 0;
    int monthNet = 0;
    final List<int> monthly = List<int>.filled(12, 0);

    for (final MockTrip t in trips) {
      if (t.status != MockTripStatus.completed) continue;
      if (t.startedAt.isAfter(weekAgo)) weekly += t.partnerNetMtn;
      if (t.startedAt.year == now.year && t.startedAt.month == now.month) {
        monthGross += t.amountMtn;
        monthNet += t.partnerNetMtn;
      }
      final int monthsAgo = (now.year - t.startedAt.year) * 12 +
          (now.month - t.startedAt.month);
      if (monthsAgo >= 0 && monthsAgo < 12) {
        monthly[11 - monthsAgo] += t.partnerNetMtn;
      }
    }

    return _EarningsStats(
      weeklyNetMtn: weekly,
      monthGrossMtn: monthGross,
      monthNetMtn: monthNet,
      monthCommissionMtn: monthGross - monthNet,
      monthlyNetMtn12: monthly,
    );
  }
}

class _TransactionRow {
  const _TransactionRow({
    required this.id,
    required this.date,
    required this.type,
    required this.tripId,
    required this.method,
    required this.amountMtn,
    required this.status,
  });

  final String id;
  final DateTime date;
  final String type;
  final String? tripId;
  final String method;
  final int amountMtn;
  final MockTransactionStatus status;
}

String _typeLabel(String type) {
  return switch (type) {
    'payout' => 'Payout',
    'refund' => 'Reembolso',
    'bonus' => 'Bónus',
    'commission' => 'Comissão',
    _ => type,
  };
}

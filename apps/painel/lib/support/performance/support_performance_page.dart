import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/charts/sparkline.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/kpi/kpi_card.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../shared/widgets/table/cells.dart';
import '../../shared/widgets/table/data_table.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../data/mock_types.dart';
import '../widgets/support_common.dart';

class SupportPerformancePage extends ConsumerWidget {
  const SupportPerformancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final YaColors colors = YaColors.of(context);
    final AsyncValue<List<SupportAgentPerformance>> leaderboardAsync =
        ref.watch(supportLeaderboardProvider);

    return AsyncView<List<SupportAgentPerformance>>(
      value: leaderboardAsync,
      onRetry: () => ref.invalidate(supportLeaderboardProvider),
      data: (List<SupportAgentPerformance> leaderboard) {
        final int resolvedTotal = leaderboard.fold<int>(
          0,
          (int sum, SupportAgentPerformance a) => sum + a.resolved,
        );
        final double weightedCsat = leaderboard.fold<double>(
          0,
          (double sum, SupportAgentPerformance a) => sum + a.csat * a.resolved,
        );
        final double csat = resolvedTotal > 0
            ? weightedCsat / resolvedTotal
            : (leaderboard.isEmpty
                ? 0
                : leaderboard
                        .map((SupportAgentPerformance a) => a.csat)
                        .reduce((double x, double y) => x + y) /
                    leaderboard.length);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PageHeader(
              title: S.of(context).supportNavPerformance,
              description: 'Métricas da equipa e leaderboard',
            ),
            const SizedBox(height: YaSpacing.xxl),
            KpiRow(
              children: <Widget>[
                KpiCard(
                  label: 'Tickets resolvidos',
                  value: '$resolvedTotal',
                  icon: LucideIcons.circleCheck,
                  empty: leaderboard.isEmpty,
                ),
                KpiCard(
                  label: 'CSAT médio',
                  value: csat.toStringAsFixed(1).replaceAll('.', ','),
                  valueSuffix: '/ 5',
                  icon: LucideIcons.star,
                  empty: leaderboard.isEmpty,
                ),
                KpiCard(
                  label: 'Agentes',
                  value: '${leaderboard.length}',
                  icon: LucideIcons.headphones,
                  empty: leaderboard.isEmpty,
                ),
              ],
            ),
            const SizedBox(height: YaSpacing.xxl),
            _LeaderboardCard(colors: colors, leaderboard: leaderboard),
          ],
        );
      },
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.colors, required this.leaderboard});

  final YaColors colors;
  final List<SupportAgentPerformance> leaderboard;

  @override
  Widget build(BuildContext context) {
    return SupportCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.all(YaSpacing.xl),
            child: SupportSectionTitle(title: 'Leaderboard da equipa'),
          ),
          YaDataTable<SupportAgentPerformance>(
            rows: leaderboard,
            keyExtractor: (SupportAgentPerformance row) => row.email,
            columns: <YaColumn<SupportAgentPerformance>>[
              YaColumn<SupportAgentPerformance>(
                key: 'position',
                label: 'Pos.',
                width: 60,
                cellBuilder: (SupportAgentPerformance row) => Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: row.current ? colors.brandSubtle : colors.bgSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: TextCell(row.position.toString()),
                ),
              ),
              YaColumn<SupportAgentPerformance>(
                key: 'agent',
                label: 'Agente',
                width: 240,
                cellBuilder: (SupportAgentPerformance row) => Row(
                  children: <Widget>[
                    Expanded(
                      child: PersonCell(name: row.name, subtitle: row.email),
                    ),
                    if (row.current)
                      const StatusBadge(
                        variant: StatusVariant.brand,
                        label: 'Eu',
                        size: StatusBadgeSize.sm,
                      ),
                  ],
                ),
              ),
              YaColumn<SupportAgentPerformance>(
                key: 'resolved',
                label: 'Resolvidos',
                width: 90,
                cellBuilder: (SupportAgentPerformance row) =>
                    TextCell(row.resolved.toString(), alignEnd: true),
              ),
              YaColumn<SupportAgentPerformance>(
                key: 'csat',
                label: 'CSAT',
                width: 80,
                cellBuilder: (SupportAgentPerformance row) =>
                    TextCell(row.csat.toStringAsFixed(1), alignEnd: true),
              ),
              YaColumn<SupportAgentPerformance>(
                key: 'time',
                label: 'Tempo médio',
                width: 120,
                cellBuilder: (SupportAgentPerformance row) =>
                    TextCell(row.averageResponse),
              ),
              YaColumn<SupportAgentPerformance>(
                key: 'trend',
                label: 'Trend',
                width: 100,
                cellBuilder: (SupportAgentPerformance row) => Sparkline(
                  data: row.trend,
                  color: row.current ? colors.brand : colors.info,
                  height: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


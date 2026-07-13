import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/feedback/empty_state.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/forms/ya_avatar.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/kpi/kpi_card.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/mock_partner_data.dart';
import '../data/mock_types.dart';
import '../widgets/partner_common.dart';

class PartnerPerformancePage extends ConsumerWidget {
  const PartnerPerformancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final YaColors colors = YaColors.of(context);
    final AsyncValue<List<MockDriver>> driversAsync =
        ref.watch(driversProvider);
    final List<MockDriver> allDrivers = driversAsync.maybeWhen(
      data: (List<MockDriver> d) => d,
      orElse: () => const <MockDriver>[],
    );
    final List<MockDriver> critical = allDrivers
        .where((MockDriver driver) => driver.rating < 4)
        .toList();
    int ratingsTotal = 0;
    double weightedRating = 0;
    for (final MockDriver d in allDrivers) {
      ratingsTotal += d.ratingsCount;
      weightedRating += d.rating * d.ratingsCount;
    }
    final double averageRating =
        ratingsTotal > 0 ? weightedRating / ratingsTotal : 0;

    final List<MockTrip> trips =
        ref.watch(tripsProvider).value ?? const <MockTrip>[];
    final int totalTrips = trips.length;
    final int completedTrips = trips
        .where((MockTrip t) => t.status == MockTripStatus.completed)
        .length;
    final int cancelledTrips = trips
        .where((MockTrip t) => t.status == MockTripStatus.cancelled)
        .length;
    final double cancellationRate =
        totalTrips > 0 ? cancelledTrips / totalTrips * 100 : 0;

    // Tempo médio até aceite dos motoristas desta frota (só viagens já
    // atribuídas — o momento em que ficaram disponíveis a motoristas até ao
    // aceite). Taxa de aceitação não é calculável por partner: uma viagem só
    // ganha partnerId depois de aceite (ver docs/PANEL_BACKLOG.md), então as
    // viagens visíveis aqui já estão todas aceites por definição.
    final List<MockTrip> withAcceptTime = trips
        .where((MockTrip t) => t.offeredAt != null && t.acceptedAt != null)
        .toList();
    final double avgAcceptSeconds = withAcceptTime.isEmpty
        ? 0
        : withAcceptTime
                .map(
                  (MockTrip t) =>
                      t.acceptedAt!.difference(t.offeredAt!).inSeconds,
                )
                .fold<int>(0, (int sum, int s) => sum + s) /
            withAcceptTime.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PageHeader(
          title: S.of(context).partnerNavPerformance,
          description: 'Indicadores de qualidade da tua operação',
        ),
        const SizedBox(height: YaSpacing.xxl),
        KpiRow(
          children: <Widget>[
            KpiCard(
              label: 'Rating médio',
              value: partnerRating(averageRating),
              valueSuffix: '★',
              icon: LucideIcons.star,
              empty: ratingsTotal == 0,
              trend: KpiTrend(
                value: averageRating >= 4 ? 'saudável' : 'a melhorar',
                direction: TrendDirection.flat,
                semantic: averageRating >= 4
                    ? TrendSemantic.positive
                    : TrendSemantic.negative,
                label: '$ratingsTotal avaliações',
              ),
            ),
            KpiCard(
              label: 'Corridas concluídas',
              value: partnerFormatInt(completedTrips),
              icon: LucideIcons.route,
              empty: totalTrips == 0,
            ),
            KpiCard(
              label: 'Cancelamentos',
              value: cancellationRate.toStringAsFixed(1).replaceAll('.', ','),
              valueSuffix: '%',
              icon: LucideIcons.ban,
              empty: totalTrips == 0,
              trend: KpiTrend(
                value: '$cancelledTrips de $totalTrips',
                direction: TrendDirection.flat,
                semantic: cancellationRate <= 10
                    ? TrendSemantic.positive
                    : TrendSemantic.negative,
                label: '',
              ),
            ),
            KpiCard(
              label: 'Motoristas',
              value: '${allDrivers.length}',
              icon: LucideIcons.users,
              empty: allDrivers.isEmpty,
            ),
            KpiCard(
              label: 'Tempo até aceite',
              value: withAcceptTime.isEmpty
                  ? '—'
                  : (avgAcceptSeconds / 60).toStringAsFixed(1),
              valueSuffix: withAcceptTime.isEmpty ? '' : 'min',
              icon: LucideIcons.timer,
              empty: withAcceptTime.isEmpty,
            ),
          ],
        ),
        const SizedBox(height: YaSpacing.xxl),
        PartnerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const PartnerSectionTitle(
                  title: 'Drivers com performance crítica',),
              const SizedBox(height: YaSpacing.lg),
              if (critical.isEmpty)
                const EmptyState(
                  icon: LucideIcons.circleCheck,
                  title: 'Sem drivers críticos',
                  description: 'Operação saudável neste momento.',
                )
              else
                for (final MockDriver driver in critical) ...<Widget>[
                  Wrap(
                    spacing: YaSpacing.sm,
                    runSpacing: YaSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: 180,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            YaAvatar.fromName(
                              driver.name,
                              border: true,
                            ),
                            const SizedBox(width: YaSpacing.sm),
                            Expanded(
                              child: Text(
                                driver.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: YaText.smMedium
                                    .copyWith(color: colors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        variant: StatusVariant.danger,
                        label: 'Rating ${partnerRating(driver.rating)} ★',
                        size: StatusBadgeSize.sm,
                      ),
                      const SizedBox(width: YaSpacing.sm),
                      YaButton.ghost(
                        label: 'Ver perfil ->',
                        onPressed: () =>
                            context.go('/partner/fleet/driver/${driver.id}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: YaSpacing.md),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/empty_state.dart';
import '../../shared/widgets/filters/filter_bar.dart';
import '../../shared/widgets/forms/ya_avatar.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_tabs.dart';
import '../../shared/widgets/kpi/kpi_card.dart';
import '../../shared/widgets/layout/responsive.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/mock_partner_data.dart';
import '../data/mock_types.dart';
import '../widgets/partner_common.dart';

class PartnerDriverDetailPage extends ConsumerStatefulWidget {
  const PartnerDriverDetailPage({required this.id, super.key});

  final String id;

  @override
  ConsumerState<PartnerDriverDetailPage> createState() =>
      _PartnerDriverDetailPageState();
}

class _PartnerDriverDetailPageState
    extends ConsumerState<PartnerDriverDetailPage> {
  int _tab = 0;
  String _ratingChip = 'all';

  List<MockRating> _filterRatings(List<MockRating> rows) {
    return switch (_ratingChip) {
      'five' => rows.where((MockRating rating) => rating.value == 5).toList(),
      'four' => rows.where((MockRating rating) => rating.value == 4).toList(),
      'low' => rows.where((MockRating rating) => rating.value <= 3).toList(),
      _ => rows,
    };
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<MockDriver>> driversAsync =
        ref.watch(driversProvider);
    final AsyncValue<List<MockVehicle>> vehiclesAsync =
        ref.watch(vehiclesProvider);
    final String fleetName =
        ref.watch(partnerProfileProvider).value?.fleetName ?? 'Frota';

    return AsyncView<List<MockDriver>>(
      value: driversAsync,
      onRetry: () => ref.invalidate(driversProvider),
      isEmpty: (List<MockDriver> drivers) => drivers.isEmpty,
      data: (List<MockDriver> drivers) {
        final MockDriver driver = drivers.firstWhere(
          (MockDriver d) => d.id == widget.id,
          orElse: () => drivers.first,
        );
        final AsyncValue<List<MockRating>> ratingsAsync =
            ref.watch(ratingsByDriverProvider(driver.id));
        final AsyncValue<List<MockTrip>> tripsAsync =
            ref.watch(tripsByDriverProvider(driver.id));

        return AsyncView<List<MockVehicle>>(
          value: vehiclesAsync,
          onRetry: () => ref.invalidate(vehiclesProvider),
          data: (List<MockVehicle> vehicles) => AsyncView<List<MockRating>>(
            value: ratingsAsync,
            onRetry: () => ref.invalidate(ratingsByDriverProvider(driver.id)),
            data: (List<MockRating> ratingsAll) => AsyncView<List<MockTrip>>(
              value: tripsAsync,
              onRetry: () => ref.invalidate(tripsByDriverProvider(driver.id)),
              data: (List<MockTrip> trips) {
                final MockVehicle? vehicle = driver.vehicleId == null
                    ? null
                    : vehicles.cast<MockVehicle?>().firstWhere(
                          (MockVehicle? v) => v!.id == driver.vehicleId,
                          orElse: () => null,
                        );
                final List<MockRating> ratings = _filterRatings(ratingsAll);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _DriverHeader(
                      driver: driver,
                      vehicle: vehicle,
                      fleetName: fleetName,
                    ),
                    const SizedBox(height: YaSpacing.xxl),
                    KpiRow(
                      children: <Widget>[
                        KpiCard(
                          label: 'Total corridas',
                          value: partnerFormatInt(driver.tripsCount),
                          icon: LucideIcons.route,
                        ),
                        KpiCard(
                          label: 'Total ganho',
                          value: partnerCompactMoney(driver.totalEarningsMtn),
                          valueSuffix: 'MTn',
                          icon: LucideIcons.trendingUp,
                          variant: KpiCardVariant.highlighted,
                        ),
                        KpiCard(
                          label: 'Avaliação',
                          value: partnerRating(driver.rating),
                          valueSuffix: '★',
                          icon: LucideIcons.star,
                          trend: KpiTrend(
                            value: '${driver.ratingsCount}',
                            direction: TrendDirection.flat,
                            semantic: driver.rating < 4
                                ? TrendSemantic.negative
                                : TrendSemantic.positive,
                            label: 'avaliações',
                          ),
                        ),
                        KpiCard(
                          label: 'Estado',
                          value: driver.online ? 'Online' : 'Offline',
                          icon: LucideIcons.clock,
                          trend: KpiTrend(
                            value: driver.online ? 'agora' : '—',
                            direction: TrendDirection.flat,
                            semantic: driver.online
                                ? TrendSemantic.positive
                                : TrendSemantic.neutral,
                            label: fleetName,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: YaSpacing.xxl),
                    YaTabs(
                      items: <YaTabItem>[
                        const YaTabItem(label: 'Visão geral'),
                        const YaTabItem(label: 'Documentos', count: 4),
                        YaTabItem(label: 'Viagens', count: trips.length),
                        YaTabItem(
                          label: 'Avaliações',
                          count: driver.ratingsCount,
                        ),
                      ],
                      activeIndex: _tab,
                      onChanged: (int index) => setState(() => _tab = index),
                    ),
                    const SizedBox(height: YaSpacing.xxl),
                    switch (_tab) {
                      0 => _OverviewTab(driver: driver, vehicle: vehicle),
                      1 => _DocumentsTab(driver: driver),
                      2 => TripsTableSection(driverId: driver.id),
                      3 => _RatingsTab(
                          ratings: ratings,
                          activeChip: _ratingChip,
                          onChip: (String id) =>
                              setState(() => _ratingChip = id),
                        ),
                      _ => const SizedBox.shrink(),
                    },
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _DriverHeader extends StatelessWidget {
  const _DriverHeader({
    required this.driver,
    required this.vehicle,
    required this.fleetName,
  });

  final MockDriver driver;
  final MockVehicle? vehicle;
  final String fleetName;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    return PartnerCard(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact =
              constraints.maxWidth.isFinite && constraints.maxWidth < 760;
          final Widget titleBlock = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              YaAvatar.fromName(driver.name, size: 64, border: true),
              const SizedBox(width: YaSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: YaSpacing.sm,
                      runSpacing: YaSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          driver.name,
                          style: YaText.xxl.copyWith(color: colors.textPrimary),
                        ),
                        driverBadge(driver),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${driver.phone} · ${driver.email}',
                      style: YaText.sm.copyWith(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Frota: $fleetName',
                      style: YaText.sans(size: 12, height: 16)
                          .copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          );
          final List<Widget> actions = <Widget>[
            YaButton.secondary(
              label: 'Mensagem',
              icon: LucideIcons.mail,
              onPressed: () => context.go('/partner/messages'),
            ),
            if (vehicle == null)
              YaButton.secondary(
                label: 'Atribuir veículo',
                icon: LucideIcons.car,
                onPressed: () => openAssignVehicleDialog(context, driver),
              ),
            if (driver.status == MockDriverStatus.active)
              YaButton.destructive(
                label: 'Suspender',
                icon: LucideIcons.ban,
                onPressed: () => openSuspendDriverDialog(context, driver),
              )
            else if (driver.status == MockDriverStatus.suspended)
              YaButton.primary(
                label: 'Reactivar',
                icon: LucideIcons.rotateCcw,
                onPressed: () => partnerToast(context, 'Driver reactivado'),
              )
            else
              const YaButton.secondary(
                label: 'Pendente',
                icon: LucideIcons.clock,
              ),
          ];

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                titleBlock,
                const SizedBox(height: YaSpacing.lg),
                Wrap(
                  spacing: YaSpacing.sm,
                  runSpacing: YaSpacing.sm,
                  children: actions,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: titleBlock),
              const SizedBox(width: YaSpacing.lg),
              Wrap(
                spacing: YaSpacing.sm,
                runSpacing: YaSpacing.sm,
                children: actions,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.driver, required this.vehicle});

  final MockDriver driver;
  final MockVehicle? vehicle;

  @override
  Widget build(BuildContext context) {
    return YaResponsiveStack(
      children: <Widget>[
        PartnerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const PartnerSectionTitle(title: 'Informações pessoais'),
              const SizedBox(height: YaSpacing.md),
              _InfoRow('Nome completo', driver.name),
              const _InfoRow('BI', '110987654321A'),
              _InfoRow('Telefone', driver.phone),
              _InfoRow('Email', driver.email),
              const _InfoRow('Endereço', 'Av. 24 de Julho, Maputo'),
              _InfoRow('Activo desde', partnerShortDate(driver.joinedAt)),
            ],
          ),
        ),
        PartnerCard(
          child: vehicle == null
              ? EmptyState(
                  icon: LucideIcons.car,
                  title: 'Sem veículo atribuído',
                  description: 'Atribui um veículo disponível da frota.',
                  ctaLabel: 'Atribuir agora',
                  onCta: () => openAssignVehicleDialog(context, driver),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const PartnerSectionTitle(title: 'Veículo atribuído'),
                    const SizedBox(height: YaSpacing.md),
                    Row(
                      children: <Widget>[
                        const VehiclePhoto(size: 80),
                        const SizedBox(width: YaSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                vehicle!.plate,
                                style: YaText.xl.copyWith(
                                  color: YaColors.of(context).textPrimary,
                                ),
                              ),
                              Text(
                                '${vehicle!.model} · ${vehicle!.year}',
                                style: YaText.sm.copyWith(
                                  color: YaColors.of(context).textSecondary,
                                ),
                              ),
                              const SizedBox(height: YaSpacing.sm),
                              vehicleBadge(vehicle!),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: YaSpacing.lg),
                    YaButton.link(
                      label: 'Ver detalhe do veículo ->',
                      onPressed: () =>
                          context.go('/partner/fleet/vehicle/${vehicle!.id}'),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab({required this.driver});

  final MockDriver driver;

  @override
  Widget build(BuildContext context) {
    final DateTime base = DateTime.now();
    final List<(String, MockDocumentStatus, DateTime?)> docs =
        <(String, MockDocumentStatus, DateTime?)>[
      (
        'Carta de condução',
        MockDocumentStatus.ok,
        base.add(const Duration(days: 180))
      ),
      (
        'Atestado médico',
        MockDocumentStatus.expiringSoon,
        base.add(const Duration(days: 18))
      ),
      (
        'Registo criminal',
        MockDocumentStatus.ok,
        base.add(const Duration(days: 240))
      ),
      (
        'Bilhete de identidade',
        driver.status == MockDriverStatus.pending
            ? MockDocumentStatus.missing
            : MockDocumentStatus.ok,
        base.add(const Duration(days: 420)),
      ),
    ];
    return Column(
      children: <Widget>[
        for (final (String title, MockDocumentStatus status, DateTime? expiry)
            in docs) ...<Widget>[
          DocumentCard(
            title: title,
            status: status,
            expiresAt: expiry,
            onTap: () => openUploadDocumentDialog(context, title),
          ),
          const SizedBox(height: YaSpacing.md),
        ],
      ],
    );
  }
}

class _RatingsTab extends StatelessWidget {
  const _RatingsTab({
    required this.ratings,
    required this.activeChip,
    required this.onChip,
  });

  final List<MockRating> ratings;
  final String activeChip;
  final ValueChanged<String> onChip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FilterBar(
          chips: const <FilterChipSpec>[
            FilterChipSpec(id: 'all', label: 'Todas'),
            FilterChipSpec(id: 'five', label: '5 estrelas'),
            FilterChipSpec(id: 'four', label: '4 estrelas'),
            FilterChipSpec(
              id: 'low',
              label: '3 ou menos',
              variant: StatusVariant.warning,
            ),
          ],
          activeChipId: activeChip,
          onChipSelected: onChip,
          searchPlaceholder: 'Pesquisar avaliações...',
        ),
        const SizedBox(height: YaSpacing.lg),
        if (ratings.isEmpty)
          const EmptyState(
            icon: LucideIcons.star,
            title: 'Sem avaliações',
            description: 'Ainda não existem avaliações neste filtro.',
          )
        else
          for (final MockRating rating in ratings.take(12)) ...<Widget>[
            _RatingCard(rating: rating),
            const SizedBox(height: YaSpacing.md),
          ],
      ],
    );
  }
}

class _RatingCard extends ConsumerWidget {
  const _RatingCard({required this.rating});

  final MockRating rating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final YaColors colors = YaColors.of(context);
    final List<MockTrip> trips =
        ref.watch(tripsProvider).value ?? const <MockTrip>[];
    MockTrip? matched;
    for (final MockTrip t in trips) {
      if (t.id == rating.tripId) {
        matched = t;
        break;
      }
    }
    final MockTrip? trip = matched;
    return PartnerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              YaAvatar.fromName(rating.id, border: true),
              const SizedBox(width: YaSpacing.sm),
              Expanded(
                child: Text(
                  'Passageiro ${rating.id.substring(rating.id.length - 3)}',
                  style: YaText.smMedium.copyWith(color: colors.textPrimary),
                ),
              ),
              Text(
                partnerRelativeWhen(rating.createdAt),
                style: YaText.sans(size: 12, height: 16)
                    .copyWith(color: colors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: YaSpacing.sm),
          Text(
            '${List<String>.filled(rating.value, '★').join()}'
            '${List<String>.filled(5 - rating.value, '☆').join()}',
            style: YaText.smMedium.copyWith(color: colors.brand),
          ),
          const SizedBox(height: YaSpacing.sm),
          Text(
            rating.comment,
            style: YaText.sm.copyWith(color: colors.textPrimary),
          ),
          if (trip != null) ...<Widget>[
            const SizedBox(height: YaSpacing.sm),
            YaButton.link(
              label: '${trip.id} · ${trip.origin} -> ${trip.destination}',
              onPressed: () => context.go('/partner/trips/${trip.id}'),
            ),
          ] else if (rating.tripId.isNotEmpty) ...<Widget>[
            const SizedBox(height: YaSpacing.sm),
            YaButton.link(
              label: 'Ver corrida',
              onPressed: () => context.go('/partner/trips/${rating.tripId}'),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: YaSpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: YaText.sm.copyWith(color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: YaSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: YaText.smMedium.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

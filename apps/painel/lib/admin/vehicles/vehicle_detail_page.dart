import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../shared/widgets/feedback/empty_state.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/forms/ya_switch.dart';
import '../../shared/widgets/forms/ya_tabs.dart';
import '../../shared/widgets/kpi/kpi_card.dart';
import '../../shared/widgets/shell/detail_header.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/types.dart';

class VehicleDetailPage extends ConsumerStatefulWidget {
  const VehicleDetailPage({required this.id, super.key});
  final String id;

  @override
  ConsumerState<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends ConsumerState<VehicleDetailPage> {
  int _tab = 0;
  bool _maintenance = false;

  @override
  Widget build(BuildContext context) {
    final vehicle = ref.watch(adminVehicleByIdProvider(widget.id)).value;
    final details = _VehicleDetails.fromAdmin(widget.id, vehicle);
    final status = _maintenance ? 'maintenance' : details.status;

    final String vehicleKey = vehicle?.id ?? widget.id;
    final List<AdminTrip> allTrips =
        ref.watch(adminTripsProvider).asData?.value ?? const <AdminTrip>[];
    final List<AdminTrip> vehicleTrips = allTrips
        .where((AdminTrip t) =>
            t.vehicleId == vehicleKey || t.vehicleId == widget.id,)
        .toList()
      ..sort((AdminTrip a, AdminTrip b) => b.createdAt.compareTo(a.createdAt));
    final double totalKm = vehicleTrips.fold<double>(
      0,
      (double s, AdminTrip t) => s + (t.distanceKm ?? 0),
    );
    final List<AdminDocument> docs =
        (ref.watch(adminDocumentsProvider).asData?.value ??
                const <AdminDocument>[])
            .where((AdminDocument d) =>
                d.ownerType == 'vehicle' &&
                (d.ownerId == vehicleKey || d.ownerId == widget.id),)
            .toList();
    final partnerName = (details.partner == '—' || details.partner.isEmpty)
        ? '—'
        : (ref
                .watch(adminPartnerByIdProvider(details.partner))
                .asData
                ?.value
                ?.name ??
            details.partner);
    final driverName = (details.driver == '-' || details.driver.isEmpty)
        ? '—'
        : (ref
                .watch(adminDriverByIdProvider(details.driver))
                .asData
                ?.value
                ?.name ??
            details.driver);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailHeader(
          name: details.name,
          statusBadge: StatusBadge.fromMapping(
            YaStatus.fromVehicleStatus(status),
          ),
          subtitle: details.subtitle,
          meta: 'Partner: $partnerName',
          breadcrumb: _Breadcrumb(
            plate: details.name,
            onBack: () => context.go('/admin/vehicles'),
          ),
          actions: [
            YaSwitch(
              value: _maintenance,
              onChanged: (v) => setState(() => _maintenance = v),
              label: 'Em manutenção',
            ),
          ],
          tabs: YaTabs(
            items: [
              const YaTabItem(label: 'Visão geral'),
              YaTabItem(label: 'Documentos', count: docs.length),
              YaTabItem(label: 'Corridas', count: vehicleTrips.length),
            ],
            activeIndex: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
        ),
        const SizedBox(height: YaSpacing.xxl),
        switch (_tab) {
          0 => KpiRow(
              children: [
                KpiCard(
                  label: 'Total corridas',
                  value: '${vehicleTrips.length}',
                  icon: LucideIcons.route,
                ),
                KpiCard(
                  label: 'Km totais',
                  value: totalKm.toStringAsFixed(0),
                  valueSuffix: 'km',
                  icon: LucideIcons.mapPin,
                ),
                KpiCard(
                  label: 'Driver actual',
                  value: driverName,
                  icon: LucideIcons.user,
                ),
                KpiCard(
                  label: 'Documentos',
                  value: '${docs.length}',
                  icon: LucideIcons.fileText,
                ),
              ],
            ),
          1 => _DocumentsTab(docs: docs),
          2 => _TripsTab(trips: vehicleTrips),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }
}

class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab({required this.docs});

  final List<AdminDocument> docs;

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) {
      return const EmptyState(
        icon: LucideIcons.fileText,
        title: 'Sem documentos',
        description: 'Este veículo ainda não tem documentos registados.',
      );
    }
    final colors = YaColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final AdminDocument doc in docs)
          Container(
            margin: const EdgeInsets.only(bottom: YaSpacing.sm),
            padding: YaSpacing.cardMd,
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: YaRadius.brLg,
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    doc.type,
                    style: YaText.mdMedium.copyWith(color: colors.textPrimary),
                  ),
                ),
                StatusBadge.fromMapping(
                  YaStatus.fromDocStatus(doc.status),
                  size: StatusBadgeSize.sm,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TripsTab extends StatelessWidget {
  const _TripsTab({required this.trips});

  final List<AdminTrip> trips;

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return const EmptyState(
        icon: LucideIcons.route,
        title: 'Sem corridas',
        description: 'Este veículo ainda não tem corridas registadas.',
      );
    }
    final colors = YaColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final AdminTrip trip in trips)
          Container(
            margin: const EdgeInsets.only(bottom: YaSpacing.sm),
            padding: YaSpacing.cardMd,
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: YaRadius.brLg,
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${trip.origin ?? '—'} → ${trip.destination ?? '—'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: YaText.smMedium.copyWith(color: colors.textPrimary),
                  ),
                ),
                const SizedBox(width: YaSpacing.md),
                Text(
                  '${trip.amountMtn} MTn',
                  style: YaText.monoSm.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(width: YaSpacing.md),
                StatusBadge.fromMapping(
                  YaStatus.fromTripStatus(trip.status),
                  size: StatusBadgeSize.sm,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _VehicleDetails {
  const _VehicleDetails({
    required this.name,
    required this.subtitle,
    required this.partner,
    required this.driver,
    required this.status,
  });

  final String name;
  final String subtitle;
  final String partner;
  final String driver;
  final String status;

  factory _VehicleDetails.fromAdmin(String fallbackId, AdminVehicle? vehicle) {
    if (vehicle == null) {
      // Ainda a carregar (ou inexistente): placeholders neutros.
      return _VehicleDetails(
        name: fallbackId,
        subtitle: '—',
        partner: '—',
        driver: '—',
        status: 'available',
      );
    }
    final plate = vehicle.plate.isEmpty ? vehicle.id : vehicle.plate;
    final year = vehicle.year?.toString() ?? '-';
    return _VehicleDetails(
      name: plate,
      subtitle: '${vehicle.model} · $year · ${vehicle.type}',
      partner: vehicle.partnerId,
      driver: vehicle.driverId ?? '-',
      status: vehicle.status,
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.plate, required this.onBack});
  final String plate;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onBack,
          child: Text(
            'Veículos',
            style: YaText.sm.copyWith(color: colors.textMuted),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '›',
            style: YaText.sm.copyWith(color: colors.textMuted),
          ),
        ),
        Text(
          plate,
          style: YaText.sm.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

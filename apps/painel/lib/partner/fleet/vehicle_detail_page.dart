import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/providers.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/empty_state.dart';
import '../../shared/widgets/forms/ya_avatar.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_switch.dart';
import '../../shared/widgets/forms/ya_tabs.dart';
import '../../shared/widgets/kpi/kpi_card.dart';
import '../../shared/widgets/layout/responsive.dart';
import '../../shared/widgets/table/cells.dart';
import '../../shared/widgets/table/data_table.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/mock_partner_data.dart';
import '../data/mock_types.dart';
import '../widgets/partner_common.dart';

class PartnerVehicleDetailPage extends ConsumerStatefulWidget {
  const PartnerVehicleDetailPage({required this.id, super.key});

  final String id;

  @override
  ConsumerState<PartnerVehicleDetailPage> createState() =>
      _PartnerVehicleDetailPageState();
}

class _PartnerVehicleDetailPageState
    extends ConsumerState<PartnerVehicleDetailPage> {
  int _tab = 0;
  bool _maintenance = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<MockVehicle>> vehiclesAsync =
        ref.watch(vehiclesProvider);
    final AsyncValue<List<MockDriver>> driversAsync =
        ref.watch(driversProvider);
    final String fleetName =
        ref.watch(partnerProfileProvider).value?.fleetName ?? 'Frota';

    return AsyncView<List<MockVehicle>>(
      value: vehiclesAsync,
      onRetry: () => ref.invalidate(vehiclesProvider),
      isEmpty: (List<MockVehicle> vehicles) => vehicles.isEmpty,
      data: (List<MockVehicle> vehicles) {
        final MockVehicle vehicle = vehicles.firstWhere(
          (MockVehicle v) => v.id == widget.id,
          orElse: () => vehicles.first,
        );
        final AsyncValue<List<MockTrip>> tripsAsync =
            ref.watch(tripsByVehicleProvider(vehicle.id));
        final AsyncValue<List<MockMaintenance>> maintenanceAsync =
            ref.watch(maintenancesByVehicleProvider(vehicle.id));

        return AsyncView<List<MockDriver>>(
          value: driversAsync,
          onRetry: () => ref.invalidate(driversProvider),
          data: (List<MockDriver> drivers) => AsyncView<List<MockTrip>>(
            value: tripsAsync,
            onRetry: () => ref.invalidate(tripsByVehicleProvider(vehicle.id)),
            data: (List<MockTrip> trips) => AsyncView<List<MockMaintenance>>(
              value: maintenanceAsync,
              onRetry: () =>
                  ref.invalidate(maintenancesByVehicleProvider(vehicle.id)),
              data: (List<MockMaintenance> maintenanceRows) {
                final MockDriver? driver = vehicle.driverId == null
                    ? null
                    : drivers.cast<MockDriver?>().firstWhere(
                          (MockDriver? d) => d!.id == vehicle.driverId,
                          orElse: () => null,
                        );
                final MockVehicle displayVehicle = _maintenance
                    ? MockVehicle(
                        id: vehicle.id,
                        plate: vehicle.plate,
                        type: vehicle.type,
                        model: vehicle.model,
                        status: MockVehicleStatus.maintenance,
                        driverId: vehicle.driverId,
                        year: vehicle.year,
                        seats: vehicle.seats,
                        odometerKm: vehicle.odometerKm,
                      )
                    : vehicle;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _VehicleHeader(
                      vehicle: displayVehicle,
                      driver: driver,
                      maintenance: _maintenance,
                      onMaintenance: (bool value) {
                        setState(() => _maintenance = value);
                        if (value) {
                          openMaintenanceConfirmDialog(context, vehicle);
                        }
                      },
                    ),
                    const SizedBox(height: YaSpacing.xxl),
                    KpiRow(
                      children: <Widget>[
                        KpiCard(
                          label: 'Total corridas',
                          value: partnerFormatInt(trips.length),
                          icon: LucideIcons.route,
                        ),
                        KpiCard(
                          label: 'Total receita',
                          value: partnerCompactMoney(
                            trips.fold<int>(
                              0,
                              (int total, MockTrip trip) =>
                                  total + trip.partnerNetMtn,
                            ),
                          ),
                          valueSuffix: 'MTn',
                          icon: LucideIcons.trendingUp,
                          variant: KpiCardVariant.highlighted,
                        ),
                        const KpiCard(
                          label: 'Próxima manutenção',
                          value: 'em 12 dias',
                          icon: LucideIcons.wrench,
                          trend: KpiTrend(
                            value: 'atenção',
                            direction: TrendDirection.flat,
                            semantic: TrendSemantic.negative,
                            label: '<30 dias',
                          ),
                        ),
                        KpiCard(
                          label: 'Driver actual',
                          value: driver?.name ?? 'Sem driver',
                          icon: LucideIcons.user,
                        ),
                      ],
                    ),
                    const SizedBox(height: YaSpacing.xxl),
                    YaTabs(
                      items: <YaTabItem>[
                        const YaTabItem(label: 'Visão geral'),
                        const YaTabItem(label: 'Documentos', count: 4),
                        YaTabItem(
                          label: 'Manutenção',
                          count: maintenanceRows.length,
                        ),
                        YaTabItem(label: 'Corridas', count: trips.length),
                      ],
                      activeIndex: _tab,
                      onChanged: (int index) => setState(() => _tab = index),
                    ),
                    const SizedBox(height: YaSpacing.xxl),
                    switch (_tab) {
                      0 => _VehicleOverview(
                          vehicle: vehicle,
                          driver: driver,
                          fleetName: fleetName,
                        ),
                      1 => _VehicleDocuments(vehicle: vehicle),
                      2 => _MaintenanceTab(
                          vehicle: vehicle,
                          rows: maintenanceRows,
                        ),
                      3 => TripsTableSection(vehicleId: vehicle.id),
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

class _VehicleHeader extends StatelessWidget {
  const _VehicleHeader({
    required this.vehicle,
    required this.driver,
    required this.maintenance,
    required this.onMaintenance,
  });

  final MockVehicle vehicle;
  final MockDriver? driver;
  final bool maintenance;
  final ValueChanged<bool> onMaintenance;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    return PartnerCard(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact =
              constraints.maxWidth.isFinite && constraints.maxWidth < 820;
          final Widget titleBlock = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const VehiclePhoto(size: 96),
              const SizedBox(width: YaSpacing.xl),
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
                          vehicle.plate,
                          style: YaText.xxl.copyWith(color: colors.textPrimary),
                        ),
                        vehicleBadge(vehicle),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vehicle.model} · ${vehicle.year} · Branco',
                      style: YaText.sm.copyWith(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${vehicle.type} · ${vehicle.seats} lugares',
                      style: YaText.sans(size: 12, height: 16)
                          .copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          );
          final List<Widget> actions = <Widget>[
            SizedBox(
              width: 190,
              child: YaSwitch(
                value: maintenance,
                onChanged: onMaintenance,
                label: 'Em manutenção',
              ),
            ),
            YaButton.secondary(
              label: 'Mudar foto',
              icon: LucideIcons.camera,
              onPressed: () => partnerToast(context, 'Upload de foto aberto'),
            ),
            if (driver == null)
              YaButton.secondary(
                label: 'Atribuir driver',
                icon: LucideIcons.userPlus,
                onPressed: () => openAssignDriverDialog(context, vehicle),
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

class _VehicleOverview extends StatelessWidget {
  const _VehicleOverview({
    required this.vehicle,
    required this.driver,
    required this.fleetName,
  });

  final MockVehicle vehicle;
  final MockDriver? driver;
  final String fleetName;

  @override
  Widget build(BuildContext context) {
    return YaResponsiveStack(
      children: <Widget>[
        PartnerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const PartnerSectionTitle(title: 'Specs'),
              const SizedBox(height: YaSpacing.md),
              _VehicleInfoRow('Matrícula', vehicle.plate),
              _VehicleInfoRow('Modelo', vehicle.model),
              _VehicleInfoRow('Ano', vehicle.year.toString()),
              _VehicleInfoRow('Tipo', vehicle.type),
              _VehicleInfoRow('Lugares', vehicle.seats.toString()),
              _VehicleInfoRow('Frota', fleetName),
            ],
          ),
        ),
        PartnerCard(
          child: driver == null
              ? EmptyState(
                  icon: LucideIcons.user,
                  title: 'Sem driver atribuído',
                  description: 'Atribui um motorista disponível.',
                  ctaLabel: 'Atribuir driver',
                  onCta: () => openAssignDriverDialog(context, vehicle),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const PartnerSectionTitle(title: 'Driver atribuído'),
                    const SizedBox(height: YaSpacing.md),
                    Row(
                      children: <Widget>[
                        YaAvatar.fromName(driver!.name, size: 48, border: true),
                        const SizedBox(width: YaSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                driver!.name,
                                style: YaText.mdMedium.copyWith(
                                  color: YaColors.of(context).textPrimary,
                                ),
                              ),
                              Text(
                                driver!.phone,
                                style: YaText.sm.copyWith(
                                  color: YaColors.of(context).textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        YaButton.link(
                          label: 'Ver perfil ->',
                          onPressed: () => context.go(
                            '/partner/fleet/driver/${driver!.id}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _VehicleDocuments extends StatelessWidget {
  const _VehicleDocuments({required this.vehicle});

  final MockVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final DateTime base = DateTime.now();
    final List<(String, MockDocumentStatus, DateTime?)> docs =
        <(String, MockDocumentStatus, DateTime?)>[
      (
        'Seguro',
        MockDocumentStatus.expiringSoon,
        base.add(const Duration(days: 18))
      ),
      (
        'Inspecção técnica',
        MockDocumentStatus.ok,
        base.add(const Duration(days: 120))
      ),
      ('Livrete', MockDocumentStatus.ok, null),
      ('Matrícula', MockDocumentStatus.ok, null),
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

class _MaintenanceTab extends StatelessWidget {
  const _MaintenanceTab({required this.vehicle, required this.rows});

  final MockVehicle vehicle;
  final List<MockMaintenance> rows;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PartnerCard(
          backgroundColor: colors.warningSubtle,
          borderColor: colors.warning,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'PRÓXIMA MANUTENÇÃO',
                      style: YaText.eyebrowKpi.copyWith(color: colors.warning),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '17/05/2026',
                      style: YaText.xl.copyWith(color: colors.textPrimary),
                    ),
                    Text(
                      'em 12 dias · revisão preventiva',
                      style: YaText.sm.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              YaButton.primary(
                label: 'Registar manutenção',
                icon: LucideIcons.wrench,
                onPressed: () =>
                    openRegisterMaintenanceDialog(context, vehicle),
              ),
            ],
          ),
        ),
        const SizedBox(height: YaSpacing.xxl),
        YaDataTable<MockMaintenance>(
          columns: <YaColumn<MockMaintenance>>[
            YaColumn<MockMaintenance>(
              key: 'date',
              label: 'Data',
              width: 120,
              cellBuilder: (MockMaintenance row) => DateCell(row.scheduledAt),
            ),
            YaColumn<MockMaintenance>(
              key: 'description',
              label: 'Descrição',
              cellBuilder: (MockMaintenance row) => TextCell(row.title),
            ),
            YaColumn<MockMaintenance>(
              key: 'cost',
              label: 'Custo',
              width: 130,
              align: Alignment.centerRight,
              cellBuilder: (MockMaintenance row) =>
                  MoneyCell(amount: partnerFormatInt(row.costMtn)),
            ),
            YaColumn<MockMaintenance>(
              key: 'next',
              label: 'Próxima',
              width: 120,
              cellBuilder: (MockMaintenance row) => DateCell(
                row.scheduledAt.add(const Duration(days: 90)),
              ),
            ),
            YaColumn<MockMaintenance>(
              key: 'by',
              label: 'Por',
              width: 130,
              cellBuilder: (MockMaintenance row) =>
                  const TextCell('Oficina XYZ'),
            ),
          ],
          rows: rows.take(5).toList(),
          keyExtractor: (MockMaintenance row) => row.id,
          emptyIcon: LucideIcons.wrench,
          emptyTitle: 'Sem manutenção',
          emptyDescription: 'Ainda não há histórico para este veículo.',
        ),
      ],
    );
  }
}

class _VehicleInfoRow extends StatelessWidget {
  const _VehicleInfoRow(this.label, this.value);

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

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_user.dart';
import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../shared/widgets/dialogs/confirm_dialog.dart';
import '../../shared/widgets/dialogs/form_dialog.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/empty_state.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/filters/filter_bar.dart';
import '../../shared/widgets/forms/file_dropzone.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_field.dart';
import '../../shared/widgets/forms/ya_input.dart';
import '../../shared/widgets/forms/ya_select.dart';
import '../../shared/widgets/forms/ya_textarea.dart';
import '../../shared/widgets/table/cells.dart';
import '../../shared/widgets/table/data_table.dart';
import '../../shared/widgets/table/row_context_menu.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/mock_partner_data.dart';
import '../data/mock_types.dart';

String partnerFormatInt(num value) {
  return NumberFormat.decimalPattern('pt_PT')
      .format(value)
      .replaceAll(String.fromCharCode(160), ' ');
}

String partnerCompactMoney(num value) {
  if (value >= 1000000) {
    final double millions = value / 1000000;
    return '${millions.toStringAsFixed(millions >= 10 ? 0 : 1)}M';
  }
  if (value >= 1000) return '${(value / 1000).round()}K';
  return value.round().toString();
}

String partnerRating(double value) {
  return NumberFormat('0.0', 'pt_PT').format(value);
}

String partnerRelativeWhen(DateTime date) {
  final Duration diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) return 'ha ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'ha ${diff.inHours} h';
  return 'ha ${diff.inDays} d';
}

String partnerShortDate(DateTime? date) {
  if (date == null) return '-';
  return DateFormat('dd/MM/y', 'pt_PT').format(date);
}

void partnerToast(
  BuildContext context,
  String message, {
  StatusVariant variant = StatusVariant.success,
}) {
  final YaColors colors = YaColors.of(context);
  final ({Color bg, Color fg}) palette = switch (variant) {
    StatusVariant.danger => (bg: colors.dangerSubtle, fg: colors.danger),
    StatusVariant.warning => (bg: colors.warningSubtle, fg: colors.warning),
    StatusVariant.info => (bg: colors.infoSubtle, fg: colors.info),
    StatusVariant.success => (bg: colors.successSubtle, fg: colors.success),
    _ => (bg: colors.bgElevated, fg: colors.textPrimary),
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content:
            Text(message, style: YaText.smMedium.copyWith(color: palette.fg)),
        backgroundColor: palette.bg,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        duration: const Duration(seconds: 3),
      ),
    );
}

class PartnerCard extends StatelessWidget {
  const PartnerCard({
    required this.child,
    this.padding = YaSpacing.cardMd,
    this.borderColor,
    this.backgroundColor,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.bgSurface,
        borderRadius: YaRadius.brLg,
        border: Border.all(color: borderColor ?? colors.borderSubtle),
        boxShadow: isLight ? YaShadows.sm : YaShadows.none,
      ),
      child: child,
    );
  }
}

class PartnerSectionTitle extends StatelessWidget {
  const PartnerSectionTitle({
    required this.title,
    this.action,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: YaText.smMedium.copyWith(color: colors.textPrimary),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: YaText.sans(size: 12, height: 16)
                      .copyWith(color: colors.textMuted),
                ),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class FleetSummaryCard extends ConsumerWidget {
  const FleetSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final YaColors colors = YaColors.of(context);
    final int driversCount = ref.watch(driversProvider).maybeWhen(
          data: (List<MockDriver> drivers) => drivers.length,
          orElse: () => 0,
        );
    final int vehiclesCount = ref.watch(vehiclesProvider).maybeWhen(
          data: (List<MockVehicle> vehicles) => vehicles.length,
          orElse: () => 0,
        );
    final MockPartnerProfile? profile =
        ref.watch(partnerProfileProvider).value;
    final String fleetName = profile?.fleetName ?? MockPartner.fleetName;
    final String fleetCity = profile?.city ?? MockPartner.city;
    return PartnerCard(
      padding: const EdgeInsets.all(YaSpacing.lg),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact =
              constraints.maxWidth.isFinite && constraints.maxWidth < 720;
          final Widget identity = Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.brandSubtle,
                  borderRadius: YaRadius.brMd,
                ),
                child: Icon(
                  LucideIcons.building2,
                  size: 18,
                  color: colors.brand,
                ),
              ),
              const SizedBox(width: YaSpacing.md),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      fleetName,
                      style:
                          YaText.mdMedium.copyWith(color: colors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      fleetCity,
                      style: YaText.sans(size: 12, height: 16)
                          .copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          );
          final Widget stats = Text(
            '$vehiclesCount viaturas · $driversCount drivers · '
            '${partnerCompactMoney(1250000)} MTn este mes',
            style: YaText.smMedium.copyWith(color: colors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                identity,
                const SizedBox(height: YaSpacing.md),
                stats,
              ],
            );
          }
          return Row(
            children: <Widget>[
              Expanded(child: identity),
              const SizedBox(width: YaSpacing.lg),
              stats,
            ],
          );
        },
      ),
    );
  }
}

StatusBadge driverBadge(MockDriver driver) {
  return StatusBadge.fromMapping(
    YaStatus.fromDriverStatus(driver.status.key, online: driver.online),
  );
}

StatusBadge vehicleBadge(MockVehicle vehicle) {
  return StatusBadge.fromMapping(
    YaStatus.fromVehicleStatus(vehicle.status.key),
  );
}

class OnlineDot extends StatelessWidget {
  const OnlineDot({required this.online, super.key});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    final Color color = online ? colors.success : colors.neutral;
    final Widget dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth.isFinite && constraints.maxWidth < 76) {
          return Center(child: dot);
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            dot,
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                online ? 'Online' : 'Offline',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: YaText.sans(size: 12, height: 16)
                    .copyWith(color: colors.textSecondary),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DriversTableSection extends ConsumerStatefulWidget {
  const DriversTableSection({
    this.showHeaderAction = false,
    this.standalone = false,
    super.key,
  });

  final bool showHeaderAction;
  final bool standalone;

  @override
  ConsumerState<DriversTableSection> createState() =>
      _DriversTableSectionState();
}

class _DriversTableSectionState extends ConsumerState<DriversTableSection> {
  final TextEditingController _searchController = TextEditingController();
  String _activeChip = 'all';
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FilterChipSpec> _chipsFor(List<MockDriver> drivers) {
    return <FilterChipSpec>[
      FilterChipSpec(id: 'all', label: 'Todos', count: drivers.length),
      FilterChipSpec(
        id: 'active',
        label: 'Activos',
        count: drivers
            .where(
              (MockDriver driver) => driver.status == MockDriverStatus.active,
            )
            .length,
        variant: StatusVariant.success,
      ),
      FilterChipSpec(
        id: 'pending',
        label: 'Pendentes',
        count: drivers
            .where(
              (MockDriver driver) => driver.status == MockDriverStatus.pending,
            )
            .length,
        variant: StatusVariant.warning,
      ),
      FilterChipSpec(
        id: 'suspended',
        label: 'Suspensos',
        count: drivers
            .where(
              (MockDriver driver) =>
                  driver.status == MockDriverStatus.suspended,
            )
            .length,
        variant: StatusVariant.danger,
      ),
      FilterChipSpec(
        id: 'online',
        label: 'Online',
        count: drivers.where((MockDriver driver) => driver.online).length,
        variant: StatusVariant.info,
      ),
      FilterChipSpec(
        id: 'low_rating',
        label: 'Rating baixo',
        count: drivers.where((MockDriver driver) => driver.rating < 4).length,
        variant: StatusVariant.warning,
      ),
    ];
  }

  List<MockDriver> _filteredFrom(List<MockDriver> source) {
    final String q = _query.trim().toLowerCase();
    return source.where((MockDriver driver) {
      final bool chipOk = switch (_activeChip) {
        'active' => driver.status == MockDriverStatus.active,
        'pending' => driver.status == MockDriverStatus.pending,
        'suspended' => driver.status == MockDriverStatus.suspended,
        'online' => driver.online,
        'low_rating' => driver.rating < 4,
        _ => true,
      };
      if (!chipOk) return false;
      if (q.isEmpty) return true;
      return driver.name.toLowerCase().contains(q) ||
          driver.phone.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<MockDriver>> driversAsync =
        ref.watch(driversProvider);
    final AsyncValue<List<MockVehicle>> vehiclesAsync =
        ref.watch(vehiclesProvider);

    return AsyncView<List<MockDriver>>(
      value: driversAsync,
      onRetry: () => ref.invalidate(driversProvider),
      data: (List<MockDriver> drivers) => AsyncView<List<MockVehicle>>(
        value: vehiclesAsync,
        onRetry: () => ref.invalidate(vehiclesProvider),
        data: (List<MockVehicle> vehicles) {
          final List<MockDriver> filtered = _filteredFrom(drivers);

          return RepaintBoundary(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FilterBar(
                  chips: _chipsFor(drivers),
                  activeChipId: _activeChip,
                  onChipSelected: (String id) =>
                      setState(() => _activeChip = id),
                  searchController: _searchController,
                  searchPlaceholder: 'Pesquisar por nome ou telefone...',
                  onSearchChanged: (String value) =>
                      setState(() => _query = value),
                ),
                const SizedBox(height: YaSpacing.lg),
                YaDataTable<MockDriver>(
                  columns: <YaColumn<MockDriver>>[
                    YaColumn<MockDriver>(
                      key: 'driver',
                      label: 'Driver',
                      width: 220,
                      cellBuilder: (MockDriver row) =>
                          PersonCell(name: row.name, subtitle: row.phone),
                    ),
                    const YaColumn<MockDriver>(
                      key: 'status',
                      label: 'Status',
                      width: 145,
                      cellBuilder: driverBadge,
                    ),
                    YaColumn<MockDriver>(
                      key: 'online',
                      label: 'Online',
                      width: 90,
                      cellBuilder: (MockDriver row) =>
                          OnlineDot(online: row.online),
                    ),
                    YaColumn<MockDriver>(
                      key: 'vehicle',
                      label: 'Veiculo',
                      width: 120,
                      cellBuilder: (MockDriver row) {
                        final MockVehicle? vehicle = row.vehicleId == null
                            ? null
                            : vehicles
                                .where((MockVehicle v) => v.id == row.vehicleId)
                                .cast<MockVehicle?>()
                                .firstWhere((_) => true, orElse: () => null);
                        return vehicle == null
                            ? const TextCell('-', muted: true)
                            : PlateCell(vehicle.plate);
                      },
                    ),
                    YaColumn<MockDriver>(
                      key: 'rating',
                      label: 'Rating',
                      width: 120,
                      cellBuilder: (MockDriver row) => TextCell(
                        '${partnerRating(row.rating)} (${row.ratingsCount})',
                      ),
                    ),
                    YaColumn<MockDriver>(
                      key: 'trips',
                      label: 'Corridas',
                      width: 90,
                      align: Alignment.centerRight,
                      cellBuilder: (MockDriver row) =>
                          NumericCell(partnerFormatInt(row.tripsCount)),
                    ),
                    YaColumn<MockDriver>(
                      key: 'earnings',
                      label: 'Total ganho',
                      width: 130,
                      align: Alignment.centerRight,
                      cellBuilder: (MockDriver row) => MoneyCell(
                        amount: partnerFormatInt(row.totalEarningsMtn),
                      ),
                    ),
                    YaColumn<MockDriver>(
                      key: 'more',
                      label: '',
                      width: 48,
                      cellBuilder: (MockDriver row) => RowContextMenu(
                        items: <Object>[
                          YaMenuItem(
                            label: 'Ver perfil',
                            icon: LucideIcons.eye,
                            onTap: () =>
                                context.go('/partner/fleet/driver/${row.id}'),
                          ),
                          YaMenuItem(
                            label: 'Mensagem',
                            icon: LucideIcons.mail,
                            onTap: () => context.go('/partner/messages'),
                          ),
                          const YaMenuDivider(),
                          YaMenuItem(
                            label: row.status == MockDriverStatus.suspended
                                ? 'Reactivar'
                                : 'Suspender',
                            icon: row.status == MockDriverStatus.suspended
                                ? LucideIcons.rotateCcw
                                : LucideIcons.ban,
                            destructive:
                                row.status != MockDriverStatus.suspended,
                            disabled: row.status == MockDriverStatus.pending,
                            onTap: () =>
                                partnerToast(context, 'Acção registada'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  rows: filtered,
                  keyExtractor: (MockDriver row) => row.id,
                  onRowTap: (MockDriver row) =>
                      context.go('/partner/fleet/driver/${row.id}'),
                  emptyIcon: LucideIcons.users,
                  emptyTitle: 'Sem motoristas',
                  emptyDescription:
                      'Ajusta a pesquisa ou filtros para veres resultados.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class VehiclesTableSection extends ConsumerStatefulWidget {
  const VehiclesTableSection({super.key});

  @override
  ConsumerState<VehiclesTableSection> createState() =>
      _VehiclesTableSectionState();
}

class _VehiclesTableSectionState extends ConsumerState<VehiclesTableSection> {
  final TextEditingController _searchController = TextEditingController();
  String _activeChip = 'all';
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FilterChipSpec> _chipsFor(List<MockVehicle> vehicles) {
    return <FilterChipSpec>[
      FilterChipSpec(id: 'all', label: 'Todos', count: vehicles.length),
      FilterChipSpec(
        id: 'available',
        label: 'Disponiveis',
        count: vehicles
            .where(
              (MockVehicle vehicle) =>
                  vehicle.status == MockVehicleStatus.available,
            )
            .length,
        variant: StatusVariant.success,
      ),
      FilterChipSpec(
        id: 'busy',
        label: 'Em uso',
        count: vehicles
            .where(
              (MockVehicle vehicle) => vehicle.status == MockVehicleStatus.busy,
            )
            .length,
        variant: StatusVariant.warning,
      ),
      FilterChipSpec(
        id: 'maintenance',
        label: 'Manutencao',
        count: vehicles
            .where(
              (MockVehicle vehicle) =>
                  vehicle.status == MockVehicleStatus.maintenance,
            )
            .length,
        variant: StatusVariant.neutral,
      ),
      FilterChipSpec(
        id: 'assigned',
        label: 'Atribuidos',
        count: vehicles
            .where((MockVehicle vehicle) => vehicle.driverId != null)
            .length,
      ),
      FilterChipSpec(
        id: 'unassigned',
        label: 'Sem driver',
        count: vehicles
            .where((MockVehicle vehicle) => vehicle.driverId == null)
            .length,
      ),
    ];
  }

  List<MockVehicle> _filteredFrom(List<MockVehicle> source) {
    final String q = _query.trim().toLowerCase();
    return source.where((MockVehicle vehicle) {
      final bool chipOk = switch (_activeChip) {
        'available' => vehicle.status == MockVehicleStatus.available,
        'busy' => vehicle.status == MockVehicleStatus.busy,
        'maintenance' => vehicle.status == MockVehicleStatus.maintenance,
        'assigned' => vehicle.driverId != null,
        'unassigned' => vehicle.driverId == null,
        _ => true,
      };
      if (!chipOk) return false;
      if (q.isEmpty) return true;
      return vehicle.plate.toLowerCase().contains(q) ||
          vehicle.model.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<MockVehicle>> vehiclesAsync =
        ref.watch(vehiclesProvider);
    final AsyncValue<List<MockDriver>> driversAsync =
        ref.watch(driversProvider);

    return AsyncView<List<MockVehicle>>(
      value: vehiclesAsync,
      onRetry: () => ref.invalidate(vehiclesProvider),
      data: (List<MockVehicle> vehicles) => AsyncView<List<MockDriver>>(
        value: driversAsync,
        onRetry: () => ref.invalidate(driversProvider),
        data: (List<MockDriver> drivers) {
          final List<MockVehicle> filtered = _filteredFrom(vehicles);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FilterBar(
                chips: _chipsFor(vehicles),
                activeChipId: _activeChip,
                onChipSelected: (String id) => setState(() => _activeChip = id),
                searchController: _searchController,
                searchPlaceholder: 'Pesquisar por matricula ou modelo...',
                onSearchChanged: (String value) =>
                    setState(() => _query = value),
              ),
              const SizedBox(height: YaSpacing.lg),
              YaDataTable<MockVehicle>(
                columns: <YaColumn<MockVehicle>>[
                  YaColumn<MockVehicle>(
                    key: 'photo',
                    label: 'Foto',
                    width: 58,
                    cellBuilder: (MockVehicle row) =>
                        const VehiclePhoto(size: 36),
                  ),
                  YaColumn<MockVehicle>(
                    key: 'plate',
                    label: 'Matricula',
                    width: 120,
                    cellBuilder: (MockVehicle row) => PlateCell(row.plate),
                  ),
                  YaColumn<MockVehicle>(
                    key: 'model',
                    label: 'Modelo',
                    width: 190,
                    cellBuilder: (MockVehicle row) =>
                        TextCell('${row.model} · ${row.year}'),
                  ),
                  YaColumn<MockVehicle>(
                    key: 'type',
                    label: 'Tipo',
                    width: 120,
                    cellBuilder: (MockVehicle row) => StatusBadge(
                      variant: StatusVariant.neutral,
                      label: row.type,
                      dot: false,
                      size: StatusBadgeSize.sm,
                    ),
                  ),
                  YaColumn<MockVehicle>(
                    key: 'seats',
                    label: 'Lugares',
                    width: 80,
                    cellBuilder: (MockVehicle row) => NumericCell(
                      row.seats.toString(),
                      alignEnd: false,
                    ),
                  ),
                  YaColumn<MockVehicle>(
                    key: 'driver',
                    label: 'Driver actual',
                    width: 180,
                    cellBuilder: (MockVehicle row) {
                      final MockDriver? driver = row.driverId == null
                          ? null
                          : drivers.cast<MockDriver?>().firstWhere(
                                (MockDriver? d) => d!.id == row.driverId,
                                orElse: () => null,
                              );
                      return driver == null
                          ? const TextCell('-', muted: true)
                          : PersonCell(
                              name: driver.name,
                              subtitle: '',
                              avatarSize: 24,
                            );
                    },
                  ),
                  const YaColumn<MockVehicle>(
                    key: 'status',
                    label: 'Status',
                    width: 135,
                    cellBuilder: vehicleBadge,
                  ),
                  YaColumn<MockVehicle>(
                    key: 'more',
                    label: '',
                    width: 48,
                    cellBuilder: (MockVehicle row) => RowContextMenu(
                      items: <Object>[
                        YaMenuItem(
                          label: 'Ver detalhe',
                          icon: LucideIcons.eye,
                          onTap: () =>
                              context.go('/partner/fleet/vehicle/${row.id}'),
                        ),
                        YaMenuItem(
                          label: 'Atribuir driver',
                          icon: LucideIcons.userPlus,
                          onTap: () => partnerToast(
                            context,
                            'Dialog de atribuição aberto',
                          ),
                        ),
                        const YaMenuDivider(),
                        YaMenuItem(
                          label: row.status == MockVehicleStatus.maintenance
                              ? 'Marcar disponivel'
                              : 'Marcar manutencao',
                          icon: LucideIcons.wrench,
                          onTap: () =>
                              partnerToast(context, 'Estado actualizado'),
                        ),
                      ],
                    ),
                  ),
                ],
                rows: filtered,
                keyExtractor: (MockVehicle row) => row.id,
                onRowTap: (MockVehicle row) =>
                    context.go('/partner/fleet/vehicle/${row.id}'),
                emptyIcon: LucideIcons.car,
                emptyTitle: 'Sem veiculos',
                emptyDescription:
                    'Ajusta a pesquisa ou filtros para veres resultados.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class VehiclePhoto extends StatelessWidget {
  const VehiclePhoto({this.size = 48, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.bgSubtle,
        borderRadius: YaRadius.brMd,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Icon(LucideIcons.car, size: size * 0.45, color: colors.textMuted),
    );
  }
}

class TripsTableSection extends ConsumerStatefulWidget {
  const TripsTableSection({
    this.driverId,
    this.vehicleId,
    this.pageSize = 25,
    this.compact = false,
    super.key,
  });

  final String? driverId;
  final String? vehicleId;
  final int pageSize;
  final bool compact;

  @override
  ConsumerState<TripsTableSection> createState() => _TripsTableSectionState();
}

class _TripsTableSectionState extends ConsumerState<TripsTableSection> {
  final TextEditingController _searchController = TextEditingController();
  String _activeChip = 'all';
  String _query = '';
  int _page = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MockTrip> _sourceFor(List<MockTrip> allTrips) {
    if (widget.driverId != null) {
      return allTrips
          .where((MockTrip t) => t.driverId == widget.driverId)
          .toList();
    }
    if (widget.vehicleId != null) {
      return allTrips
          .where((MockTrip t) => t.vehicleId == widget.vehicleId)
          .toList();
    }
    final List<MockTrip> sorted = <MockTrip>[...allTrips]
      ..sort((MockTrip a, MockTrip b) => b.startedAt.compareTo(a.startedAt));
    return sorted;
  }

  List<FilterChipSpec> _chipsFor(List<MockTrip> source) {
    return <FilterChipSpec>[
      FilterChipSpec(id: 'all', label: 'Todas', count: source.length),
      FilterChipSpec(
        id: 'started',
        label: 'A decorrer',
        count: source
            .where((MockTrip trip) => trip.status == MockTripStatus.started)
            .length,
        variant: StatusVariant.warning,
      ),
      FilterChipSpec(
        id: 'completed',
        label: 'Completas',
        count: source
            .where((MockTrip trip) => trip.status == MockTripStatus.completed)
            .length,
        variant: StatusVariant.success,
      ),
      FilterChipSpec(
        id: 'cancelled',
        label: 'Canceladas',
        count: source
            .where((MockTrip trip) => trip.status == MockTripStatus.cancelled)
            .length,
        variant: StatusVariant.danger,
      ),
      FilterChipSpec(
        id: 'accepted',
        label: 'Aceites',
        count: source
            .where((MockTrip trip) => trip.status == MockTripStatus.accepted)
            .length,
        variant: StatusVariant.info,
      ),
    ];
  }

  List<MockTrip> _filteredFrom(
    List<MockTrip> source,
    List<MockDriver> drivers,
    List<MockVehicle> vehicles,
  ) {
    final String q = _query.trim().toLowerCase();
    return source.where((MockTrip trip) {
      final bool chipOk =
          _activeChip == 'all' || trip.status.key == _activeChip;
      if (!chipOk) return false;
      if (q.isEmpty) return true;
      final MockDriver? driver = drivers.cast<MockDriver?>().firstWhere(
            (MockDriver? d) => d!.id == trip.driverId,
            orElse: () => null,
          );
      final MockVehicle? vehicle = vehicles.cast<MockVehicle?>().firstWhere(
            (MockVehicle? v) => v!.id == trip.vehicleId,
            orElse: () => null,
          );
      return trip.id.toLowerCase().contains(q) ||
          trip.origin.toLowerCase().contains(q) ||
          trip.destination.toLowerCase().contains(q) ||
          (driver?.name.toLowerCase().contains(q) ?? false) ||
          (vehicle?.plate.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<MockTrip>> tripsAsync = ref.watch(tripsProvider);
    final AsyncValue<List<MockDriver>> driversAsync =
        ref.watch(driversProvider);
    final AsyncValue<List<MockVehicle>> vehiclesAsync =
        ref.watch(vehiclesProvider);

    return AsyncView<List<MockTrip>>(
      value: tripsAsync,
      onRetry: () => ref.invalidate(tripsProvider),
      data: (List<MockTrip> allTrips) => AsyncView<List<MockDriver>>(
        value: driversAsync,
        onRetry: () => ref.invalidate(driversProvider),
        data: (List<MockDriver> drivers) => AsyncView<List<MockVehicle>>(
          value: vehiclesAsync,
          onRetry: () => ref.invalidate(vehiclesProvider),
          data: (List<MockVehicle> vehicles) {
            final List<MockTrip> source = _sourceFor(allTrips);
            final List<MockTrip> filtered =
                _filteredFrom(source, drivers, vehicles);
            final int totalPages = filtered.isEmpty
                ? 1
                : (filtered.length / widget.pageSize).ceil();
            final int start = ((_page - 1) * widget.pageSize)
                .clamp(0, filtered.length)
                .toInt();
            final int end =
                (start + widget.pageSize).clamp(0, filtered.length).toInt();
            final List<MockTrip> pageRows = filtered.sublist(start, end);

            MockDriver? driverById(String id) =>
                drivers.cast<MockDriver?>().firstWhere(
                      (MockDriver? d) => d!.id == id,
                      orElse: () => null,
                    );
            MockVehicle? vehicleById(String id) =>
                vehicles.cast<MockVehicle?>().firstWhere(
                      (MockVehicle? v) => v!.id == id,
                      orElse: () => null,
                    );

            return RepaintBoundary(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (!widget.compact) ...<Widget>[
                    FilterBar(
                      chips: _chipsFor(source),
                      activeChipId: _activeChip,
                      onChipSelected: (String id) => setState(() {
                        _activeChip = id;
                        _page = 1;
                      }),
                      searchController: _searchController,
                      searchPlaceholder: 'Pesquisar por ID, origem, destino...',
                      onSearchChanged: (String value) => setState(() {
                        _query = value;
                        _page = 1;
                      }),
                    ),
                    const SizedBox(height: YaSpacing.lg),
                  ],
                  YaDataTable<MockTrip>(
                    density: YaTableDensity.compact,
                    columns: <YaColumn<MockTrip>>[
                      YaColumn<MockTrip>(
                        key: 'id',
                        label: 'Trip ID',
                        width: 120,
                        cellBuilder: (MockTrip row) => IdCell(row.id),
                      ),
                      YaColumn<MockTrip>(
                        key: 'route',
                        label: 'Origem -> Destino',
                        cellBuilder: (MockTrip row) =>
                            RouteCell(from: row.origin, to: row.destination),
                      ),
                      YaColumn<MockTrip>(
                        key: 'driver',
                        label: 'Driver',
                        width: 180,
                        cellBuilder: (MockTrip row) {
                          final MockDriver? driver = driverById(row.driverId);
                          return PersonCell(
                            name: driver?.name ?? row.driverId,
                            subtitle: '',
                          );
                        },
                      ),
                      YaColumn<MockTrip>(
                        key: 'vehicle',
                        label: 'Veiculo',
                        width: 120,
                        cellBuilder: (MockTrip row) => PlateCell(
                          vehicleById(row.vehicleId)?.plate ?? row.vehicleId,
                        ),
                      ),
                      YaColumn<MockTrip>(
                        key: 'amount',
                        label: 'Valor',
                        width: 120,
                        align: Alignment.centerRight,
                        cellBuilder: (MockTrip row) => MoneyCell(
                          amount: partnerFormatInt(row.partnerNetMtn),
                        ),
                      ),
                      YaColumn<MockTrip>(
                        key: 'status',
                        label: 'Status',
                        width: 130,
                        cellBuilder: (MockTrip row) => StatusBadge.fromMapping(
                          YaStatus.fromTripStatus(row.status.key),
                          size: StatusBadgeSize.sm,
                        ),
                      ),
                      YaColumn<MockTrip>(
                        key: 'when',
                        label: 'Quando',
                        width: 105,
                        cellBuilder: (MockTrip row) =>
                            WhenCell(partnerRelativeWhen(row.startedAt)),
                      ),
                      YaColumn<MockTrip>(
                        key: 'more',
                        label: '',
                        width: 48,
                        cellBuilder: (MockTrip row) => RowContextMenu(
                          items: <Object>[
                            YaMenuItem(
                              label: 'Ver detalhe',
                              icon: LucideIcons.eye,
                              onTap: () =>
                                  context.go('/partner/trips/${row.id}'),
                            ),
                            YaMenuItem(
                              label: 'Copiar ID',
                              icon: LucideIcons.copy,
                              onTap: () => partnerToast(context, 'ID copiado'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    rows: widget.compact
                        ? filtered.take(widget.pageSize).toList()
                        : pageRows,
                    keyExtractor: (MockTrip row) => row.id,
                    onRowTap: (MockTrip row) =>
                        context.go('/partner/trips/${row.id}'),
                    emptyIcon: LucideIcons.route,
                    emptyTitle: 'Sem corridas',
                    emptyDescription:
                        'Ajusta os filtros para encontrares corridas.',
                    footer: widget.compact
                        ? null
                        : YaTablePagination(
                            currentPage: _page,
                            totalPages: totalPages,
                            onPageChange: (int page) =>
                                setState(() => _page = page),
                            summary:
                                'A mostrar ${pageRows.length} de ${filtered.length} corridas',
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

void openInviteDriverDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => const _InviteDriverDialog(),
  );
}

void openAddVehicleDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => const _AddVehicleDialog(),
  );
}

/// Convidar motorista por telefone (chama a Cloud Function `inviteDriver`).
class _InviteDriverDialog extends ConsumerStatefulWidget {
  const _InviteDriverDialog();

  @override
  ConsumerState<_InviteDriverDialog> createState() =>
      _InviteDriverDialogState();
}

class _InviteDriverDialogState extends ConsumerState<_InviteDriverDialog> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String phone = _phone.text.trim();
    if (phone.replaceAll(RegExp(r'\D'), '').length < 9) {
      setState(() => _error = 'Introduz um telefone válido.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final repo = ref.read(partnerDataRepositoryProvider);
      final String status =
          await ref.read(cloudFunctionsServiceProvider).inviteDriver(
                partnerId: repo.partnerId,
                phone: phone,
                name: _name.text.trim().isEmpty ? null : _name.text.trim(),
              );
      if (!mounted) return;
      ref.invalidate(driversProvider);
      ref.invalidate(driversStreamProvider);
      Navigator.of(context).pop();
      partnerToast(
        context,
        status == 'linked'
            ? 'Motorista vinculado à frota'
            : 'Convite criado · aplicado quando o motorista entrar na app',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Não foi possível convidar o motorista. Tenta novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Convidar motorista',
      description:
          'Indica o telefone. Se já tiver conta, é vinculado de imediato; '
          'caso contrário o vínculo é aplicado no primeiro login.',
      confirmLabel: 'Enviar convite',
      submitting: _submitting,
      errorBanner: _error,
      onConfirm: _submit,
      children: <Widget>[
        YaField(
          label: 'Nome (opcional)',
          child: YaInput(controller: _name, placeholder: 'Nome completo'),
        ),
        YaField(
          label: 'Telefone',
          child: YaInput(
            controller: _phone,
            placeholder: '+258 84 000 0000',
            keyboardType: TextInputType.phone,
          ),
        ),
      ],
    );
  }
}

/// Adicionar veículo à frota do partner (escreve em `partners/{pid}/vehicles`).
class _AddVehicleDialog extends ConsumerStatefulWidget {
  const _AddVehicleDialog();

  @override
  ConsumerState<_AddVehicleDialog> createState() => _AddVehicleDialogState();
}

class _AddVehicleDialogState extends ConsumerState<_AddVehicleDialog> {
  final TextEditingController _plate = TextEditingController();
  final TextEditingController _model = TextEditingController();
  final TextEditingController _year = TextEditingController();
  final TextEditingController _type = TextEditingController();
  final TextEditingController _seats = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _plate.dispose();
    _model.dispose();
    _year.dispose();
    _type.dispose();
    _seats.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String plate = _plate.text.trim();
    final String model = _model.text.trim();
    if (plate.isEmpty || model.isEmpty) {
      setState(() => _error = 'Matrícula e modelo são obrigatórios.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(partnerDataRepositoryProvider).createVehicle(
            plate: plate,
            model: model,
            type: _type.text.trim().isEmpty ? 'Sedan' : _type.text.trim(),
            year: int.tryParse(_year.text.trim()) ?? DateTime.now().year,
            seats: int.tryParse(_seats.text.trim()) ?? 5,
          );
      if (!mounted) return;
      ref.invalidate(vehiclesProvider);
      ref.invalidate(vehiclesStreamProvider);
      Navigator.of(context).pop();
      partnerToast(context, 'Veículo adicionado');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Não foi possível adicionar o veículo. Tenta novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Adicionar veículo',
      description: 'A frota é ${MockPartner.fleetName}.',
      confirmLabel: 'Adicionar veículo',
      submitting: _submitting,
      errorBanner: _error,
      onConfirm: _submit,
      children: <Widget>[
        YaField(
          label: 'Matrícula',
          child: YaInput(controller: _plate, placeholder: 'AAA-123-MP'),
        ),
        YaField(
          label: 'Modelo',
          child: YaInput(controller: _model, placeholder: 'Toyota Corolla'),
        ),
        YaField(
          label: 'Ano',
          child: YaInput(
            controller: _year,
            placeholder: '2022',
            keyboardType: TextInputType.number,
          ),
        ),
        YaField(
          label: 'Tipo',
          child: YaInput(controller: _type, placeholder: 'Sedan'),
        ),
        YaField(
          label: 'Lugares',
          child: YaInput(
            controller: _seats,
            placeholder: '5',
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }
}

void openUploadDocumentDialog(BuildContext context, String title) {
  showDialog<void>(
    context: context,
    builder: (BuildContext _) => _UploadDocumentDialog(title: title),
  );
}

class _UploadDocumentDialog extends ConsumerStatefulWidget {
  const _UploadDocumentDialog({required this.title});

  final String title;

  @override
  ConsumerState<_UploadDocumentDialog> createState() =>
      _UploadDocumentDialogState();
}

class _UploadDocumentDialogState extends ConsumerState<_UploadDocumentDialog> {
  final TextEditingController _expiry = TextEditingController();
  Uint8List? _bytes;
  String? _fileName;
  bool _busy = false;

  @override
  void dispose() {
    _expiry.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    final PlatformFile? file = result?.files.firstOrNull;
    if (file == null || file.bytes == null) return;
    if (file.size > 5 * 1024 * 1024) {
      if (mounted) {
        partnerToast(
          context,
          'Ficheiro demasiado grande (máx. 5MB).',
          variant: StatusVariant.danger,
        );
      }
      return;
    }
    setState(() {
      _bytes = file.bytes;
      _fileName = file.name;
    });
  }

  DateTime? _parseExpiry() {
    final String raw = _expiry.text.trim();
    if (raw.isEmpty) return null;
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    final Uint8List? bytes = _bytes;
    final String? fileName = _fileName;
    if (bytes == null || fileName == null) {
      partnerToast(
        context,
        'Seleciona um ficheiro primeiro.',
        variant: StatusVariant.danger,
      );
      return;
    }
    if (_expiry.text.trim().isNotEmpty && _parseExpiry() == null) {
      partnerToast(
        context,
        'Data inválida (usa DD/MM/AAAA).',
        variant: StatusVariant.danger,
      );
      return;
    }
    final AuthUser? user = ref.read(authStateProvider);
    final String? partnerId = user?.partnerId;
    if (partnerId == null) {
      partnerToast(
        context,
        'Sessão sem partner associado.',
        variant: StatusVariant.danger,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(storageServiceProvider).uploadDocument(
            bytes: bytes,
            ownerType: 'partner',
            ownerId: partnerId,
            docType: widget.title,
            filename: fileName,
            expiresAt: _parseExpiry(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      partnerToast(context, 'Documento enviado · aguarda aprovação');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      partnerToast(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Carregar ${widget.title}',
      confirmLabel: 'Guardar',
      submitting: _busy,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _submit,
      children: <Widget>[
        FileDropzone(
          label: _fileName == null ? 'Selecionar ficheiro' : 'Ficheiro pronto',
          subtitle: 'PDF, JPG ou PNG ate 5MB',
          state: _fileName == null
              ? FileDropzoneState.idle
              : FileDropzoneState.success,
          fileName: _fileName,
          onTap: _pickFile,
          onClear: () => setState(() {
            _bytes = null;
            _fileName = null;
          }),
        ),
        YaField(
          label: 'Data de expiração',
          child: YaInput(controller: _expiry, placeholder: 'DD/MM/AAAA'),
        ),
      ],
    );
  }
}

void openAssignVehicleDialog(BuildContext context, MockDriver driver) {
  showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => _AssignVehicleDialog(driver),
  );
}

void openAssignDriverDialog(BuildContext context, MockVehicle vehicle) {
  showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => _AssignDriverDialog(vehicle),
  );
}

/// Atribui um veículo (sem motorista) ao [driver] via `assignVehicle`.
class _AssignVehicleDialog extends ConsumerStatefulWidget {
  const _AssignVehicleDialog(this.driver);

  final MockDriver driver;

  @override
  ConsumerState<_AssignVehicleDialog> createState() =>
      _AssignVehicleDialogState();
}

class _AssignVehicleDialogState extends ConsumerState<_AssignVehicleDialog> {
  String? _selected;
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    if (_selected == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final repo = ref.read(partnerDataRepositoryProvider);
      await ref.read(cloudFunctionsServiceProvider).assignVehicle(
            partnerId: repo.partnerId,
            vehicleId: _selected!,
            driverUid: widget.driver.id,
          );
      if (!mounted) return;
      ref.invalidate(vehiclesProvider);
      ref.invalidate(vehiclesStreamProvider);
      ref.invalidate(driversProvider);
      ref.invalidate(driversStreamProvider);
      Navigator.of(context).pop();
      partnerToast(context, 'Veículo atribuído a ${widget.driver.name}');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Não foi possível atribuir o veículo. Tenta novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<MockVehicle> available =
        (ref.watch(vehiclesProvider).value ?? const <MockVehicle>[])
            .where((MockVehicle v) => v.driverId == null)
            .toList();
    _selected ??= available.isEmpty ? null : available.first.id;

    return FormDialog(
      title: 'Atribuir veículo',
      description: 'Escolhe um veículo sem motorista atribuído.',
      confirmLabel: 'Atribuir',
      submitting: _submitting,
      errorBanner: _error,
      confirmDisabled: _selected == null,
      onConfirm: _submit,
      children: <Widget>[
        if (available.isEmpty)
          const EmptyState(
            icon: LucideIcons.car,
            title: 'Sem veículos disponíveis',
            description: 'Todos os veículos desta frota já têm driver.',
          )
        else
          YaField(
            label: 'Veículo',
            child: YaSelect<String>(
              value: _selected,
              items: <YaSelectItem<String>>[
                for (final MockVehicle vehicle in available)
                  YaSelectItem<String>(
                    value: vehicle.id,
                    label: '${vehicle.plate} · ${vehicle.model}',
                  ),
              ],
              onChanged: (String value) => setState(() => _selected = value),
            ),
          ),
      ],
    );
  }
}

/// Atribui um motorista (sem veículo) ao [vehicle] via `assignVehicle`.
class _AssignDriverDialog extends ConsumerStatefulWidget {
  const _AssignDriverDialog(this.vehicle);

  final MockVehicle vehicle;

  @override
  ConsumerState<_AssignDriverDialog> createState() =>
      _AssignDriverDialogState();
}

class _AssignDriverDialogState extends ConsumerState<_AssignDriverDialog> {
  String? _selected;
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    if (_selected == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final repo = ref.read(partnerDataRepositoryProvider);
      await ref.read(cloudFunctionsServiceProvider).assignVehicle(
            partnerId: repo.partnerId,
            vehicleId: widget.vehicle.id,
            driverUid: _selected,
          );
      if (!mounted) return;
      ref.invalidate(vehiclesProvider);
      ref.invalidate(vehiclesStreamProvider);
      ref.invalidate(driversProvider);
      ref.invalidate(driversStreamProvider);
      Navigator.of(context).pop();
      partnerToast(context, 'Driver atribuído a ${widget.vehicle.plate}');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Não foi possível atribuir o motorista. Tenta novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<MockDriver> available =
        (ref.watch(driversProvider).value ?? const <MockDriver>[])
            .where((MockDriver d) => d.vehicleId == null)
            .toList();
    _selected ??= available.isEmpty ? null : available.first.id;

    return FormDialog(
      title: 'Atribuir driver',
      description: 'Escolhe um motorista sem veículo atribuído.',
      confirmLabel: 'Atribuir',
      submitting: _submitting,
      errorBanner: _error,
      confirmDisabled: _selected == null,
      onConfirm: _submit,
      children: <Widget>[
        if (available.isEmpty)
          const EmptyState(
            icon: LucideIcons.user,
            title: 'Sem motoristas disponíveis',
            description: 'Todos os motoristas desta frota já têm veículo.',
          )
        else
          YaField(
            label: 'Motorista',
            child: YaSelect<String>(
              value: _selected,
              items: <YaSelectItem<String>>[
                for (final MockDriver driver in available)
                  YaSelectItem<String>(
                    value: driver.id,
                    label: driver.name,
                  ),
              ],
              onChanged: (String value) => setState(() => _selected = value),
            ),
          ),
      ],
    );
  }
}

void openSuspendDriverDialog(BuildContext context, MockDriver driver) {
  showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return ConfirmDialog(
        title: 'Suspender ${driver.name}?',
        description:
            'O driver fica imediatamente offline e deixa de receber corridas.',
        confirmLabel: 'Suspender',
        onCancel: () => Navigator.of(dialogContext).pop(),
        onConfirm: () {
          Navigator.of(dialogContext).pop();
          partnerToast(
            context,
            'Driver suspenso',
            variant: StatusVariant.warning,
          );
        },
        body: const YaField(
          label: 'Motivo da suspensão',
          child: YaTextarea(
            placeholder: 'Ex: Documento expirado e não renovado.',
            minLines: 3,
          ),
        ),
      );
    },
  );
}

void openMaintenanceConfirmDialog(BuildContext context, MockVehicle vehicle) {
  showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return ConfirmDialog(
        title: 'Marcar ${vehicle.plate} em manutenção?',
        description: 'O veículo deixa de estar disponível para novas corridas.',
        confirmLabel: 'Marcar manutenção',
        variant: StatusVariant.warning,
        onCancel: () => Navigator.of(dialogContext).pop(),
        onConfirm: () {
          Navigator.of(dialogContext).pop();
          partnerToast(context, 'Veículo marcado em manutenção');
        },
        body: const YaField(
          label: 'Nota',
          child: YaTextarea(
            placeholder: 'Ex: revisão preventiva',
            minLines: 3,
          ),
        ),
      );
    },
  );
}

void openRegisterMaintenanceDialog(BuildContext context, MockVehicle vehicle) {
  showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return FormDialog(
        title: 'Registar manutenção',
        confirmLabel: 'Registar',
        onCancel: () => Navigator.of(dialogContext).pop(),
        onConfirm: () {
          Navigator.of(dialogContext).pop();
          partnerToast(context, 'Manutenção registada');
        },
        children: const <Widget>[
          YaField(
            label: 'Descrição',
            child: YaTextarea(placeholder: 'Serviço realizado', minLines: 3),
          ),
          YaField(
            label: 'Custo (MTn)',
            child: YaInput(placeholder: '0'),
          ),
          YaField(
            label: 'Realizada em',
            child: YaInput(placeholder: 'DD/MM/AAAA'),
          ),
          YaField(
            label: 'Próxima manutenção',
            child: YaInput(placeholder: 'DD/MM/AAAA'),
          ),
        ],
      );
    },
  );
}

class DocumentCard extends StatelessWidget {
  const DocumentCard({
    required this.title,
    required this.status,
    this.expiresAt,
    this.onTap,
    this.actionLabel,
    super.key,
  });

  final String title;
  final MockDocumentStatus status;
  final DateTime? expiresAt;
  final VoidCallback? onTap;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    final StatusMapping mapping = YaStatus.fromDocStatus(status.key);
    final bool warning = status == MockDocumentStatus.expiringSoon;
    final bool danger = status == MockDocumentStatus.expired;
    final Color borderColor = danger
        ? colors.danger
        : warning
            ? colors.warning
            : colors.borderSubtle;

    final Widget icon = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.bgSubtle,
        borderRadius: YaRadius.brMd,
      ),
      child: Icon(
        danger ? LucideIcons.triangleAlert : LucideIcons.fileText,
        size: 20,
        color: danger ? colors.danger : colors.textMuted,
      ),
    );

    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: YaText.smMedium.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          expiresAt == null
              ? 'Sem expiração'
              : 'Expira em ${partnerShortDate(expiresAt)}',
          style: YaText.sans(size: 12, height: 16)
              .copyWith(color: colors.textSecondary),
        ),
      ],
    );

    final List<Widget> actions = <Widget>[
      StatusBadge.fromMapping(mapping, size: StatusBadgeSize.sm),
      YaButton.ghost(
        label: actionLabel ??
            (status == MockDocumentStatus.missing ? 'Carregar' : 'Substituir'),
        icon: LucideIcons.upload,
        onPressed: onTap,
      ),
    ];

    return PartnerCard(
      borderColor: borderColor,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 460;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    icon,
                    const SizedBox(width: YaSpacing.md),
                    Expanded(child: body),
                  ],
                ),
                const SizedBox(height: YaSpacing.md),
                Wrap(
                  spacing: YaSpacing.sm,
                  runSpacing: YaSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: actions,
                ),
              ],
            );
          }

          return Row(
            children: <Widget>[
              icon,
              const SizedBox(width: YaSpacing.md),
              Expanded(child: body),
              const SizedBox(width: YaSpacing.md),
              Wrap(
                spacing: YaSpacing.sm,
                runSpacing: YaSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: actions,
              ),
            ],
          );
        },
      ),
    );
  }
}

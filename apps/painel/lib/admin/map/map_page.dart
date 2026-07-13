import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/config/map_config.dart';
import '../../data/providers.dart';
import '../../core/constants/status_mapping.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/feedback/live_pill.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/forms/ya_avatar.dart';
import '../../shared/widgets/kpi/kpi_card.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/types.dart';

// === Coordenadas dos bairros de Maputo ===
const _maputoCenter = LatLng(-25.9664, 32.5892);
const _initialZoom = 12.5;
const _minZoom = 9.0;
const _maxZoom = 18.0;
const _zoomStep = 1.0;

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final MapController _mapController = MapController();

  String _activeFilter = 'all';
  String _layer = 'map';
  String _activeTab = 'trips';
  String? _selectedTripId;
  String _search = '';

  final TextEditingController _searchCtrl = TextEditingController();

  // Corridas activas (com rota) e posições live dos drivers — preenchidas
  // em build() a partir dos providers.
  List<AdminTrip> _trips = const <AdminTrip>[];
  List<_DriverMarker> _drivers = const <_DriverMarker>[];
  Map<String, AdminDriver> _driversById = const <String, AdminDriver>{};

  String _tileUrlTemplate(BuildContext context) {
    if (_layer == 'satellite') return MapConfig.satelliteTileUrl;
    if (Theme.of(context).brightness == Brightness.dark) {
      return MapConfig.darkTileUrl;
    }
    return MapConfig.streetsTileUrl;
  }

  List<_DriverMarker> get _filteredDrivers {
    if (_activeFilter == 'all') return _drivers;
    return _drivers.where((d) => d.status == _activeFilter).toList();
  }

  List<AdminTrip> get _filteredTrips {
    if (_search.isEmpty) return _trips;
    final q = _search.toLowerCase();
    return _trips.where((t) {
      return t.id.toLowerCase().contains(q) ||
          (t.origin ?? '').toLowerCase().contains(q) ||
          (t.destination ?? '').toLowerCase().contains(q) ||
          _driverName(t.driverId).toLowerCase().contains(q);
    }).toList();
  }

  String _driverName(String? driverId) {
    if (driverId == null) return '—';
    return _driversById[driverId]?.name ?? driverId;
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _search = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);
    final dateStr = DateFormat("EEEE, d 'de' MMMM", 'pt_PT').format(now);
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final mapAreaHeight = math.max(640.0, viewportHeight - 290.0);

    final allDrivers =
        ref.watch(adminDriversProvider).asData?.value ?? const [];
    final allTrips = ref.watch(adminTripsProvider).asData?.value ?? const [];
    final liveTrips =
        ref.watch(adminActiveTripsForMapProvider).asData?.value ??
            const <AdminTrip>[];
    final liveLocations =
        ref.watch(adminDriverLocationsProvider).asData?.value ??
            const <AdminDriverLocation>[];

    _driversById = {for (final d in allDrivers) d.id: d};
    _trips = liveTrips;
    if (_selectedTripId == null && _trips.isNotEmpty) {
      _selectedTripId = _trips.first.id;
    }

    final busyDriverIds = {
      for (final t in liveTrips)
        if (t.driverId != null &&
            (t.status == 'accepted' || t.status == 'started'))
          t.driverId!,
    };
    _drivers = [
      for (final loc in liveLocations)
        _DriverMarker(
          driverId: loc.driverId,
          point: LatLng(loc.lat, loc.lng),
          status: !loc.online
              ? 'offline'
              : busyDriverIds.contains(loc.driverId)
                  ? 'busy'
                  : 'available',
        ),
    ];

    final onlineDrivers = allDrivers.where((d) => d.online).length;
    final activeTrips = allTrips.where((t) {
      return t.status == 'pending' ||
          t.status == 'accepted' ||
          t.status == 'started';
    }).length;
    final dayStart = DateTime(now.year, now.month, now.day);
    final revenueToday = allTrips
        .where(
          (t) => t.status == 'completed' && !t.createdAt.isBefore(dayStart),
        )
        .fold<int>(0, (sum, t) => sum + t.amountMtn);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: S.of(context).adminNavMap,
          breadcrumb: const [
            BreadcrumbItem(label: 'Operações'),
            BreadcrumbItem(label: 'Mapa live'),
          ],
          actions: [
            const LivePill(),
            const SizedBox(width: YaSpacing.lg),
            _HeaderClock(timeStr: timeStr, dateStr: dateStr),
          ],
        ),
        const SizedBox(height: YaSpacing.xxl),
        KpiRow(
          children: [
            KpiCard(
              label: 'Drivers online',
              value: onlineDrivers.toString(),
              valueSuffix: '/ ${allDrivers.length}',
            ),
            KpiCard(
              label: 'Corridas activas',
              value: activeTrips.toString(),
            ),
            KpiCard(
              label: 'Receita hoje',
              value: NumberFormat('#,##0', 'pt_PT').format(revenueToday),
              valueSuffix: 'MTn',
            ),
          ],
        ),
        const SizedBox(height: YaSpacing.xxl),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth.isFinite && constraints.maxWidth < 1040;

            if (compact) {
              return Column(
                children: [
                  SizedBox(height: 560, child: _buildMap()),
                  const SizedBox(height: YaSpacing.lg),
                  SizedBox(height: 560, child: _buildSidePanel()),
                ],
              );
            }

            return SizedBox(
              height: mapAreaHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 7, child: _buildMap()),
                  const SizedBox(width: YaSpacing.lg),
                  SizedBox(width: 380, child: _buildSidePanel()),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // === MAPA ===
  void _zoomIn() => _setZoom(_mapController.camera.zoom + _zoomStep);

  void _zoomOut() => _setZoom(_mapController.camera.zoom - _zoomStep);

  void _centerMap() {
    _mapController.move(_maputoCenter, _initialZoom, id: 'center-map');
  }

  void _setZoom(double zoom) {
    final targetZoom = zoom.clamp(_minZoom, _maxZoom).toDouble();
    _mapController.move(
      _mapController.camera.center,
      targetZoom,
      id: 'zoom-control',
    );
  }

  Widget _buildMap() {
    final colors = YaColors.of(context);
    return ClipRRect(
      borderRadius: YaRadius.brLg,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colors.borderSubtle),
          borderRadius: YaRadius.brLg,
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: _maputoCenter,
                initialZoom: _initialZoom,
                maxZoom: _maxZoom,
                minZoom: _minZoom,
              ),
              children: [
                TileLayer(
                  urlTemplate: _tileUrlTemplate(context),
                  userAgentPackageName: 'mz.ya.painel',
                ),
                _polylineLayer(colors),
                _tripPinsLayer(colors),
                _driverMarkersLayer(colors),
              ],
            ),
            // Top-left: filtros
            Positioned(
              top: YaSpacing.lg,
              left: YaSpacing.lg,
              child: _FilterRow(
                active: _activeFilter,
                onChanged: (id) => setState(() => _activeFilter = id),
              ),
            ),
            // Top-right: layer toggle
            Positioned(
              top: YaSpacing.lg,
              right: YaSpacing.lg,
              child: _LayerToggle(
                active: _layer,
                onChanged: (l) => setState(() => _layer = l),
              ),
            ),
            // Right: zoom + center controls
            Positioned(
              right: YaSpacing.lg,
              top: 80,
              child: _MapControls(
                onZoomIn: _zoomIn,
                onZoomOut: _zoomOut,
                onCenter: _centerMap,
              ),
            ),
            // Bottom-left: legend
            const Positioned(
              bottom: YaSpacing.lg,
              left: YaSpacing.lg,
              child: _Legend(),
            ),
            // Bottom-right: attribution
            Positioned(
              bottom: 4,
              right: 8,
              child: Text(
                '© Mapbox  © OpenStreetMap contributors',
                style: YaText.sans(size: 10, height: 14)
                    .copyWith(color: colors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === Layers ===
  PolylineLayer _polylineLayer(YaColors colors) {
    return PolylineLayer(
      polylines: [
        for (final trip in _trips)
          if (trip.hasRoute)
            Polyline(
              points: [
                LatLng(trip.originLat!, trip.originLng!),
                LatLng(trip.destLat!, trip.destLng!),
              ],
              color: colors.brand,
              strokeWidth: trip.id == _selectedTripId ? 4.5 : 2.5,
            ),
      ],
    );
  }

  MarkerLayer _tripPinsLayer(YaColors colors) {
    return MarkerLayer(
      markers: [
        for (final trip in _trips) ...[
          if (trip.originLat != null && trip.originLng != null)
            Marker(
              point: LatLng(trip.originLat!, trip.originLng!),
              width: 24,
              height: 24,
              child: Icon(LucideIcons.mapPin, size: 22, color: colors.success),
            ),
          if (trip.destLat != null && trip.destLng != null)
            Marker(
              point: LatLng(trip.destLat!, trip.destLng!),
              width: 24,
              height: 24,
              child: Icon(LucideIcons.mapPin, size: 22, color: colors.danger),
            ),
        ],
      ],
    );
  }

  MarkerLayer _driverMarkersLayer(YaColors colors) {
    return MarkerLayer(
      markers: [
        for (final d in _filteredDrivers)
          Marker(
            point: d.point,
            width: 14,
            height: 14,
            child: _DriverDot(status: d.status),
          ),
      ],
    );
  }

  // === SIDE PANEL ===
  Widget _buildSidePanel() {
    final colors = YaColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: YaRadius.brLg,
        border: Border.all(color: colors.borderSubtle),
        boxShadow: isLight ? YaShadows.sm : YaShadows.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(YaSpacing.md),
            child: _SearchInput(controller: _searchCtrl),
          ),
          // Tabs
          _PanelTabs(
            active: _activeTab,
            tripsCount: _trips.length,
            driversCount: _drivers.where((d) => d.status != 'offline').length,
            onChanged: (t) => setState(() => _activeTab = t),
          ),
          // List
          Expanded(
            child:
                _activeTab == 'trips' ? _buildTripsList() : _buildDriversList(),
          ),
          // Footer
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.borderSubtle)),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: YaSpacing.md,
              vertical: YaSpacing.md,
            ),
            child: GestureDetector(
              onTap: () => context.go('/admin/trips'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Ver todas as corridas',
                      style: YaText.smMedium.copyWith(color: colors.brand),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(LucideIcons.chevronRight, size: 14, color: colors.brand),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList() {
    final colors = YaColors.of(context);
    final trips = _filteredTrips;
    if (trips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(YaSpacing.xxl),
          child: Text(
            _search.isEmpty
                ? 'Sem corridas activas neste momento.'
                : 'Nenhuma corrida corresponde à pesquisa.',
            textAlign: TextAlign.center,
            style: YaText.sm.copyWith(color: colors.textMuted),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: YaSpacing.md,
        vertical: YaSpacing.sm,
      ),
      itemCount: trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: YaSpacing.sm),
      itemBuilder: (context, i) {
        final trip = trips[i];
        return _TripCard(
          trip: trip,
          driverName: _driverName(trip.driverId),
          selected: trip.id == _selectedTripId,
          onTap: () {
            setState(() => _selectedTripId = trip.id);
            if (trip.originLat != null && trip.originLng != null) {
              _mapController.move(
                LatLng(trip.originLat!, trip.originLng!),
                14,
                id: 'focus-trip',
              );
            }
          },
        );
      },
    );
  }

  Widget _buildDriversList() {
    final colors = YaColors.of(context);
    final q = _search.toLowerCase();
    final drivers = _drivers.where((d) {
      if (q.isEmpty) return true;
      return _driverName(d.driverId).toLowerCase().contains(q) ||
          d.driverId.toLowerCase().contains(q);
    }).toList();
    if (drivers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(YaSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.users, size: 32, color: colors.textMuted),
              const SizedBox(height: YaSpacing.sm),
              Text(
                'Sem drivers com localização',
                style: YaText.smMedium.copyWith(color: colors.textPrimary),
              ),
              Text(
                'As posições aparecem quando os drivers ficam online.',
                textAlign: TextAlign.center,
                style: YaText.sans(size: 12, height: 16)
                    .copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: YaSpacing.md,
        vertical: YaSpacing.sm,
      ),
      itemCount: drivers.length,
      separatorBuilder: (_, __) => const SizedBox(height: YaSpacing.sm),
      itemBuilder: (context, i) {
        final d = drivers[i];
        final name = _driverName(d.driverId);
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _mapController.move(d.point, 15, id: 'focus-driver'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: YaRadius.brSm,
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: _DriverDot(status: d.status),
                  ),
                  const SizedBox(width: YaSpacing.sm),
                  YaAvatar.fromName(name, size: 22),
                  const SizedBox(width: YaSpacing.sm),
                  Expanded(
                    child: Text(
                      name,
                      style: YaText.sm.copyWith(color: colors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    switch (d.status) {
                      'available' => 'Disponível',
                      'busy' => 'Em corrida',
                      _ => 'Offline',
                    },
                    style: YaText.sans(size: 12, height: 16)
                        .copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// === Widgets ===

class _HeaderClock extends StatelessWidget {
  const _HeaderClock({required this.timeStr, required this.dateStr});
  final String timeStr;
  final String dateStr;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          timeStr,
          style:
              YaText.monoMd.copyWith(color: colors.textPrimary, fontSize: 16),
        ),
        Text(
          dateStr.replaceFirstMapped(
            RegExp(r'^.'),
            (m) => m.group(0)!.toUpperCase(),
          ),
          style: YaText.sm.copyWith(color: colors.textMuted),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.active, required this.onChanged});
  final String active;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FloatingChip(
          label: 'Todos',
          active: active == 'all',
          variant: StatusVariant.brand,
          onTap: () => onChanged('all'),
        ),
        _FloatingChip(
          label: 'Disponíveis',
          active: active == 'available',
          variant: StatusVariant.success,
          onTap: () => onChanged('available'),
        ),
        _FloatingChip(
          label: 'Em corrida',
          active: active == 'busy',
          variant: StatusVariant.warning,
          onTap: () => onChanged('busy'),
        ),
        _FloatingChip(
          label: 'Offline',
          active: active == 'offline',
          variant: StatusVariant.danger,
          onTap: () => onChanged('offline'),
        ),
        const _CityDropdown(),
      ],
    );
  }
}

class _FloatingChip extends StatelessWidget {
  const _FloatingChip({
    required this.label,
    required this.active,
    required this.variant,
    required this.onTap,
  });
  final String label;
  final bool active;
  final StatusVariant variant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final accent = variant.resolve(colors);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: active ? accent.bg : colors.bgSurface,
            borderRadius: YaRadius.brSm,
            border: Border.all(
              color: active ? accent.text : colors.borderSubtle,
            ),
            boxShadow: YaShadows.sm,
          ),
          child: Text(
            label,
            style: YaText.smMedium.copyWith(
              color: active ? accent.text : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CityDropdown extends StatelessWidget {
  const _CityDropdown();

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: YaRadius.brSm,
        border: Border.all(color: colors.borderSubtle),
        boxShadow: YaShadows.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Cidade: Maputo',
              style: YaText.smMedium.copyWith(color: colors.textPrimary),),
          const SizedBox(width: 4),
          Icon(LucideIcons.chevronDown, size: 12, color: colors.textMuted),
        ],
      ),
    );
  }
}

class _LayerToggle extends StatelessWidget {
  const _LayerToggle({required this.active, required this.onChanged});
  final String active;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: YaRadius.brSm,
        border: Border.all(color: colors.borderSubtle),
        boxShadow: YaShadows.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LayerOption(
              label: 'Map', value: 'map', active: active, onChanged: onChanged,),
          _LayerOption(
              label: 'Satellite',
              value: 'satellite',
              active: active,
              onChanged: onChanged,),
          const Tooltip(
            message: 'Heatmap disponível quando houver histórico suficiente',
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: _DisabledLayerLabel('Heatmap'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisabledLayerLabel extends StatelessWidget {
  const _DisabledLayerLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Text(
      label,
      style: YaText.smMedium.copyWith(color: colors.textMuted),
    );
  }
}

class _LayerOption extends StatelessWidget {
  const _LayerOption({
    required this.label,
    required this.value,
    required this.active,
    required this.onChanged,
  });
  final String label;
  final String value;
  final String active;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final selected = active == value;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? colors.brandSubtle : Colors.transparent,
            borderRadius: YaRadius.brXs,
          ),
          child: Text(
            label,
            style: YaText.smMedium.copyWith(
              color: selected ? colors.brand : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onCenter,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onCenter;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapButton(icon: LucideIcons.plus, onTap: onZoomIn),
        const SizedBox(height: 4),
        _MapButton(icon: LucideIcons.minus, onTap: onZoomOut),
        const SizedBox(height: YaSpacing.sm),
        _MapButton(
          icon: LucideIcons.locate,
          onTap: onCenter,
          label: 'Centrar\nem mim',
        ),
      ],
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.onTap, this.label});
  final IconData icon;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: label != null ? 56 : 32,
          height: label != null ? 52 : 32,
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: YaRadius.brSm,
            border: Border.all(color: colors.borderSubtle),
            boxShadow: YaShadows.sm,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: colors.textPrimary),
              if (label != null) ...[
                const SizedBox(height: 2),
                Text(
                  label!,
                  textAlign: TextAlign.center,
                  style: YaText.sans(size: 9, height: 11)
                      .copyWith(color: colors.textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: YaSpacing.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: YaRadius.brSm,
        border: Border.all(color: colors.borderSubtle),
        boxShadow: YaShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegendDot(color: colors.success, label: 'Disponíveis'),
          const SizedBox(height: 4),
          _LegendDot(color: colors.warning, label: 'Em corrida'),
          const SizedBox(height: 4),
          _LegendDot(color: colors.danger, label: 'Offline/alerta'),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: YaSpacing.sm),
        Text(label,
            style: YaText.sans(size: 12, height: 16)
                .copyWith(color: colors.textPrimary),),
      ],
    );
  }
}

class _DriverDot extends StatelessWidget {
  const _DriverDot({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final color = switch (status) {
      'available' => colors.success,
      'busy' => colors.warning,
      'offline' => colors.danger,
      _ => colors.neutral,
    };
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1),),
        ],
      ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: YaRadius.brSm,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.search, size: 14, color: colors.textMuted),
          const SizedBox(width: YaSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              style: YaText.sm.copyWith(color: colors.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Pesquisar driver ou corrida...',
                hintStyle: YaText.sm.copyWith(color: colors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelTabs extends StatelessWidget {
  const _PanelTabs({
    required this.active,
    required this.tripsCount,
    required this.driversCount,
    required this.onChanged,
  });
  final String active;
  final int tripsCount;
  final int driversCount;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: YaSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: _PanelTab(
                label: 'Corridas activas',
                count: tripsCount,
                active: active == 'trips',
                onTap: () => onChanged('trips'),
              ),
            ),
            const SizedBox(width: YaSpacing.md),
            Expanded(
              child: _PanelTab(
                label: 'Drivers',
                count: driversCount,
                active: active == 'drivers',
                onTap: () => onChanged('drivers'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelTab extends StatelessWidget {
  const _PanelTab({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? colors.brand : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: YaText.smMedium.copyWith(
                    color: active ? colors.textPrimary : colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '($count)',
                style: YaText.mono(size: 12, height: 16)
                    .copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.driverName,
    required this.selected,
    required this.onTap,
  });
  final AdminTrip trip;
  final String driverName;
  final bool selected;
  final VoidCallback onTap;

  String get _elapsed {
    final minutes = DateTime.now().difference(trip.createdAt).inMinutes;
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h${(minutes % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final mapping = _statusMapping(trip.status);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: selected ? colors.brandSubtle : colors.bgSurface,
            borderRadius: YaRadius.brSm,
            border: Border.all(
              color: selected ? colors.brandBorder : colors.borderSubtle,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: ID + status + tempo
              Wrap(
                spacing: YaSpacing.sm,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    trip.id,
                    style: YaText.monoSm.copyWith(color: colors.textPrimary),
                  ),
                  StatusBadge.fromMapping(mapping),
                  Text(
                    _elapsed,
                    style: YaText.monoSm.copyWith(color: colors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Rota
              Row(
                children: [
                  Flexible(
                    child: Text(
                      trip.origin ?? '—',
                      style: YaText.sm.copyWith(color: colors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(LucideIcons.arrowRight,
                        size: 12, color: colors.textMuted,),
                  ),
                  Flexible(
                    child: Text(
                      trip.destination ?? '—',
                      style: YaText.sm.copyWith(color: colors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Footer: avatar + nome + valor
              Row(
                children: [
                  YaAvatar.fromName(driverName, size: 22),
                  const SizedBox(width: YaSpacing.sm),
                  Expanded(
                    child: Text(
                      driverName,
                      style: YaText.sm.copyWith(color: colors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: YaSpacing.sm),
                  Text(
                    '${_fmt(trip.amountMtn)} MTn',
                    style: YaText.monoSm.copyWith(color: colors.textPrimary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  StatusMapping _statusMapping(String status) {
    return switch (status) {
      'started' => YaStatus.tripStarted,
      'accepted' => YaStatus.tripAccepted,
      'pending' => const StatusMapping(StatusVariant.warning, 'Pendente'),
      'enroute' => const StatusMapping(StatusVariant.info, 'A caminho'),
      _ => StatusMapping(StatusVariant.neutral, status),
    };
  }

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// === Data classes ===

class _DriverMarker {
  const _DriverMarker({
    required this.driverId,
    required this.point,
    required this.status,
  });
  final String driverId;
  final LatLng point;
  final String status;
}

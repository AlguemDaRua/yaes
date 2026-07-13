import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/config/map_config.dart';
import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';

enum YaMapStyle { streets, dark, satellite }

/// Wrapper reutilizável sobre FlutterMap com tiles Mapbox.
/// Sincroniza automaticamente dark/light com o tema quando style é omitido.
class YaMap extends StatelessWidget {
  const YaMap({
    this.controller,
    this.initialCenter = const LatLng(-25.9664, 32.5892),
    this.initialZoom = 12.5,
    this.minZoom = 9.0,
    this.maxZoom = 18.0,
    this.style,
    this.markers = const [],
    this.polylines = const [],
    this.circles = const [],
    this.interactive = true,
    this.showAttribution = true,
    this.extraLayers = const [],
    super.key,
  });

  final MapController? controller;
  final LatLng initialCenter;
  final double initialZoom;
  final double minZoom;
  final double maxZoom;

  /// Quando null, usa streets em modo claro e dark em modo escuro.
  final YaMapStyle? style;

  final List<Marker> markers;
  final List<Polyline> polylines;
  final List<CircleMarker> circles;
  final bool interactive;
  final bool showAttribution;

  /// Layers adicionais (e.g. MarkerCluster, Heatmap).
  final List<Widget> extraLayers;

  String _tileUrl(BuildContext context) {
    final resolved = style ??
        (Theme.of(context).brightness == Brightness.dark
            ? YaMapStyle.dark
            : YaMapStyle.streets);
    switch (resolved) {
      case YaMapStyle.satellite:
        return MapConfig.satelliteTileUrl;
      case YaMapStyle.dark:
        return MapConfig.darkTileUrl;
      case YaMapStyle.streets:
        return MapConfig.streetsTileUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final tileUrl = _tileUrl(context);

    final mapOptions = interactive
        ? MapOptions(
            initialCenter: initialCenter,
            initialZoom: initialZoom,
            minZoom: minZoom,
            maxZoom: maxZoom,
          )
        : MapOptions(
            initialCenter: initialCenter,
            initialZoom: initialZoom,
            minZoom: minZoom,
            maxZoom: maxZoom,
            interactionOptions:
                const InteractionOptions(flags: InteractiveFlag.none),
          );

    return FlutterMap(
      mapController: controller,
      options: mapOptions,
      children: [
        TileLayer(
          urlTemplate: tileUrl,
          userAgentPackageName: 'mz.ya.painel',
        ),
        if (circles.isNotEmpty)
          CircleLayer(circles: circles),
        if (polylines.isNotEmpty)
          PolylineLayer(polylines: polylines),
        if (markers.isNotEmpty)
          MarkerLayer(markers: markers),
        ...extraLayers,
        if (showAttribution)
          Positioned(
            bottom: 4,
            right: 8,
            child: Text(
              '© Mapbox  © OpenStreetMap',
              style: YaText.sans(size: 9, height: 12)
                  .copyWith(color: colors.textMuted),
            ),
          ),
      ],
    );
  }
}

/// Marker de driver: ponto colorido com sombra.
class YaDriverDotMarker extends StatelessWidget {
  const YaDriverDotMarker({required this.status, super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final color = switch (status) {
      'available' => colors.success,
      'on_trip' || 'started' => colors.brand,
      'offline' => colors.textMuted,
      _ => colors.textMuted,
    };
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
        ],
      ),
    );
  }
}

/// Pin marcador de origem/destino com cor e ícone.
class YaTripPin extends StatelessWidget {
  const YaTripPin({required this.isOrigin, super.key});
  final bool isOrigin;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final color = isOrigin ? colors.success : colors.danger;
    return Icon(LucideIcons.mapPin, color: color, size: 22);
  }
}

/// Controles de zoom flutuantes (para usar em Stack sobre YaMap).
class YaMapZoomControls extends StatelessWidget {
  const YaMapZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onCenter,
    super.key,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onCenter;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: YaRadius.brMd,
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ControlBtn(icon: LucideIcons.plus, onTap: onZoomIn),
          _Divider(colors: colors),
          _ControlBtn(icon: LucideIcons.minus, onTap: onZoomOut),
          _Divider(colors: colors),
          _ControlBtn(icon: LucideIcons.crosshair, onTap: onCenter),
        ],
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  const _ControlBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: YaRadius.brSm,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 16, color: colors.textSecondary),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.colors});
  final YaColors colors;

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: colors.borderSubtle);
}

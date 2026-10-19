import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Botão de bússola para o mapa que indica o Norte e reposiciona a rotação para 0° ao ser tocado.
/// Reutilizável em todos os mapas (passageiro, escolha no mapa, motorista).
class MapCompassButton extends StatefulWidget {
  final MapController? mapController;
  final AnimatedMapController? animatedMapController;
  final double? size;
  final VoidCallback? onReset;
  final bool autoHide;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? margin;

  const MapCompassButton({
    super.key,
    this.mapController,
    this.animatedMapController,
    this.size,
    this.onReset,
    this.autoHide = false,
    this.backgroundColor,
    this.boxShadow,
    this.margin,
  }) : assert(
          mapController != null || animatedMapController != null,
          'Deve fornecer mapController ou animatedMapController',
        );

  @override
  State<MapCompassButton> createState() => _MapCompassButtonState();
}

class _MapCompassButtonState extends State<MapCompassButton> {
  StreamSubscription<MapEvent>? _subscription;
  double _currentRotation = 0.0;

  MapController get _controller =>
      widget.animatedMapController?.mapController ?? widget.mapController!;

  double get _safeRotation {
    try {
      return _controller.camera.rotation;
    } catch (_) {
      return 0.0;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _currentRotation = _safeRotation;
      });
      _listenToMapEvents();
    });
  }

  void _listenToMapEvents() {
    _subscription?.cancel();
    _subscription = _controller.mapEventStream.listen((event) {
      if (!mounted) return;
      final rot = event.camera.rotation;
      if ((rot - _currentRotation).abs() > 0.05) {
        setState(() {
          _currentRotation = rot;
        });
      }
    });
  }

  @override
  void didUpdateWidget(MapCompassButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCtrl = oldWidget.animatedMapController?.mapController ?? oldWidget.mapController;
    final newCtrl = widget.animatedMapController?.mapController ?? widget.mapController;
    if (oldCtrl != newCtrl) {
      _currentRotation = _safeRotation;
      _listenToMapEvents();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _resetToNorth() {
    final current = _safeRotation;
    final normalized = ((current % 360) + 540) % 360 - 180;
    if (normalized.abs() < 0.5) {
      widget.onReset?.call();
      return;
    }

    if (widget.animatedMapController != null) {
      widget.animatedMapController!.animatedRotateReset();
    } else {
      _controller.rotate(0.0);
    }

    widget.onReset?.call();
  }

  @override
  Widget build(BuildContext context) {
    final buttonSize = widget.size ?? 44.sp;
    final isRotated = ((_currentRotation % 360) + 540) % 360 - 180;
    final hasRotation = isRotated.abs() >= 1.0;

    final content = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _resetToNorth,
      child: Tooltip(
        message: 'Apontar a norte',
        child: Container(
          width: buttonSize,
          height: buttonSize,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.white,
            shape: BoxShape.circle,
            boxShadow: widget.boxShadow ??
                [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
          ),
          child: Center(
            child: Transform.rotate(
              // Rotação invertida para que o ponteiro norte aponte para o Norte geográfico real
              angle: -(_currentRotation * math.pi / 180.0),
              child: SizedBox(
                width: buttonSize * 0.65,
                height: buttonSize * 0.65,
                child: const CustomPaint(
                  painter: _CompassDialPainter(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.autoHide) {
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: hasRotation ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: !hasRotation,
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Desenha o mostrador da bússola com agulha facetada em 3D e indicador "N".
class _CompassDialPainter extends CustomPainter {
  const _CompassDialPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final halfLen = size.height * 0.38;
    final halfWidth = size.width * 0.15;

    // 1. Letra "N" no topo
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          color: Color(0xFFE53935),
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          fontFamily: 'sans-serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - halfLen - textPainter.height + 1.5),
    );

    final pathNorthLeft = Path()
      ..moveTo(cx, cy - halfLen)
      ..lineTo(cx - halfWidth, cy)
      ..lineTo(cx, cy)
      ..close();

    final pathNorthRight = Path()
      ..moveTo(cx, cy - halfLen)
      ..lineTo(cx + halfWidth, cy)
      ..lineTo(cx, cy)
      ..close();

    final pathSouthLeft = Path()
      ..moveTo(cx, cy + halfLen)
      ..lineTo(cx - halfWidth, cy)
      ..lineTo(cx, cy)
      ..close();

    final pathSouthRight = Path()
      ..moveTo(cx, cy + halfLen)
      ..lineTo(cx + halfWidth, cy)
      ..lineTo(cx, cy)
      ..close();

    // 2. Ponteiro Norte (Vermelho facetado)
    canvas.drawPath(
      pathNorthLeft,
      Paint()
        ..color = const Color(0xFFEF5350)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      pathNorthRight,
      Paint()
        ..color = const Color(0xFFD32F2F)
        ..style = PaintingStyle.fill,
    );

    // 3. Ponteiro Sul (Cinza facetado)
    canvas.drawPath(
      pathSouthLeft,
      Paint()
        ..color = const Color(0xFFB0BEC5)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      pathSouthRight,
      Paint()
        ..color = const Color(0xFF78909C)
        ..style = PaintingStyle.fill,
    );

    // 4. Pino central (anel metálico com centro branco)
    canvas.drawCircle(
      Offset(cx, cy),
      2.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      2.5,
      Paint()
        ..color = const Color(0xFF37474F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

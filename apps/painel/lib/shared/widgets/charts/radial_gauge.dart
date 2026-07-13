// Tradução fiel de _design/showcases/charts.jsx (componente RadialGauge).
// Arco 270° (-135°→+135° relativo ao topo) com track + valor.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/typography.dart';

/// Gauge radial: arco de 270° com valor central + label.
///
/// Cor é controlada pelo consumidor (success/warning/danger/brand).
class RadialGauge extends StatelessWidget {
  const RadialGauge({
    required this.value,
    required this.label,
    this.max = 100,
    this.suffix = '%',
    this.color,
    this.size = 200,
    super.key,
  });

  final double value;
  final double max;
  final String label;
  final String suffix;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return SizedBox(
      width: size,
      height: size * 0.85,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size * 0.85),
            painter: _GaugePainter(
              value: value,
              max: max,
              trackColor: colors.bgSubtle,
              fillColor: color ?? colors.brand,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: YaText.serif(
                    size: 28,
                    height: 32,
                    weight: FontWeight.w500,
                  ).copyWith(color: colors.textPrimary),
                  children: [
                    TextSpan(text: _formatValue(value)),
                    TextSpan(
                      text: suffix,
                      style: YaText.serif(size: 14, height: 22)
                          .copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: YaText.sans(
                  size: 11,
                  height: 14,
                  letterSpacing: 0.55, // 0.05em * 11
                ).copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatValue(double v) {
    if (v == v.toInt()) return v.toInt().toString();
    return v.toStringAsFixed(1).replaceAll('.', ',');
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.max,
    required this.trackColor,
    required this.fillColor,
  });
  final double value;
  final double max;
  final Color trackColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final cx = size.width / 2;
    final cy = size.width / 2; // origem y = top da square
    final r = size.width / 2 - 18;

    // CSS: startAngle = π * 0.75 = 135°, endAngle = π * 2.25 = 405° → arco 270°.
    // Em Flutter: ângulo zero = 3 horas. 135° em radianos = 3π/4.
    const startAngle = math.pi * 0.75;
    const sweep = math.pi * 1.5; // 270°

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweep, false, track);

    final ratio = (value / max).clamp(0.0, 1.0);
    final valueSweep = sweep * ratio;
    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, valueSweep, false, fill);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) {
    return old.value != value ||
        old.max != max ||
        old.trackColor != trackColor ||
        old.fillColor != fillColor;
  }
}

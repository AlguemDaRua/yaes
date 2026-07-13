// Tradução fiel de _design/showcases/charts.jsx (componente Sparkline).
// SVG inline → CustomPainter em Dart (mais leve que fl_chart para inline).

import 'package:flutter/material.dart';

import '../../../theme/tokens/colors.dart';

/// Mini-gráfico inline (em KPIs, células de tabela). Render directo via
/// [CustomPainter] — sem dependência de fl_chart.
class Sparkline extends StatelessWidget {
  const Sparkline({
    required this.data,
    this.color,
    this.fill = false,
    this.width = 80,
    this.height = 28,
    super.key,
  });

  final List<double> data;

  /// Default = brand do tema.
  final Color? color;
  final bool fill;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return CustomPaint(
      size: Size(width, height),
      painter: _SparklinePainter(
        data: data,
        color: color ?? colors.brand,
        fill: fill,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.data,
    required this.color,
    required this.fill,
  });
  final List<double> data;
  final Color color;
  final bool fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs() < 0.0001 ? 1.0 : max - min;

    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - min) / range) * (size.height - 4) - 2;
      points.add(Offset(x, y));
    }

    if (fill) {
      final fillPath = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      fillPath.lineTo(size.width, size.height);
      fillPath.lineTo(0, size.height);
      fillPath.close();

      canvas.drawPath(
        fillPath,
        Paint()..color = color.withValues(alpha: 0.15),
      );
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // Dot final
    canvas.drawCircle(points.last, 2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) {
    return old.color != color || old.fill != fill || old.data != data;
  }
}

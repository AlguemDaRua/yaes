// Tradução fiel de _design/showcases/empty-skeleton.jsx (componente Skeleton).
// CSS: classe `.ya-skeleton` em _design/tokens.css — gradient shimmer 1.5s linear.
// Respeita prefers-reduced-motion → fallback estático.

import 'package:flutter/material.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';

/// Primitivo de loading: rectângulo/círculo com shimmer.
///
/// Usa-se directamente para qualquer placeholder. Para composições comuns
/// (linha de tabela, KPI card, chart), o consumidor compõe vários `Skeleton`
/// num layout — não há subclasses pré-fabricadas porque o JSX original
/// também não as define.
class Skeleton extends StatefulWidget {
  const Skeleton({
    required this.width,
    required this.height,
    this.radius = 4,
    super.key,
  });

  /// Atalho para um círculo (radius = full).
  factory Skeleton.circle({required double size, Key? key}) {
    return Skeleton(width: size, height: size, radius: size / 2, key: key);
  }

  final double width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: YaDurations.shimmer,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final radius = BorderRadius.circular(widget.radius);

    if (reduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: colors.bgSubtle,
          borderRadius: radius,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // CSS faz `background-position: -200% → 200%` num gradient `200% 100%`.
        // Em Flutter simulamos com Alignment a deslizar de -1 → +3 (4 unidades
        // = 200% num eixo cujo tamanho default é 1 = 100%).
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 4, 0),
              end: Alignment(1 + t * 4, 0),
              colors: [
                colors.bgSubtle,
                colors.bgElevated,
                colors.bgSubtle,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../../../theme/tokens/dimensions.dart';

abstract class YaBreakpoints {
  static const double compact = 640;
  static const double medium = 900;
  static const double wide = 1180;
}

abstract class YaResponsive {
  static bool isCompact(double width, {double breakpoint = YaBreakpoints.compact}) {
    return width.isFinite && width < breakpoint;
  }

  static EdgeInsets pagePaddingForWidth(double width) {
    final padding = switch (width) {
      < 520 => YaSpacing.md,
      < 900 => YaSpacing.lg,
      < 1180 => YaSpacing.xxl,
      _ => YaDimensions.pageHorizontalPadding,
    };

    return EdgeInsets.all(padding);
  }
}

class YaResponsiveStack extends StatelessWidget {
  const YaResponsiveStack({
    required this.children,
    this.flexes,
    this.spacing = YaSpacing.lg,
    this.breakpoint = YaBreakpoints.medium,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    super.key,
  }) : assert(flexes == null || flexes.length == children.length);

  final List<Widget> children;
  final List<int>? flexes;
  final double spacing;
  final double breakpoint;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = YaResponsive.isCompact(
          constraints.maxWidth,
          breakpoint: breakpoint,
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _spaced(children, Axis.vertical),
          );
        }

        return Row(
          crossAxisAlignment: crossAxisAlignment,
          children: _spaced(
            [
              for (var i = 0; i < children.length; i++)
                Expanded(flex: flexes?[i] ?? 1, child: children[i]),
            ],
            Axis.horizontal,
          ),
        );
      },
    );
  }

  List<Widget> _spaced(List<Widget> widgets, Axis axis) {
    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      if (i > 0) {
        result.add(axis == Axis.horizontal
            ? SizedBox(width: spacing)
            : SizedBox(height: spacing),);
      }
      result.add(widgets[i]);
    }
    return result;
  }
}

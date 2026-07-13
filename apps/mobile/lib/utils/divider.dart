
import 'package:flutter/material.dart';
Widget dividerWithOrVaryingThickness({
  Color color = Colors.black,
  double maxThickness = 2,
  double minThickness = 0.2,
  double totalWidth = 10,
  String text = 'or',
  TextStyle? textStyle,
  int steps = 100,
}) {
  final stepWidth = totalWidth / steps;

  List<Widget> buildLine({bool reverse = false}) {
    List<Widget> widgets = [];
    for (int i = 0; i < steps; i++) {
      double thickness = minThickness + (maxThickness - minThickness) * (i / (steps - 1));
      if (reverse) thickness = minThickness + (maxThickness - minThickness) * ((steps - 1 - i) / (steps - 1));
      widgets.add(Container(
        width: stepWidth,
        height: thickness,
        color: color,
      ));
    }
    return widgets;
  }

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      ...buildLine(reverse: false),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          style: textStyle ?? const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      ...buildLine(reverse: true),
    ],
  );
}

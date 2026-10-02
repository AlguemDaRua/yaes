import 'package:flutter/material.dart';

/// The number follows the same order as the itinerary's stop list.
class StopMarker extends StatelessWidget {
  const StopMarker({super.key, required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final label = 'Paragem $number';
    return Semantics(
      label: label,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: ExcludeSemantics(
          child: Container(
            margin: const EdgeInsets.all(4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF202520),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:limousineexecutive/passenger/models/cardata.dart';

abstract final class RideStyle {
  static const ink = Color(0xFF202520);
  static const muted = Color(0xFF74786E);
  static const gold = Color(0xFFF2C94C);
  static const cream = Color(0xFFF7F6F2);
  static const line = Color(0xFFE9EAE3);
  static const sheetDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    boxShadow: [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 32,
        offset: Offset(0, -8),
      ),
    ],
  );
}

class VehicleArtwork extends StatelessWidget {
  const VehicleArtwork({super.key, required this.category, this.height = 76});
  final String category;
  final double height;
  @override
  Widget build(BuildContext context) {
    final path = CarData.categoryImages[category];
    return SizedBox(
      height: height,
      child: path == null
          ? Icon(
              CarData.categoryIcon(category),
              size: height * .65,
              color: RideStyle.ink,
            )
          : Transform.scale(
              scale: category == 'confort' ? 1.25 : 1,
              child: Image.asset(
                path,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    Icon(CarData.categoryIcon(category), size: height * .65),
              ),
            ),
    );
  }
}

class RideButton extends StatelessWidget {
  const RideButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: RideStyle.ink,
        foregroundColor: Colors.white,
        disabledBackgroundColor: RideStyle.line,
        disabledForegroundColor: RideStyle.muted,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          Icon(icon, size: 21),
        ],
      ),
    ),
  );
}

class RideHandle extends StatelessWidget {
  const RideHandle({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 38,
      height: 4,
      margin: const EdgeInsets.only(top: 12, bottom: 18),
      decoration: BoxDecoration(
        color: RideStyle.line,
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}

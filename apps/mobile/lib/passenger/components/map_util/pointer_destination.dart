import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

Widget buildDestinationMarker({
  required int minutes, // Ex: "5 min"
}) {
  // 1. Get the current time
  final now = DateTime.now();

  // 2. Add duration in minutes
  final eta = now.add(Duration(minutes: minutes));

  // 3. Format the arrival time (e.g. 13:45)
  final formatter = DateFormat('HH:mm'); // 24h format
  final etaTime = formatter.format(eta);

  return FittedBox(
    fit: BoxFit.contain,
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Box with arrival time (ETA)
      // Box with arrival time (ETA)
      Container(
        padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 4.sp),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            const BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          etaTime,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 11.sp,
          ),
        ),
      ),

      // Balloon tip (small triangle)
      CustomPaint(
        size: Size(10.sp, 5.sp),
        painter: _TrianglePainter(color: Colors.black),
      ),

      // Styled pin (destination)
      Stack(
        alignment: Alignment.center,
        children: [
          // Shadow or circular base
          Container(
            width: 14.sp,
            height: 14.sp,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(30),
              shape: BoxShape.circle,
            ),
          ),

          // Pin body
          Container(
            width: 8.sp,
            height: 8.sp,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    ],
    ),
  );
}

// Draw triangle (bottom tip of the balloon)
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

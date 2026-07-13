import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/utils/asset_paths.dart';

class VehicleMarker extends StatelessWidget {
  final double angle;
  final double size;
  final bool showTooltip;
  final String? carImage;
  final String? carName;
  final double? rating;
  final VoidCallback? onTap;

  const VehicleMarker({
    super.key,
    required this.angle,
    this.size = 40,
    this.showTooltip = false,
    this.carImage,
    this.carName,
    this.rating,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Tooltip Bubble
          if (showTooltip) Positioned(top: -95.h, child: _buildTooltip()),

          // Marker shadow for depth
          Container(
            width: (size * 0.95).sp,
            height: (size * 0.95).sp,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),

          // Car Icon
          Transform.rotate(
            angle: angle,
            child: Image.asset(
              AssetPaths.CarIcon,
              width: size.sp,
              height: size.sp,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTooltip() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          alignment: Alignment.bottomCenter,
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 85.w, // Reduced width to make it more square-ish
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Car Image - Emphasized
                Image.asset(
                  carImage ?? AssetPaths.hatchrenault,
                  //width: 50.w, // Larger relative to the card width
                  height: 45.h,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 4.h),
                // Compact Info
                Text(
                  carName ?? "Executivo",
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                // SizedBox(height: 2.h),
                // Compact Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star,
                      color: const Color(0xFFD4AF37),
                      size: 10.sp,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      rating?.toStringAsFixed(1) ?? "5.0",
                      style: GoogleFonts.poppins(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Triangle Pointer
          CustomPaint(
            size: Size(12.w, 7.h),
            painter: _TrianglePainter(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

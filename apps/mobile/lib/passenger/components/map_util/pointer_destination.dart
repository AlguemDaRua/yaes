import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

Widget buildDestinationMarker({
  required int minutes,
}) {
  return DestinationMarker(minutes: minutes);
}

class DestinationMarker extends StatefulWidget {
  final int minutes;
  const DestinationMarker({super.key, required this.minutes});

  @override
  State<DestinationMarker> createState() => _DestinationMarkerState();
}

class _DestinationMarkerState extends State<DestinationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eta = DateTime.now().add(Duration(minutes: widget.minutes));
    final etaTime = DateFormat('HH:mm').format(eta);

    return FittedBox(
      fit: BoxFit.contain,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Caixa com tempo estimado de chegada e aura pulsante
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Aura pulsante
              Positioned(
                top: -6.sp,
                bottom: -6.sp,
                left: -8.sp,
                right: -8.sp,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final t = _controller.value;
                    return Transform.scale(
                      scale: 1.0 + (t * 0.06),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.35 + (t * 0.45),
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: 0.08 + (t * 0.12),
                              ),
                              blurRadius: 8 + (t * 4),
                              spreadRadius: t * 1.5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Caixa estática
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.sp,
                  vertical: 6.sp,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  'chegada às $etaTime',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),

          // Ponta do balão
          CustomPaint(
            size: Size(10.sp, 5.sp),
            painter: const _TrianglePainter(color: Colors.black),
          ),

          // Pino de destino
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 14.sp,
                height: 14.sp,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(30),
                  shape: BoxShape.circle,
                ),
              ),
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
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
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

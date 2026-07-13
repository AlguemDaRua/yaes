import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> showCallToPassanger({
  required context,
  required String phoneNumber,
  required VoidCallback onConfirm,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
      ),
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      child: Padding(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone, size: 40.sp, color: Colors.amberAccent),
            SizedBox(height: 12.sp),
            Text(
              "Confirmar ligação",
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.amberAccent,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 6,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              "Deseja ligar para $phoneNumber?",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 20.sp),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  child: Text(
                    "Cancelar",
                    style: GoogleFonts.poppins(fontSize: 14.sp),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    foregroundColor: Colors.black,
                    elevation: 8,
                    shadowColor: Colors.amberAccent.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 10.h,
                    ),
                  ),
                  icon: Icon(Icons.phone, size: 18.sp),
                  label: Text(
                    "Ligar",
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop(); // fecha o dialog
                    onConfirm(); // execute call action
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

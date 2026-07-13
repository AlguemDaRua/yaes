import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/utils/asset_paths.dart';
import 'package:slide_to_act/slide_to_act.dart';

class CancelRideSlider extends StatefulWidget {
  final VoidCallback onCancel;

  const CancelRideSlider({super.key, required this.onCancel});

  @override
  State<CancelRideSlider> createState() => _CancelRideSliderState();
}

class _CancelRideSliderState extends State<CancelRideSlider> {
  static const Color _accentColor = Color(0xffe5a400);

  @override
  Widget build(BuildContext context) {
    return SlideAction(
      height: 54.sp,
      text: "Deslize para cancelar",
      textStyle: GoogleFonts.poppins(
        color: Colors.black87,
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      ),
      onSubmit: () {
        showCancelDialog(context);
        widget.onCancel();
        return null;
      },
      outerColor: Colors.grey.withAlpha(12),
      innerColor: _accentColor,
      elevation: 0,
      sliderButtonIcon: Icon(
        Icons.close_rounded,
        color: Colors.white,
        size: 18.sp,
      ),
      submittedIcon: Container(
        height: 40.sp,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Image.asset(AssetPaths.sad),
      ),
    );
  }
}

Future showCancelDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Viagem Cancelada',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18.sp,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.sp),
            Text(
              'Sua viagem foi cancelada com sucesso.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.sp),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.sp),
                decoration: BoxDecoration(
                  color: const Color(0xffe5a400),
                  borderRadius: BorderRadius.circular(30.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xffe5a400).withAlpha(60),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

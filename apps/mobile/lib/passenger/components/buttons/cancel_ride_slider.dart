import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:limousineexecutive/shared/widgets/trip_cancellation_dialog.dart';

class CancelRideSlider extends StatefulWidget {
  final Future<void> Function(String reason) onCancel;

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
      text: 'Deslize para cancelar',
      textStyle: GoogleFonts.poppins(
        color: const Color(0xFF5D6258),
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      ),
      onSubmit: () async {
        await showTripCancellationDialog(context, onConfirm: widget.onCancel);
        return null;
      },
      outerColor: const Color(0xFFF5F6F1),
      innerColor: const Color(0xFFB9382F),
      elevation: 0,
      borderRadius: 18,
      sliderButtonIcon: Icon(
        Icons.close_rounded,
        color: Colors.white,
        size: 18.sp,
      ),
      submittedIcon: Icon(
        Icons.check_rounded,
        size: 22.sp,
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swipe_left_rounded, size: 18.sp, color: _accentColor),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              'Deslize para cancelar',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: const Color(0xFF5D6258),
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

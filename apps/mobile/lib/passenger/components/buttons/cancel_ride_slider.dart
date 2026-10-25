import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slide_to_act/slide_to_act.dart';

class CancelRideSlider extends StatefulWidget {
  final Future<void> Function() onCancel;

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
        final confirmed = await showCancelDialog(context);
        if (confirmed == true) await widget.onCancel();
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

Future<bool?> showCancelDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26.r)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(22.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 54.w,
                height: 54.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0ED),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: const Color(0xFFB9382F),
                  size: 29.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Cancelar esta viagem?',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 19.sp,
                  color: const Color(0xFF202520),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Tem certeza que deseja cancelar? O motorista deixará de receber este pedido.',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: const Color(0xFF74786E),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 22.h),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 330;
                  final keepButton = OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(0, 48.h),
                      foregroundColor: const Color(0xFF202520),
                      side: const BorderSide(color: Color(0xFFE2E4DC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                    ),
                    child: const Text('Continuar viagem'),
                  );
                  final cancelButton = FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: FilledButton.styleFrom(
                      minimumSize: Size(0, 48.h),
                      backgroundColor: const Color(0xFFB9382F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                    ),
                    child: const Text('Sim, cancelar'),
                  );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        cancelButton,
                        SizedBox(height: 8.h),
                        keepButton,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: keepButton),
                      SizedBox(width: 10.w),
                      Expanded(child: cancelButton),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:provider/provider.dart';

class SelectedCarCard extends StatelessWidget {
  static const Color _ink = Color(0xFF202520);
  static const Color _muted = Color(0xFF74786E);

  const SelectedCarCard({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<PassengerState>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 350;

        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 8.h),
          padding: EdgeInsets.all(compact ? 14.w : 16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xFFE8E8E8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _DriverAvatar(photoUrl: appState.driverPhotoUrl),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MOTORISTA',
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: _muted,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          appState.driverName.trim().isNotEmpty
                              ? appState.driverName
                              : 'Motorista',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _EtaPill(minutes: appState.durationMin),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                child: const Divider(height: 1, color: Color(0xFFE8E8E8)),
              ),
              _TripFare(amount: appState.estimatedPrice.ceil()),
            ],
          ),
        );
      },
    );
  }
}

class _DriverAvatar extends StatelessWidget {
  const _DriverAvatar({required this.photoUrl});
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF1F2ED),
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl.trim().isNotEmpty
          ? Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.person_outline_rounded,
                color: SelectedCarCard._muted,
                size: 26,
              ),
            )
          : const Icon(
              Icons.person_outline_rounded,
              color: SelectedCarCard._muted,
              size: 26,
            ),
    );
  }
}

class _EtaPill extends StatelessWidget {
  const _EtaPill({required this.minutes});
  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 40.h),
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F1),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 16,
            color: SelectedCarCard._ink,
          ),
          SizedBox(width: 5.w),
          Text(
            '$minutes min',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: SelectedCarCard._ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripFare extends StatelessWidget {
  const _TripFare({required this.amount});
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E0),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF3E2A8)),
      ),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE5A400),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.payments_outlined,
              size: 20.sp,
              color: SelectedCarCard._ink,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Valor da viagem',
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.55,
                    color: SelectedCarCard._muted,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  '$amount MT',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: SelectedCarCard._ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

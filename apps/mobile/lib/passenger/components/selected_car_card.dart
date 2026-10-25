import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/passenger/models/cardata.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:provider/provider.dart';

class SelectedCarCard extends StatelessWidget {
  static const Color _ink = Color(0xFF202520);
  static const Color _muted = Color(0xFF74786E);
  static const Color _gold = Color(0xFFF2C94C);

  const SelectedCarCard({super.key});

  String _categoryName(String category, String selectedLabel) {
    final standardName = switch (category) {
      'economico' => 'Económico',
      'confort' => 'Confort',
      'txopela' => 'Txopela',
      'moto' => 'Moto',
      _ => null,
    };
    if (standardName != null) return standardName;
    return selectedLabel.trim().isNotEmpty ? selectedLabel : 'Viatura';
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<PassengerState>(context);
    final vehicle = appState.driverVehicle;
    final category = appState.carCategory;
    final categoryName = _categoryName(category, appState.selectedCarType);
    final model = vehicle?['model']?.toString().trim() ?? '';
    final color = vehicle?['color']?.toString().trim() ?? '';
    final plate = vehicle?['plate']?.toString().trim() ?? '';
    final seats = vehicle?['seats']?.toString().trim() ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 350;
        final iconSize = compact ? 62.0 : 72.0;

        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 8.h),
          padding: EdgeInsets.all(compact ? 14.w : 16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: const Color(0xFFE9EAE3)),
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
                child: const Divider(height: 1, color: Color(0xFFE9EAE3)),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8DF),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: _gold.withValues(alpha: 0.45)),
                    ),
                    child: ExcludeSemantics(
                      child: Icon(
                        CarData.categoryIcon(category),
                        size: compact ? 36.sp : 42.sp,
                        color: _ink,
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CATEGORIA ESCOLHIDA',
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.65,
                            color: _muted,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            height: 1.15,
                          ),
                        ),
                        if (model.isNotEmpty || color.isNotEmpty) ...[
                          SizedBox(height: 3.h),
                          Text(
                            [
                              if (model.isNotEmpty) model,
                              if (color.isNotEmpty) color,
                            ].join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              color: _muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (plate.isNotEmpty)
                    _InfoChip(
                      icon: Icons.confirmation_number_outlined,
                      label: plate,
                    ),
                  if (seats.isNotEmpty)
                    _InfoChip(
                      icon: Icons.event_seat_outlined,
                      label: '$seats lugares',
                    ),
                  _FarePill(amount: appState.estimatedPrice.ceil()),
                ],
              ),
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

class _FarePill extends StatelessWidget {
  const _FarePill({required this.amount});
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 38.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: const Color(0xFF202520),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Text(
        '$amount MT estimado',
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 38.h, maxWidth: 170.w),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F1),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15.sp, color: SelectedCarCard._muted),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: SelectedCarCard._ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

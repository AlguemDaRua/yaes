import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/passenger/models/cardata.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:provider/provider.dart';

class SelectedCarCard extends StatelessWidget {
  static const Color _accentColor = Color(0xffe5a400);

  const SelectedCarCard({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<PassengerState>(context);

    // Só dados reais: veículo do motorista aceite (espelho do painel) e
    // preço estimado do servidor. Sem catálogo fictício.
    final vehicle = appState.driverVehicle;
    final vehiclePhoto = vehicle?['photoUrl']?.toString();

    return Container(
      width: double.infinity,
      height: 200.sp,
      margin: EdgeInsets.only(bottom: 12.sp),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, _accentColor.withAlpha(16)],
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: _accentColor.withAlpha(35), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),

          // Foto real do veículo (painel) ou ícone da categoria
          Positioned(
            right: -16.sp,
            bottom: -8.sp,
            child: Opacity(
              opacity: 0.95,
              child: vehiclePhoto != null && vehiclePhoto.isNotEmpty
                  ? Image.network(
                      vehiclePhoto,
                      width: 210.sp,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Padding(
                        padding:
                            EdgeInsets.only(right: 50.sp, bottom: 30.sp),
                        child: Icon(
                          CarData.categoryIcon(appState.carCategory),
                          size: 80.sp,
                          color: _accentColor,
                        ),
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.only(right: 50.sp, bottom: 30.sp),
                      child: Icon(
                        CarData.categoryIcon(appState.carCategory),
                        size: 80.sp,
                        color: _accentColor,
                      ),
                    ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(16.sp, 14.sp, 130.sp, 14.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 38.sp,
                      width: 38.sp,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: appState.driverPhotoUrl.isNotEmpty
                            ? Image.network(
                                appState.driverPhotoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: Colors.grey.withAlpha(40),
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.grey,
                                        size: 24.sp,
                                      ),
                                    ),
                              )
                            : Container(
                                color: Colors.grey.withAlpha(40),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                  size: 24.sp,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: 10.sp),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appState.driverName.isNotEmpty
                                ? appState.driverName
                                : "Motorista",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5.sp,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 2.sp),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.sp,
                                  vertical: 4.sp,
                                ),
                                decoration: BoxDecoration(
                                  color: _accentColor.withAlpha(20),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Novo',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10.5.sp,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.sp),
                              RatingBarIndicator(
                                rating: 0,
                                itemBuilder: (context, index) => const Icon(
                                  Icons.star_rounded,
                                  color: _accentColor,
                                ),
                                itemCount: 5,
                                itemSize: 14.0.sp,
                                direction: Axis.horizontal,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.sp,
                        vertical: 6.sp,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(210),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.black.withAlpha(10)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14.sp,
                            color: Colors.black54,
                          ),
                          SizedBox(width: 6.sp),
                          Text(
                            '${appState.durationMin} min',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5.sp,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.sp),
                Text(
                  vehicle?['model'] ?? appState.selectedCarType,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 18.sp,
                    color: Colors.black,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4.sp),
                Text(
                  vehicle?['color'] != null
                      ? '${vehicle!['color']} • ${appState.selectedCarType}'
                      : appState.selectedCarType,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 12.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                Wrap(
                  spacing: 8.sp,
                  runSpacing: 8.sp,
                  children: [
                    _InfoChip(
                      icon: Icons.confirmation_number_rounded,
                      label: vehicle?['plate']?.toString() ?? '—',
                    ),
                    _InfoChip(
                      icon: Icons.event_seat_rounded,
                      label: '${vehicle?['seats'] ?? '—'} lugares',
                    ),
                  ],
                ),
                SizedBox(height: 10.sp),
                Row(
                  children: [
                    Text(
                      '${appState.estimatedPrice.ceil()} MT',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 18.sp,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 8.sp),
                    Text(
                      'estimativa',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 11.5.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  static const Color _accentColor = Color(0xffe5a400);
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 7.sp),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(220),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _accentColor.withAlpha(35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: _accentColor),
          SizedBox(width: 6.sp),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 11.5.sp,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

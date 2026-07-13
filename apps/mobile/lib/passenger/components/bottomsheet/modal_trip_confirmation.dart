import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/asset_paths.dart';

Future<bool?> showTripConfirmationModal(
  BuildContext context, {
  required String originAddress,
  required String destinationAddress,
  required List<Map<String, dynamic>> stops,
  required double price,
  required String paymentMethod,
  required Map<String, dynamic> car,
  DateTime? timeSchedule,
}) {
  return showModalBottomSheet<bool>(
    isDismissible: true,
    backgroundColor: Colors.white,
    enableDrag: true,
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext context) {
      String paymentIcon = AssetPaths.mpesa;
      Color? iconColor;
      String paymentName = 'M-Pesa';

      if (paymentMethod == 'emola') {
        paymentIcon = AssetPaths.emola;
        iconColor = Colors.orange;
        paymentName = 'E-Mola';
      } else if (paymentMethod == 'cartao') {
        paymentIcon = AssetPaths.creditCard;
        paymentName = 'Cartão';
      }

      return Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 12.sp),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 18.sp),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.sp),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.sp),
                    decoration: BoxDecoration(
                      color: const Color(0xffe5a400).withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      color: const Color(0xffe5a400),
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.sp),
                  Text(
                    'Confirmar Viagem',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 18.sp,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.sp),

            // Trip Details
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.sp),
              child: Container(
                padding: EdgeInsets.all(16.sp),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withAlpha(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // origin
                    Row(
                      children: [
                        Icon(
                          Icons.my_location,
                          size: 16.sp,
                          color: Colors.amber,
                        ),
                        SizedBox(width: 8.sp),
                        Expanded(
                          child: Text(
                            originAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 7.sp),
                      child: Container(
                        width: 2,
                        height: 16.sp,
                        color: Colors.grey.withAlpha(80),
                      ),
                    ),
                    // stops
                    ...stops.map(
                      (stop) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.stop_circle_outlined,
                                size: 16.sp,
                                color: Colors.blue,
                              ),
                              SizedBox(width: 8.sp),
                              Expanded(
                                child: Text(
                                  stop['name'] ?? 'Paragem',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.sp,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 7.sp),
                            child: Container(
                              width: 2,
                              height: 16.sp,
                              color: Colors.grey.withAlpha(80),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // destiny
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16.sp, color: Colors.red),
                        SizedBox(width: 8.sp),
                        Expanded(
                          child: Text(
                            destinationAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.sp),
                    Divider(color: Colors.grey.withAlpha(40)),
                    SizedBox(height: 12.sp),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Veículo',
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          car['name'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    if (timeSchedule != null) ...[
                      SizedBox(height: 8.sp),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Agendado para',
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            "${timeSchedule.day.toString().padLeft(2, '0')}/${timeSchedule.month.toString().padLeft(2, '0')} ${timeSchedule.hour.toString().padLeft(2, '0')}:${timeSchedule.minute.toString().padLeft(2, '0')}",
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.sp),

            // Highlighted Price and Payment
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.sp),
              child: Container(
                padding: EdgeInsets.all(16.sp),
                decoration: BoxDecoration(
                  color: const Color(0xffe5a400).withAlpha(15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xffe5a400),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A Pagar',
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          '${price.ceil()} MT',
                          style: GoogleFonts.poppins(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.sp,
                        vertical: 8.sp,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            paymentIcon,
                            width: 24.sp,
                            color: iconColor,
                          ),
                          SizedBox(width: 8.sp),
                          Text(
                            paymentName,
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24.sp),

            // Actions
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.sp),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.sp),
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(25),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.sp),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.sp),
                        decoration: BoxDecoration(
                          color: const Color(0xffe5a400),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xffe5a400).withAlpha(80),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Confirmar Viagem',
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.sp),
          ],
        ),
      );
    },
  );
}

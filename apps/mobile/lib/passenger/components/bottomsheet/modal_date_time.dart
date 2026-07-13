import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

Future<DateTime?> showDateTimeModal(BuildContext context) async {
  // DateTime? selectedDate;

  return await showModalBottomSheet(
    context: context,
    isDismissible: true,
    enableDrag: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      DateTime tempDate = DateTime.now();

      return StatefulBuilder(
        builder: (context, setState) {
          // formatadores
          final formattedDay = DateFormat(
            "EEE, d MMM",
            "pt_BR",
          ).format(tempDate);
          final formattedTime = DateFormat("HH:mm").format(tempDate);

          return Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Handle bar ──
                SizedBox(height: 12.sp),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                SizedBox(height: 18.sp),

                // ── Title row with icon badge ──
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
                          Icons.schedule_rounded,
                          color: const Color(0xffe5a400),
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.sp),
                      Text(
                        'Programa sua viagem',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 18.sp,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6.sp),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.sp),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 44.sp),
                      child: Text(
                        'Escolha a data e hora da viagem',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 18.sp),

                // ── Date / Time display card ──
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 18.sp),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.sp,
                    vertical: 14.sp,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffe5a400).withAlpha(15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xffe5a400).withAlpha(60),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Date display
                      Row(
                        children: [
                          Container(
                            width: 40.sp,
                            height: 40.sp,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(8),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              color: const Color(0xffe5a400),
                              size: 18.sp,
                            ),
                          ),
                          SizedBox(width: 10.sp),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.sp,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                formattedDay,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Divider
                      Container(
                        width: 1,
                        height: 36.sp,
                        color: const Color(0xffe5a400).withAlpha(50),
                      ),
                      // Time display
                      Row(
                        children: [
                          Container(
                            width: 40.sp,
                            height: 40.sp,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(8),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.access_time_rounded,
                              color: const Color(0xffe5a400),
                              size: 18.sp,
                            ),
                          ),
                          SizedBox(width: 10.sp),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hora',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.sp,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                formattedTime,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.sp),

                // ── Cupertino Date Picker ──
                SizedBox(
                  height: 160.sp,
                  child: CupertinoDatePicker(
                    showTimeSeparator: true,
                    mode: CupertinoDatePickerMode.dateAndTime,
                    use24hFormat: true,
                    minimumDate: DateTime.now(),
                    initialDateTime: DateTime.now(),
                    onDateTimeChanged: (DateTime newDate) {
                      setState(() {
                        tempDate = newDate;
                      });
                    },
                  ),
                ),

                SizedBox(height: 20.sp),

                // ── Action buttons ──
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.sp),
                  child: Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context, null),
                          child: Container(
                            height: 54.sp,
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(30),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                'Cancelar',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade600,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.sp),
                      // Confirm button
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context, tempDate),
                          child: Container(
                            height: 54.sp,
                            decoration: BoxDecoration(
                              color: const Color(0xffe5a400),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xffe5a400).withAlpha(80),
                                  spreadRadius: 0,
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Concluído',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
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
    },
  );
}

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchingDriver extends StatefulWidget {
  const SearchingDriver({super.key});

  @override
  State<SearchingDriver> createState() => _SearchingDriverState();
}

class _SearchingDriverState extends State<SearchingDriver> {
  static const Color _accentColor = Color(0xffe5a400);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160.sp,
      margin: EdgeInsets.only(bottom: 12.sp),
      child: Container(
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
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.sp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 50.sp,
                  width: 50.sp,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Container(
                      color: Colors.grey.withAlpha(40),
                      child: Icon(Icons.person, color: Colors.grey, size: 28.sp),
                    ),
                  ),
                ),
                SizedBox(width: 14.sp),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Notificando motorista',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 16.sp,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: 6.sp),
                          DefaultTextStyle(
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 16.sp,
                              color: Colors.black,
                            ),
                            child: AnimatedTextKit(
                              animatedTexts: [
                                TyperAnimatedText(
                                  '.',
                                  speed: const Duration(milliseconds: 300),
                                ),
                                TyperAnimatedText(
                                  '..',
                                  speed: const Duration(milliseconds: 300),
                                ),
                                TyperAnimatedText(
                                  '...',
                                  speed: const Duration(milliseconds: 300),
                                ),
                              ],
                              isRepeatingAnimation: true,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.sp),
                      Text(
                        'Isso pode levar alguns segundos.',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

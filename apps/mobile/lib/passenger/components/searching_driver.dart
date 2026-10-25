import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/passenger/models/cardata.dart';

class SearchingDriver extends StatelessWidget {
  const SearchingDriver({super.key, this.category = 'economico'});

  final String category;

  String get _categoryName => switch (category) {
    'economico' => 'Económico',
    'confort' => 'Confort',
    'txopela' => 'Txopela',
    'moto' => 'Moto',
    _ => 'Viatura',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFE9EAE3)),
      ),
      child: Row(
        children: [
          Container(
            width: 58.w,
            height: 58.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8DF),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: ExcludeSemantics(
              child: Icon(
                CarData.categoryIcon(category),
                size: 31.sp,
                color: const Color(0xFF202520),
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A procurar motorista',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF202520),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Categoria $_categoryName · a contactar motoristas próximos',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    height: 1.4,
                    color: const Color(0xFF74786E),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          SizedBox(
            width: 22.w,
            height: 22.w,
            child: const CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFFE5A400),
            ),
          ),
        ],
      ),
    );
  }
}

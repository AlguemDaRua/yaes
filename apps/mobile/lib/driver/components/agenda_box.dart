// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:limousineexecutive/utils/asset_paths.dart';

// class AgendaBox extends StatelessWidget {
//   const AgendaBox({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final appState = Provider.of<DriverState>(context, listen: false);
//     return Container(
//       padding: EdgeInsets.only(
//         left: 5.sp,
//         bottom: 5.sp,
//         top: 5.sp,
//         right: 10.sp,
//       ),
//       height: 60.sp,
//       width: 150.sp,
//       decoration: BoxDecoration(
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.39),
//             spreadRadius: 1,
//             blurRadius: 12,
//             offset: Offset(0, 0), // changes position of shadow
//           ),
//         ],
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         children: [
//           Container(
//             height: 47.sp,
//             width: 47.sp,
//             padding: EdgeInsets.all(7.w),
//             decoration: BoxDecoration(
//               color: Colors.grey[300],
//               shape: BoxShape.circle,
//               border: Border.all(color: appState.mainColor, width: 1.sp),
//             ),
//             // child: Icon(Icons.attach_money, color: Colors.green, size: 40.sp),
//             child: Image.asset(
//               AssetPaths.agenda,
//               color: Colors.black.withOpacity(0.59),
//             ),
//           ),
//           SizedBox(width: 10.sp),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Align(
//                 child: Text(
//                   "Agenda",
//                   style: TextStyle(
//                     fontSize: 14.sp,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.black,
//                   ),
//                 ),
//               ),
//               Text(
//                 "8",
//                 style: TextStyle(
//                   fontSize: 16.sp,
//                   fontWeight: FontWeight.bold,
//                   color: appState.mainColor,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/utils/asset_paths.dart';

class AgendaBox extends StatelessWidget {
  const AgendaBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70.sp,
      width: 160.sp,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.85),
            Colors.black.withValues(alpha: 0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 10.w),
            height: 50.sp,
            width: 50.sp,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: Image.asset(AssetPaths.agenda, color: Colors.amberAccent),
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Agenda",
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                "8",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.amberAccent,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 6,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

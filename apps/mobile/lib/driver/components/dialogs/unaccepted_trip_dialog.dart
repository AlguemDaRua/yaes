// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// void showUnacceptedDialog(BuildContext context) {
//   showDialog(
//     context: context,
//     barrierDismissible: true,
//     builder: (context) {
//       return Dialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16.r),
//         ),
//         backgroundColor: Colors.white,
//         child: Padding(
//           padding: EdgeInsets.all(20.w),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(Icons.call_end, color: Colors.red, size: 48.sp),
//               SizedBox(height: 12.h),
//               Text(
//                 'Corrida Recusada',
//                 style: TextStyle(
//                   fontSize: 18.sp,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//               SizedBox(height: 8.h),
//               Text(
//                 'Quanto mais chamadas recusadas, menor será a sua pontuação como motorista.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
//               ),
//               SizedBox(height: 20.h),
//               ElevatedButton.icon(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.redAccent,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8.r),
//                   ),
//                   padding: EdgeInsets.symmetric(
//                     horizontal: 24.w,
//                     vertical: 12.h,
//                   ),
//                 ),
//                 // icon: Icon(Icons.close, size: 20.sp, color: Colors.white),
//                 label: Text(
//                   'Fechar',
//                   style: TextStyle(fontSize: 14.sp, color: Colors.white),
//                 ),
//                 onPressed: () => Navigator.of(context).pop(),
//               ),
//             ],
//           ),
//         ),
//       );
//     },
//   );
// }

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void showUnacceptedDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.85),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.call_end, color: Colors.redAccent, size: 48.sp),
              SizedBox(height: 12.h),
              Text(
                'Corrida Recusada',
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
              SizedBox(height: 8.h),
              Text(
                'Quanto mais chamadas recusadas, menor será a sua pontuação como motorista.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: Colors.white70),
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black,
                  shadowColor: Colors.amber.withValues(alpha: 0.4),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                ),
                child: Text(
                  'Fechar',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );
}

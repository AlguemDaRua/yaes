// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:limousineexecutive/driver/components/buttons/online_switch.dart';
// import 'package:limousineexecutive/driver/models/driver_state.dart';
// import 'package:provider/provider.dart';

// class StatusBox extends StatelessWidget {
//   final VoidCallback? onTap;
//   const StatusBox({super.key, this.onTap});
//   @override
//   Widget build(BuildContext context) {
//     final appState = Provider.of<DriverState>(context);

//     return Container(
//       height: 50.sp,
//       width: 270.sp,
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
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           // Icon de peessoa
//           Icon(
//             Icons.person,
//             size: 40.sp,
//             color: Colors.black.withOpacity(0.59),
//           ),

//           //
//           Row(
//             children: [
//               Icon(
//                 Icons.circle,
//                 color: appState.isOnline ? appState.mainColor : Colors.red,
//                 size: 15.sp,
//               ),
//               SizedBox(width: 5.sp),
//               Text(
//                 appState.isOnline ? 'Online' : 'Offline',
//                 style: TextStyle(
//                   fontSize: 16.sp,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//           OnlineSwitch(onTap: onTap),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/driver/components/buttons/menu_button.dart';
import 'package:limousineexecutive/driver/components/buttons/online_switch.dart';
import 'package:limousineexecutive/driver/models/driver_state.dart';
import 'package:provider/provider.dart';

class TopBar extends StatelessWidget {
  final VoidCallback? onTap;
  const TopBar({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<DriverState>(context);

    return Container(
      height: 60.sp,
      width: 280.sp,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.r),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const MenuButton(),

          // // Person icon with glow
          // Container(
          //   decoration: BoxDecoration(
          //     shape: BoxShape.circle,
          //     color: Colors.white.withOpacity(0.15),
          //     border: Border.all(
          //       color: Colors.white.withOpacity(0.6),
          //       width: 1.5,
          //     ),
          //     boxShadow: [
          //       BoxShadow(
          //         color: Colors.amber.withOpacity(0.4),
          //         blurRadius: 8,
          //         spreadRadius: 2,
          //       ),
          //     ],
          //   ),
          //   padding: EdgeInsets.all(6.w),
          //   child: Icon(
          //     Icons.person,
          //     size: 28.sp,
          //     color: Colors.amberAccent,
          //     shadows: [
          //       Shadow(
          //         color: Colors.black.withOpacity(0.5),
          //         blurRadius: 6,
          //         offset: const Offset(1, 1),
          //       ),
          //     ],
          //   ),
          // ),

          // Status Online/Offline
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.r),
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
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  color: appState.isOnline
                      ? Colors.amberAccent
                      : Colors.redAccent,
                  size: 14.sp,
                ),
                SizedBox(width: 6.sp),
                Text(
                  appState.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 4,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Switch estilizado
          OnlineSwitch(onTap: onTap),
        ],
      ),
    );
  }
}

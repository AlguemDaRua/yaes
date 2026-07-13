// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:limousineexecutive/driver/models/driver_state.dart';
// import 'package:provider/provider.dart';

// class MenuButton extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final appState = Provider.of<DriverState>(context);

//     return InkWell(
//       onTap: () {
//         Navigator.pushNamed(context, '/driver_menu');
//       },
//       child: Container(
//         padding: EdgeInsets.all(8.sp),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           shape: BoxShape.circle,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.39),
//               spreadRadius: 1,
//               blurRadius: 12,
//               offset: Offset(0, 0), // changes position of shadow
//             ),
//           ],
//         ),
//         child: Icon(
//           Icons.menu,
//           size: 30.sp,
//           color: Colors.black.withOpacity(0.59),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MenuButton extends StatelessWidget {
  const MenuButton({super.key});

  @override
  Widget build(BuildContext context) {

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/driver_menu');
      },
      child: Container(
        padding: EdgeInsets.all(5.sp),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.blueGrey.withValues(alpha: 0.2),
              Colors.blueGrey.withValues(alpha: 0.1),
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
        child: Icon(
          Icons.menu,
          size: 30.sp,
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
    );
  }
}

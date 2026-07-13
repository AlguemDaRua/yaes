import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/driver/models/driver_state.dart';
import 'package:limousineexecutive/utils/asset_paths.dart';
import 'package:provider/provider.dart';

class GainBox extends StatelessWidget {
  const GainBox({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<DriverState>(context, listen: false);

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/my_gain'),
      child: Container(
        padding: EdgeInsets.only(
          left: 5.sp,
          bottom: 5.sp,
          top: 5.sp,
          right: 10.sp,
        ),
        height: 60.sp,
        width: 150.sp,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.39),
              spreadRadius: 1,
              blurRadius: 12,
              offset: const Offset(0, 0), // changes position of shadow
            ),
          ],
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              height: 47.sp,
              width: 47.sp,
              padding: EdgeInsets.all(7.w),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
                border: Border.all(color: appState.mainColor, width: 1.sp),
              ),
              child: Image.asset(
                AssetPaths.moneySack,
                color: Colors.black.withValues(alpha: 0.59),
              ),
            ),
            SizedBox(width: 10.sp),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Ganhos",
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "5000.00MZn",
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: appState.mainColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

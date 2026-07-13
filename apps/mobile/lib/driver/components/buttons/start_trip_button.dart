import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/utils/asset_paths.dart';

class StartTripButton extends StatelessWidget {
  final VoidCallback? onTap;
  const StartTripButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap!();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8.sp),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.59),
              shape: BoxShape.circle,
            ),
            child: Column(
              children: [Image.asset(AssetPaths.sendIcon, width: 40.sp)],
            ),
          ),
          SizedBox(height: 5.sp),
          Text(
            'Iniciar',
            style: TextStyle(
              fontSize: 20.sp,
              color: Colors.amber.withValues(alpha: 0.59),
            ),
          ),
        ],
      ),
    );
  }
}

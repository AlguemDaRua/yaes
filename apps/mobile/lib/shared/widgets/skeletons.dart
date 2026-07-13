import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'skeleton.dart';

class VehicleTypeSkeleton extends StatelessWidget {
  const VehicleTypeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 75.sp,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        padding: EdgeInsets.symmetric(horizontal: 16.sp),
        itemBuilder: (context, index) => Container(
          width: 75.sp,
          margin: EdgeInsets.only(right: 12.sp),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Stack(
            children: [
              // Image placeholder area
              Positioned(
                top: 10.sp,
                left: 10.sp,
                right: 10.sp,
                bottom: 20.sp,
                child: Skeleton(borderRadius: 8.r),
              ),
              // Text placeholder area
              Positioned(
                bottom: 5.sp,
                left: 15.sp,
                right: 15.sp,
                child: Skeleton(height: 10.sp, borderRadius: 4.r),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RideHistorySkeleton extends StatelessWidget {
  const RideHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20.sp),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        margin: EdgeInsets.only(bottom: 16.sp),
        padding: EdgeInsets.all(16.sp),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Row: Avatar + Name + Price
            Row(
              children: [
                Skeleton(height: 45.sp, width: 45.sp, borderRadius: 100),
                SizedBox(width: 12.sp),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(height: 14.sp, width: 100.sp),
                      SizedBox(height: 6.sp),
                      Skeleton(height: 10.sp, width: 60.sp),
                    ],
                  ),
                ),
                Skeleton(height: 20.sp, width: 60.sp, borderRadius: 6.r),
              ],
            ),
            SizedBox(height: 16.sp),
            // Route Points
            Column(
              children: [
                Row(
                  children: [
                    Skeleton(height: 16.sp, width: 16.sp, borderRadius: 100),
                    SizedBox(width: 12.sp),
                    Skeleton(height: 12.sp, width: 220.sp),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(left: 7.sp, top: 4.sp, bottom: 4.sp),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Skeleton(height: 12.sp, width: 2.sp),
                  ),
                ),
                Row(
                  children: [
                    Skeleton(height: 16.sp, width: 16.sp, borderRadius: 100),
                    SizedBox(width: 12.sp),
                    Skeleton(height: 12.sp, width: 180.sp),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16.sp),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            SizedBox(height: 12.sp),
            // Footer: Verification badge + Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Skeleton(height: 14.sp, width: 80.sp),
                Skeleton(height: 14.sp, width: 70.sp),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar circle
        Skeleton(height: 70.sp, width: 70.sp, borderRadius: 20.r),
        SizedBox(width: 16.sp),
        // Name and Contact lines
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Skeleton(height: 18.sp, width: 140.sp, borderRadius: 4.r),
            SizedBox(height: 10.sp),
            Row(
              children: [
                Skeleton(height: 16.sp, width: 16.sp, borderRadius: 100),
                SizedBox(width: 8.sp),
                Skeleton(height: 14.sp, width: 100.sp, borderRadius: 4.r),
              ],
            ),
          ],
        ),
        const Spacer(),
        // Chat button placeholder
        Skeleton(height: 50.sp, width: 50.sp, borderRadius: 100),
      ],
    );
  }
}

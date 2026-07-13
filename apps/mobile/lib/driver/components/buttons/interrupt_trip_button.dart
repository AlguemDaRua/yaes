import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/driver/models/driver_state.dart';
import 'package:provider/provider.dart';

class InterruptTripButton extends StatelessWidget {
  const InterruptTripButton({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<DriverState>(context, listen: false);

    return InkWell(
      onTap: () {
        appState.endTrip();
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.sp, horizontal: 20.sp),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('Interromper', style: TextStyle(fontSize: 16.sp)),
      ),
    );
  }
}

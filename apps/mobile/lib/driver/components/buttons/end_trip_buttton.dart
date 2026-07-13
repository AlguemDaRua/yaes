import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/driver/components/dialog_end_trip.dart';
import 'package:limousineexecutive/driver/models/driver_state.dart';
import 'package:provider/provider.dart';

class EndTripButtton extends StatelessWidget {
  const EndTripButtton({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<DriverState>(context, listen: false);

    return InkWell(
      onTap: () {
        showCustomPopup(context);
        appState.endTrip();
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.sp, horizontal: 20.sp),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.59),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Concluir Viagem',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

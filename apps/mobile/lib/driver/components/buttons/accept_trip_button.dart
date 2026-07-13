import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/driver/models/driver_state.dart';
import 'package:provider/provider.dart';

class AcceptTripButton extends StatelessWidget {
  const AcceptTripButton({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<DriverState>(context, listen: false);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        // onTap: () => mostrarPopupPersonalizado(context),
        onTap: () {
          appState.acceptTrip();
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: 50.sp,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.59),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                'Aceitar',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

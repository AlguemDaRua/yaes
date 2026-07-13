import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/passenger/components/car_type_options_horizontal.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:limousineexecutive/passenger/widgets/car_options_list.dart';
import 'package:limousineexecutive/passenger/widgets/location_inputs.dart';
import 'package:limousineexecutive/passenger/widgets/location_search_sheet.dart';
import 'package:provider/provider.dart';

class ChooseCarSheet extends StatelessWidget {
  final DraggableScrollableController sheetController;
  final VoidCallback onRouteChanged;
  final VoidCallback onTripRequested;
  final VoidCallback onStopRequested;

  const ChooseCarSheet({
    super.key,
    required this.sheetController,
    required this.onRouteChanged,
    required this.onTripRequested,
    required this.onStopRequested,
  });

  void _animateSheet(double size) {
    if (sheetController.isAttached) {
      sheetController.animateTo(
        size,
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<PassengerState>(context);
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        final hasFocus =
            appState.showDestinationOptions || appState.showPickupOptions;
        if (hasFocus) {
          const double lockedSize = 0.9;
          if ((sheetController.size - lockedSize).abs() > 0.001) {
            sheetController.jumpTo(lockedSize);
          }
          return true;
        }
        return false;
      },
      child: DraggableScrollableSheet(
        controller: sheetController,
        expand: true,
        initialChildSize: 0.9,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        snap: (appState.showDestinationOptions || appState.showPickupOptions)
            ? false
            : true,
        snapSizes: const [0.5],
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 8.sp),
                        // Drag handle
                        Container(
                          width: 100.sp,
                          height: 4.sp,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(height: 8.sp),

                        // Location inputs
                        LocationInputs(
                          onRouteChanged: onRouteChanged,
                          onStopRequested: onStopRequested,
                        ),
                      ],
                    ),
                  ),

                  // Location search results
                  if ((appState.showDestinationOptions ||
                          appState.showPickupOptions) &&
                      !appState.isPaymentSelected)
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 625.sp),
                      child: LocationSearchSheet(
                        onRouteChanged: onRouteChanged,
                        onAnimateSheet: _animateSheet,
                      ),
                    ),

                  // Car options list
                  if (!appState.showDestinationOptions &&
                      !appState.showPickupOptions &&
                      appState.selectedCarType.isNotEmpty &&
                      !appState.isPaymentSelected)
                    Column(
                      children: [
                        Divider(
                          color: Colors.grey.withAlpha(88),
                          thickness: 1.0.sp,
                          height: 0.sp,
                          indent: 10.sp,
                          endIndent: 10.sp,
                        ),
                        SizedBox(height: 10.sp),

                        const CarTypeOptionsHorizontal(),

                        SizedBox(height: 10.sp),

                        Container(
                          padding: EdgeInsets.only(left: 4.sp, right: 4.sp),
                          decoration: const BoxDecoration(
                            color: Colors.amberAccent,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          child: Text(
                            'ESCOLHA O SEU TRANSPORTE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20.sp,
                              fontFamily: 'Gagalin',
                              letterSpacing: 0.sp,
                            ),
                          ),
                        ),

                        SizedBox(height: 5.sp),

                        Divider(
                          color: Colors.grey.withAlpha(88),
                          thickness: 1.0.sp,
                          height: 0.sp,
                          indent: 60.sp,
                          endIndent: 60.sp,
                        ),
                        SizedBox(height: 10.sp),

                        Container(
                          color: Colors.transparent,
                          height: (appState.destinationLocation != null)
                              ? 498.sp
                              : 550.sp,
                          child: CarOptionsList(
                            onTripRequested: onTripRequested,
                            onAnimateSheet: _animateSheet,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/passenger/components/cart_type_options_grid.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:limousineexecutive/passenger/widgets/location_inputs.dart';
import 'package:limousineexecutive/passenger/widgets/location_search_sheet.dart';
import 'package:limousineexecutive/utils/asset_paths.dart';
import 'package:provider/provider.dart';

class CarTypeSelector extends StatelessWidget {
  final VoidCallback onRouteChanged;
  final VoidCallback onStopRequested;
  final void Function(double size) onAnimateSheet;

  const CarTypeSelector({
    super.key,
    required this.onRouteChanged,
    required this.onStopRequested,
    required this.onAnimateSheet,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<PassengerState>(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: LocationInputs(
              onRouteChanged: onRouteChanged,
              onStopRequested: onStopRequested,
            ),
          ),

          // Location search results
          if ((appState.showDestinationOptions || appState.showPickupOptions) &&
              !appState.isPaymentSelected)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.of(context).size.height * 0.85 -
                    MediaQuery.of(context).padding.top -
                    16.sp,
                minHeight:
                    MediaQuery.of(context).size.height * 0.85 -
                    MediaQuery.of(context).padding.top -
                    16.sp,
              ),
              child: LocationSearchSheet(
                onRouteChanged: onRouteChanged,
                onAnimateSheet: onAnimateSheet,
              ),
            ),

          // Car type grid
          if (!(appState.showDestinationOptions || appState.showPickupOptions) &&
              appState.selectedCarType.isEmpty &&
              !appState.isPaymentSelected)
            Column(
              children: [
                SizedBox(height: 8.sp),
                Row(
                  children: [
                    SizedBox(width: 35.sp),
                    Image.asset(AssetPaths.arrow, height: 30.sp),
                    SizedBox(width: 20.sp),
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
                          fontSize: 18.sp,
                          fontFamily: 'Gagalin',
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const CartTypeOptionsGrid(),
              ],
            ),
        ],
      ),
    );
  }
}

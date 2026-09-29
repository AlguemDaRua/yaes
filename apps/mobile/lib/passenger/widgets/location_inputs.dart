import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/passenger/components/textfields/location_textfield.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:limousineexecutive/passenger/pages/pick_location_on_map.dart';
import 'package:limousineexecutive/utils/blink_textfield.dart';
import 'package:provider/provider.dart';

class LocationInputs extends StatelessWidget {
  final VoidCallback onRouteChanged;
  final VoidCallback onStopRequested;

  const LocationInputs({
    super.key,
    required this.onRouteChanged,
    required this.onStopRequested,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<PassengerState>(context);
    return Column(
      children: [
        // Origin textfield (only show if destination is set)
        if (appState.toAddress.isNotEmpty &&
            appState.destinationLocation != null)
          Row(
            children: [
              Expanded(
                flex: 8,
                child: originTextField(
                  label: "De",
                  textValue: appState.fromAddress,
                  onChanged: (value) {
                    appState.fromAddress = value;
                  },
                  controller: appState.controllerPickup,
                  context: context,
                ),
              ),
              if (appState.focusNodePickup.hasFocus)
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PickLocationOnMap(text: 'De'),
                        ),
                      );
                      // ignore: use_build_context_synchronously
                      FocusScope.of(context).unfocus();
                      onRouteChanged();
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 18.sp),
                      height: 30.sp,
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(40),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Center(child: Text('Mapa')),
                    ),
                  ),
                ),
            ],
          ),

        // Divider
        if (appState.toAddress.isNotEmpty &&
            appState.destinationLocation != null)
          Divider(
            color: Colors.grey.withAlpha(88),
            thickness: 1.0.sp,
            height: 0.sp,
            indent: 18.sp,
            endIndent: 18.sp,
          ),

        // Destination textfield
        Row(
          children: [
            Expanded(
              flex: 8,
              child: BlinkingBorder(
                blink: appState.blinkDestinationField,
                child: destinationTextField(
                  label: "Para",
                  textValue: appState.toAddress,
                  onChanged: (value) {
                    appState.toAddress = value;
                    appState.blinkDestinationField = false;
                    onRouteChanged();
                  },
                  controller: appState.controllerDestination,
                  context: context,
                  onTap: () {
                    appState.blinkDestinationField = false;
                  },
                ),
              ),
            ),
            // SizedBox(width: 8.sp),
            // Stops button
            if (appState.toAddress.isNotEmpty &&
                appState.destinationLocation != null &&
                !appState.focusNodeDestination.hasFocus)
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: () {
                    onStopRequested();
                    FocusScope.of(context).unfocus();
                  },
                  child: Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 18.sp),
                        height: 30.sp,
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(40),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Center(child: Text('Paragens')),
                      ),
                      if (appState.stops.isNotEmpty)
                        Positioned(
                          top: 2.sp,
                          right: 23.sp,
                          child: Text(
                            appState.stops.length.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            // Map button (when destination field focused)
            if (appState.focusNodeDestination.hasFocus)
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PickLocationOnMap(text: 'Para'),
                      ),
                    );
                    // ignore: use_build_context_synchronously
                    FocusScope.of(context).unfocus();
                    onRouteChanged();
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 18.sp),
                    height: 30.sp,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(40),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(child: Text('Mapa')),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

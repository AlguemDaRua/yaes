import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:limousineexecutive/services/location_service.dart';
import 'package:limousineexecutive/utils/asset_paths.dart';
import 'package:limousineexecutive/passenger/components/location_suggestion_card.dart';
import 'package:provider/provider.dart';

class LocationSearchSheet extends StatelessWidget {
  final VoidCallback onRouteChanged;
  final void Function(double size) onAnimateSheet;

  const LocationSearchSheet({
    super.key,
    required this.onRouteChanged,
    required this.onAnimateSheet,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<PassengerState>(context);
    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      children: [
        if (appState.showPickupOptions)
          LocationSuggestionCard(
            title: 'Minha localização',
            subtitle: 'Usar localização atual do GPS',
            customLeading: Container(
              width: 40.sp,
              height: 40.sp,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(AssetPaths.location, scale: 25),
              ),
            ),
            onTap: () {
              appState.fromAddress = 'Minha localização';
              appState.originLocation = appState.currentLocation;
              appState.controllerPickup.text = 'Minha localização';
              if (appState.fromAddress.isNotEmpty &&
                  appState.toAddress.isNotEmpty) {
                onRouteChanged();
              }
              appState.focusNodePickup.unfocus();
              appState.showPickupOptions = false;
            },
          ),
        ...List.generate(appState.address.length, (index) {
          final addr = appState.address[index];
          return LocationSuggestionCard(
            title: addr["name"] as String,
            subtitle: addr["fullName"] as String,
            iconData: LocationService.iconForPlace(addr["type"]),
            onTap: () {
              if (appState.showPickupOptions) {
                appState.fromAddress = addr["name"] as String;
                appState.originLocation = addr["latlong"];
                appState.controllerPickup.text = addr["name"] as String;

                if (appState.fromAddress.isNotEmpty &&
                    appState.toAddress.isNotEmpty) {
                  onRouteChanged();
                }
              } else if (appState.showDestinationOptions) {
                appState.toAddress = addr["name"] as String;
                appState.destinationLocation = addr["latlong"];
                appState.controllerDestination.text = addr["name"] as String;

                if (appState.fromAddress.isNotEmpty &&
                    appState.toAddress.isNotEmpty) {
                  onRouteChanged();
                }

                appState.showDestinationOptions = false;

                if (appState.selectedCarTypeindex != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    onAnimateSheet(0.9);
                  });
                }
              }

              appState.focusNodePickup.unfocus();
              appState.focusNodeDestination.unfocus();
              appState.showDestinationOptions = false;
              appState.showPickupOptions = false;
            },
          );
        }),
      ],
    );
  }
}

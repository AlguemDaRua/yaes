import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/passenger/components/dialogs/default_dialog.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:limousineexecutive/services/location_service.dart';
import 'package:limousineexecutive/utils/asset_paths.dart';
import 'package:provider/provider.dart';

Widget locationTextField({
  required String label,
  required String textValue,
  required Function(String) onChanged,
  required TextEditingController controller,
  required BuildContext context,
}) {
  final appState = Provider.of<PassengerState>(context);
  if (label == "De") {
    controller.text = appState.fromAddress;
  } else {
    controller.text = appState.toAddress;
  }

  return TextField(
    controller: controller,
    enabled: (appState.paymentMethod!.isNotEmpty) ? false : true,
    focusNode: label == "De"
        ? appState.focusNodePickup
        : appState.focusNodeDestination,
    style: TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 13.5.sp,
      color: Colors.black,
    ),
    textInputAction:
        TextInputAction.search, // force search button on keyboard
    decoration: InputDecoration(
      // labelText: label,
      hint: label == "De"
          ? Text(
              "Recolha",
              style: TextStyle(color: Colors.grey, fontSize: 14.5.sp),
            )
          : Text(
              "Para onde vais?",
              style: TextStyle(color: Colors.grey, fontSize: 15.5.sp),
            ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      prefixIcon: label == "Para"
          ? Image.asset(AssetPaths.flag, scale: 5)
          : Image.asset(AssetPaths.stopPeople, scale: 3),
      suffixIcon: label == "De"
          ? (appState.focusNodePickup.hasFocus && controller.text.isNotEmpty)
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                      appState.showRoute = false;
                      appState.fromAddress = '';
                      appState.originLocation = null;
                    },
                  )
                : null
          : (appState.focusNodeDestination.hasFocus && controller.text.isNotEmpty)
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                controller.clear();
                onChanged('');
                // appState.clearStops;
                appState.showRoute = false;
                appState.toAddress = '';
                appState.destinationLocation = null;
              },
            )
          : null,
    ),
    onTap: () {
      if (label == 'De') {
        appState.showPickupOptions = true;
        appState.showDestinationOptions = false;
      } else {
        appState.showDestinationOptions = true;
        appState.showPickupOptions = false;
      }
    },
    onChanged: (value) {
      if (value.isNotEmpty) {
        EasyDebounce.debounce(
          'search-debounce',
          const Duration(milliseconds: 700),
          () => LocationService.onSearchChanged(query: value, context: context),
        );
        onChanged(value);
      } else {
        controller.clear();
        onChanged('');
        if (label == "Para") {
          appState.showRoute = false;
          appState.destinationLocation = null;
          appState.toAddress = '';
        } else {
          appState.showRoute = false;
          appState.originLocation = null;
          appState.fromAddress = '';
        }
      }
    },
    onSubmitted: (value) {
      if (value.isNotEmpty) {
        LocationService.onSearchChanged(query: value, context: context);

        // desfoca os textfields
        FocusScope.of(context).unfocus();
      } else {
        showDefaultDialog(
          context,
          title: 'Aviso!',
          content: 'Escreva algo para fazer a pesquisa!',
        );
      }
    },
    onEditingComplete: () {},
  );
}

////////////////////////////////////////
Widget destinationTextField({
  required String label,
  required String textValue,
  required Function(String) onChanged,
  required TextEditingController controller,
  required BuildContext context,
  VoidCallback? onTap,
}) {
  final appState = Provider.of<PassengerState>(context);

  controller.text = appState.toAddress;

  return TextField(
    controller: controller,
    enabled: (appState.paymentMethod!.isNotEmpty) ? false : true,
    focusNode: appState.focusNodeDestination,
    style: TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 13.5.sp,
      color: Colors.black,
    ),
    textInputAction:
        TextInputAction.search, // force search button on keyboard
    decoration: InputDecoration(
      // labelText: label,
      hint: Text(
        "Para onde vais?",
        style: TextStyle(color: Colors.grey, fontSize: 15.5.sp),
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      prefixIcon: Image.asset(AssetPaths.flag, scale: 5),
      suffixIcon:
          (appState.focusNodeDestination.hasFocus && controller.text.isNotEmpty)
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                controller.clear();
                onChanged('');
                // appState.clearStops;
                appState.showRoute = false;
                appState.toAddress = '';
                appState.destinationLocation = null;
              },
            )
          : null,
    ),
    onTap: () {
      appState.showDestinationOptions = true;
      appState.showPickupOptions = false;
      appState.blinkDestinationField = false;
      if (onTap != null) onTap();
    },
    onChanged: (value) {
      if (value.isNotEmpty) {
        EasyDebounce.debounce(
          'destino_search-debounce',
          const Duration(milliseconds: 700),
          () => LocationService.onSearchChanged(query: value, context: context),
        );
        onChanged(value);
      } else {
        controller.clear();
        onChanged('');
        appState.showRoute = false;
        appState.destinationLocation = null;
        appState.toAddress = '';
      }
    },
    onSubmitted: (value) {
      if (value.isNotEmpty) {
        LocationService.onSearchChanged(query: value, context: context);

        // desfoca os textfields
        FocusScope.of(context).unfocus();
      } else {
        showDefaultDialog(
          context,
          title: 'Aviso!',
          content: 'Escreva algo para fazer a pesquisa!',
        );
      }
    },
    onEditingComplete: () {},
  );
}

Widget originTextField({
  required String label,
  required String textValue,
  required Function(String) onChanged,
  required TextEditingController controller,
  required BuildContext context,
}) {
  final appState = Provider.of<PassengerState>(context);
  controller.text = appState.fromAddress;

  return TextField(
    controller: controller,
    enabled: (appState.paymentMethod!.isNotEmpty) ? false : true,
    focusNode: appState.focusNodePickup,
    style: TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 13.5.sp,
      color: Colors.black,
    ),
    textInputAction:
        TextInputAction.search, // force search button on keyboard
    decoration: InputDecoration(
      // labelText: label,
      hint: Text(
        "Recolha",
        style: TextStyle(color: Colors.grey, fontSize: 14.5.sp),
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      prefixIcon: Image.asset(AssetPaths.stopPeople, scale: 3),
      suffixIcon:
          (appState.focusNodePickup.hasFocus && controller.text.isNotEmpty)
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                controller.clear();
                onChanged('');
                appState.showRoute = false;
                appState.fromAddress = '';
                appState.originLocation = null;
              },
            )
          : null,
    ),
    onTap: () {
      appState.showPickupOptions = true;
      appState.showDestinationOptions = false;
    },
    onChanged: (value) {
      if (value.isNotEmpty) {
        EasyDebounce.debounce(
          'origem_search-debounce',
          const Duration(milliseconds: 700),
          () => LocationService.onSearchChanged(query: value, context: context),
        );
        onChanged(value);
      } else {
        controller.clear();
        onChanged('');

        appState.showRoute = false;
        appState.originLocation = null;
        appState.fromAddress = '';
      }
    },
    onSubmitted: (value) {
      if (value.isNotEmpty) {
        LocationService.onSearchChanged(query: value, context: context);

        // desfoca os textfields
        FocusScope.of(context).unfocus();
      } else {
        showDefaultDialog(
          context,
          title: 'Aviso!',
          content: 'Escreva algo para fazer a pesquisa!',
        );
      }
    },
    onEditingComplete: () {},
  );
}

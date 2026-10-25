import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/passenger/components/bottomsheet/modal_date_time.dart';
import 'package:limousineexecutive/passenger/components/bottomsheet/modal_payment_method.dart';
import 'package:limousineexecutive/passenger/components/bottomsheet/modal_trip_confirmation.dart';
import 'package:limousineexecutive/passenger/components/dialogs/default_dialog.dart';
import 'package:limousineexecutive/passenger/models/cardata.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:provider/provider.dart';

/// The passenger chooses a service category. Dispatch finds the closest
/// available driver whose vehicle supports that category.
class CarOptionsList extends StatelessWidget {
  final VoidCallback onTripRequested;
  final void Function(double size) onAnimateSheet;

  const CarOptionsList({
    super.key,
    required this.onTripRequested,
    required this.onAnimateSheet,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<PassengerState>(context);
    final category = appState.carCategory;
    final categoryLabel = appState.selectedCarType.isEmpty
        ? category
        : appState.selectedCarType;

    return Padding(
      padding: EdgeInsets.fromLTRB(18.sp, 16.sp, 18.sp, 32.sp),
      child: Column(
        children: [
          Icon(
            CarData.categoryIcon(category),
            size: 48.sp,
            color: const Color(0xffe5a400),
          ),
          SizedBox(height: 10.sp),
          Text(
            categoryLabel,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Gagalin',
            ),
          ),
          SizedBox(height: 6.sp),
          Text(
            'Vamos chamar o motorista disponível mais próximo com um veículo nesta categoria.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: Colors.black54),
          ),
          if (appState.tripStatus == 'no_driver_available') ...[
            SizedBox(height: 8.sp),
            Text(
              'Não encontrámos um motorista da última vez. Podes tentar novamente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: Colors.deepOrange),
            ),
          ],
          SizedBox(height: 14.sp),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xffe5a400),
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 13.sp),
              ),
              onPressed: () => _requestTrip(context, appState, categoryLabel),
              icon: const Icon(Icons.near_me_outlined),
              label: Text(
                appState.tripStatus == 'no_driver_available'
                    ? 'Tentar novamente'
                    : 'Pedir esta categoria',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestTrip(
    BuildContext context,
    PassengerState appState,
    String categoryLabel,
  ) async {
    if (appState.destinationLocation == null ||
        appState.originLocation == null) {
      appState.blinkDestinationField = true;
      await showDefaultDialog(
        context,
        title: 'Aviso!',
        content: 'Preencha a localização!',
      );
      return;
    }

    final timeSchedule = await showDateTimeModal(context);
    if (timeSchedule == null) return;

    final method = await showPaymentMethodModal(context);
    if (method == null) return;

    final minAllowedTime = DateTime.now().add(const Duration(minutes: 30));
    final isScheduled = timeSchedule.isAfter(minAllowedTime);
    final category = <String, dynamic>{
      'name': categoryLabel,
      'category': appState.carCategory,
    };
    final confirmed = await showTripConfirmationModal(
      // ignore: use_build_context_synchronously
      context,
      originAddress: appState.fromAddress,
      destinationAddress: appState.toAddress,
      stops: appState.stops,
      price: appState.estimatedPrice,
      paymentMethod: method,
      car: category,
      timeSchedule: isScheduled ? timeSchedule : null,
    );
    if (confirmed != true) return;

    if (isScheduled) {
      appState.addAgenda({
        'fromAddress': appState.fromAddress,
        'originLocation': appState.originLocation,
        'toAddress': appState.toAddress,
        'destinationLocation': appState.destinationLocation,
        'selectedCar': categoryLabel,
        'selectedCarType': categoryLabel,
        'selectedCarTypeIndex': appState.selectedCarTypeindex,
        'selectedCategoryId': appState.carCategory,
        'paymentMethod': method,
        'isPaymentSelected': true,
        'stops': appState.stops,
        'time': timeSchedule,
        'car': category,
      });
      onAnimateSheet(0.3);
      return;
    }

    appState.selectedCar = categoryLabel;
    appState.selectedCarIndex = null;
    appState.paymentMethod = method;
    appState.isPaymentSelected = true;
    onTripRequested();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/passenger/components/bottomsheet/modal_date_time.dart';
import 'package:limousineexecutive/passenger/components/bottomsheet/modal_payment_method.dart';
import 'package:limousineexecutive/passenger/components/bottomsheet/modal_trip_confirmation.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:provider/provider.dart';

/// The passenger chooses a service category. Dispatch finds the closest
/// available driver whose vehicle supports that category.
class CarOptionsList extends StatefulWidget {
  final Future<void> Function() onTripRequested;
  final void Function(double size) onAnimateSheet;

  const CarOptionsList({
    super.key,
    required this.onTripRequested,
    required this.onAnimateSheet,
  });

  @override
  State<CarOptionsList> createState() => _CarOptionsListState();
}

class _CarOptionsListState extends State<CarOptionsList> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<PassengerState>(context);
    final categoryLabel = appState.selectedCarType.isEmpty
        ? appState.carCategory
        : appState.selectedCarType;
    final hasCategory = appState.selectedCarType.isNotEmpty;
    final categoryAvailable =
        hasCategory &&
        appState.hasAvailableDriversForCategory(appState.carCategory);
    final hasAnyAvailableCategory = appState.hasAnyAvailableCategory;
    final hasLocations = appState.hasTripLocations;
    final hasRoute = appState.distanceKm > 0;
    final canSubmit =
        hasCategory &&
        categoryAvailable &&
        hasLocations &&
        hasRoute &&
        !_isSubmitting;
    final disabledReason = _disabledReason(
      hasCategory: hasCategory,
      categoryAvailable: categoryAvailable,
      hasAnyAvailableCategory: hasAnyAvailableCategory,
      hasLocations: hasLocations,
      hasRoute: hasRoute,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(18.sp, 8.sp, 18.sp, 14.sp),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (disabledReason != null && !_isSubmitting) ...[
            Text(
              disabledReason,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                color: const Color(0xff68645f),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 7.sp),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xffe5a400),
                foregroundColor: const Color(0xff211c12),
                padding: EdgeInsets.symmetric(vertical: 14.sp),
                minimumSize: Size.fromHeight(54.sp),
                elevation: 2,
                shadowColor: const Color(0xff805500).withValues(alpha: 0.22),
                disabledBackgroundColor: const Color(0xffe9e5df),
                disabledForegroundColor: const Color(0xff77736d),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              onPressed: canSubmit
                  ? () => _requestTrip(context, appState, categoryLabel)
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSubmitting) ...[
                    SizedBox(
                      width: 18.sp,
                      height: 18.sp,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: const Color(0xff211c12),
                      ),
                    ),
                    SizedBox(width: 10.sp),
                    Text('A solicitar...'),
                  ] else ...[
                    Icon(
                      Icons.near_me_rounded,
                      size: 19.sp,
                      color: canSubmit
                          ? const Color(0xff211c12)
                          : const Color(0xff77736d),
                    ),
                    SizedBox(width: 9.sp),
                    Text(
                      'Solicitar Carro',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _disabledReason({
    required bool hasCategory,
    required bool categoryAvailable,
    required bool hasAnyAvailableCategory,
    required bool hasLocations,
    required bool hasRoute,
  }) {
    if (!hasLocations) return 'Define a origem e o destino para continuar.';
    if (!hasCategory && !hasAnyAvailableCategory) {
      return 'Nenhum motorista disponível neste momento.';
    }
    if (!hasCategory) return 'Escolha uma categoria disponível.';
    if (!categoryAvailable) {
      return 'Nenhum motorista disponível nesta categoria.';
    }
    if (!hasRoute) return 'A calcular a rota. Aguarde um momento.';
    return null;
  }

  Future<void> _requestTrip(
    BuildContext context,
    PassengerState appState,
    String categoryLabel,
  ) async {
    if (_isSubmitting ||
        appState.selectedCarType.isEmpty ||
        !appState.hasTripLocations ||
        appState.distanceKm <= 0 ||
        !appState.hasAvailableDriversForCategory(appState.carCategory)) {
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final timeSchedule = await showDateTimeModal(context);
      if (!mounted || timeSchedule == null) return;

      final method = await showPaymentMethodModal(context);
      if (!mounted || method == null) return;

      final minAllowedTime = DateTime.now().add(const Duration(minutes: 30));
      final isScheduled = timeSchedule.isAfter(minAllowedTime);
      final category = <String, dynamic>{
        'name': categoryLabel,
        'category': appState.carCategory,
      };
      final confirmed = await showTripConfirmationModal(
        context,
        originAddress: appState.fromAddress,
        destinationAddress: appState.toAddress,
        stops: appState.stops,
        price: appState.estimatedPrice,
        paymentMethod: method,
        car: category,
        timeSchedule: isScheduled ? timeSchedule : null,
      );
      if (!mounted || confirmed != true) return;

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
        widget.onAnimateSheet(0.3);
        return;
      }

      appState.selectedCar = categoryLabel;
      appState.selectedCarIndex = null;
      appState.paymentMethod = method;
      appState.isPaymentSelected = true;
      await widget.onTripRequested();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível solicitar o carro: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

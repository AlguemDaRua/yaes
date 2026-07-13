import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/passenger/components/bottomsheet/modal_date_time.dart';
import 'package:limousineexecutive/passenger/components/bottomsheet/modal_payment_method.dart';
import 'package:limousineexecutive/passenger/components/bottomsheet/modal_trip_confirmation.dart';
import 'package:limousineexecutive/passenger/components/dialogs/default_dialog.dart';
import 'package:limousineexecutive/passenger/models/cardata.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:provider/provider.dart';

/// Lista de veículos REAIS disponíveis na categoria seleccionada — motoristas
/// online e livres, com o veículo que o parceiro registou no painel. Nada de
/// catálogo fictício: se não há oferta, mostra-o honestamente.
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

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: appState.availableVehicles(appState.carCategory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: EdgeInsets.only(top: 40.sp),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final vehicles = snapshot.data ?? const [];
        if (vehicles.isEmpty) {
          return Padding(
            padding: EdgeInsets.fromLTRB(24.sp, 32.sp, 24.sp, 40.sp),
            child: Column(
              children: [
                Icon(
                  CarData.categoryIcon(appState.carCategory),
                  size: 48.sp,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 12.sp),
                Text(
                  'Sem veículos disponíveis nesta categoria agora. '
                  'Tenta outra categoria ou volta daqui a pouco.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        final localScroll = ScrollController();
        return SingleChildScrollView(
          controller: localScroll,
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: List.generate(vehicles.length, (i) {
              final car = vehicles[i];
              return _VehicleCard(
                car: car,
                isLast: i == vehicles.length - 1,
                onTap: () => _requestTrip(context, appState, car, i),
              );
            }),
          ),
        );
      },
    );
  }

  Future<void> _requestTrip(
    BuildContext context,
    PassengerState appState,
    Map<String, dynamic> car,
    int index,
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

    // ignore: use_build_context_synchronously
    final method = await showPaymentMethodModal(context);
    if (method == null) return;

    final minAllowedTime = DateTime.now().add(const Duration(minutes: 30));

    final confirmed = await showTripConfirmationModal(
      // ignore: use_build_context_synchronously
      context,
      originAddress: appState.fromAddress,
      destinationAddress: appState.toAddress,
      stops: appState.stops,
      price: appState.estimatedPrice,
      paymentMethod: method,
      car: car,
      timeSchedule:
          timeSchedule.isAfter(minAllowedTime) ? timeSchedule : null,
    );
    if (confirmed != true) return;

    if (timeSchedule.isAfter(minAllowedTime)) {
      appState.addAgenda({
        'fromAddress': appState.fromAddress,
        'originLocation': appState.originLocation,
        'toAddress': appState.toAddress,
        'destinationLocation': appState.destinationLocation,
        'selectedCar': car["name"] ?? '',
        'selectedCarIndex': index,
        'selectedCarType': appState.selectedCarType,
        'selectedCarTypeIndex': appState.selectedCarTypeindex,
        'paymentMethod': method,
        'isPaymentSelected': true,
        'stops': appState.stops,
        'time': timeSchedule,
        'car': car,
      });
      onAnimateSheet(0.3);
    } else {
      appState.selectedCar = car["name"] ?? '';
      appState.selectedCarIndex = index;
      appState.paymentMethod = method;
      appState.isPaymentSelected = true;
      onTripRequested();
    }
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.car,
    required this.isLast,
    required this.onTap,
  });

  final Map<String, dynamic> car;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<PassengerState>(context);
    final photoUrl = car['photoUrl']?.toString();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.only(bottom: isLast ? 40.sp : 0),
          width: double.infinity,
          height: 215.sp,
          margin: EdgeInsets.only(left: 15.sp, right: 15.sp, bottom: 12.sp),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.amber.withValues(alpha: 0.65),
                      Colors.amber.withValues(alpha: 0.50),
                    ],
                  ),
                ),
              ),
              // Foto real do veículo (painel) ou ícone da categoria
              Positioned(
                bottom: 0.sp,
                top: 0.sp,
                right: 0,
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          photoUrl,
                          width: 280.sp,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _categoryIcon(
                            appState.carCategory,
                          ),
                        ),
                      )
                    : _categoryIcon(appState.carCategory),
              ),
              // Motorista + lugares
              Positioned(
                top: 40.sp,
                left: 15.sp,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _chip(
                      Icons.person_outline,
                      car['driverName']?.toString() ?? 'Motorista',
                    ),
                    SizedBox(height: 6.sp),
                    _chip(
                      Icons.event_seat_outlined,
                      '${car["seats"]} LUGARES',
                    ),
                    if ((car['plate']?.toString() ?? '').isNotEmpty) ...[
                      SizedBox(height: 6.sp),
                      _chip(
                        Icons.confirmation_number_outlined,
                        car['plate'].toString(),
                      ),
                    ],
                  ],
                ),
              ),
              // Modelo real
              Positioned(
                top: 10.sp,
                left: 15.sp,
                child: Text(
                  car["name"]?.toString() ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                    fontFamily: 'Gagalin',
                    letterSpacing: 2.sp,
                  ),
                ),
              ),
              // Preço real (servidor)
              Positioned(
                bottom: 15.sp,
                left: 15.sp,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.sp,
                    vertical: 8.sp,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(180),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    (appState.destinationLocation != null &&
                            appState.toAddress.isNotEmpty &&
                            appState.showRoute)
                        ? (appState.estimatedPrice > 0
                              ? '${appState.estimatedPrice.ceil()} MT'
                              : 'Calculando...')
                        : 'PREÇO...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      fontFamily: 'Gagalin',
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryIcon(String category) => Padding(
        padding: EdgeInsets.only(right: 40.sp),
        child: Center(
          child: Icon(
            CarData.categoryIcon(category),
            size: 64.sp,
            color: Colors.black87,
          ),
        ),
      );

  Widget _chip(IconData icon, String label) => Container(
        padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(50),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14.sp, color: Colors.black87),
            SizedBox(width: 4.sp),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11.sp,
                fontFamily: 'Gagalin',
                letterSpacing: 0.5,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/driver/components/dialogs/call_passenger_dialog.dart';
import 'package:limousineexecutive/driver/components/dialogs/cancel_trip_dialog.dart';
import 'package:limousineexecutive/driver/components/dialogs/unaccepted_trip_dialog.dart';
import 'package:limousineexecutive/driver/components/dialogs/interrupt_trip_dialog.dart';
import 'package:limousineexecutive/driver/models/driver_state.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:limousineexecutive/utils/functions/make_phone_call.dart';
import 'package:limousineexecutive/utils/asset_paths.dart';
import 'package:limousineexecutive/shared/pages/chat_page.dart';
import 'package:provider/provider.dart';
import 'package:limousineexecutive/shared/widgets/skeletons.dart';

class GoingToPassenger extends StatefulWidget {
  final VoidCallback? onTap;
  const GoingToPassenger({super.key, this.onTap});

  @override
  State<GoingToPassenger> createState() => _GoingToPassengerState();
}

class _GoingToPassengerState extends State<GoingToPassenger> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<DriverState>(context);

    if (!appState.isTripStarted) {
      return _goingToPassanger();
    } else {
      return _goingToDestiny();
    }
  }

  Widget _goingToPassanger() {
    final appState = Provider.of<DriverState>(context);
    final tripData = appState.currentTripData;
    final passengerUid = tripData?['passenger'] as String?;
    final tripRepo = Provider.of<ITripRepository>(context, listen: false);

    return StreamBuilder<Map<String, dynamic>?>(
      stream: passengerUid != null
          ? tripRepo.watchProfile(passengerUid)
          : Stream.value(null),
      builder: (context, snapshot) {
        final passengerData = snapshot.data ?? {};
        final passengerName = (passengerData['name']?.toString().isNotEmpty == true)
            ? passengerData['name'].toString()
            : 'Passageiro';
        final passengerPhone = passengerData['phone']?.toString() ?? '';
        final photoUrl = passengerData['photoUrl']?.toString();

        return Container(
          margin: EdgeInsets.all(10.sp),
          padding: EdgeInsets.all(18.sp),
          height: 240.sp,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.black87, Colors.black54],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.directions_car, color: Colors.blueAccent, size: 22.sp),
                  SizedBox(width: 8.sp),
                  Text(
                    'Indo até o Passageiro',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '30s • 0.2 km',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.sp),
              Divider(color: Colors.white.withValues(alpha: 0.2)),

              if (snapshot.connectionState == ConnectionState.waiting) ...[
                SizedBox(height: 12.sp),
                const ProfileSkeleton(),
              ] else ...[
                SizedBox(height: 12.sp),
                // Passenger details
                Row(
                  children: [
                    // Avatar passageiro
                    Container(
                      padding: EdgeInsets.all(
                        (photoUrl != null && photoUrl.isNotEmpty) ? 0 : 10.sp,
                      ),
                      width: 70.sp,
                      height: 70.sp,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(color: appState.mainColor, width: 1.sp),
                        image: (photoUrl != null && photoUrl.isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(photoUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (photoUrl == null || photoUrl.isEmpty)
                          ? Icon(Icons.person, size: 36.sp, color: Colors.white70)
                          : null,
                    ),
                    SizedBox(width: 16.sp),

                    // Name and contact
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          passengerName,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 6.sp),
                        InkWell(
                          onTap: () {
                            if (passengerPhone.isNotEmpty) {
                              showCallToPassanger(
                                context: context,
                                phoneNumber: passengerPhone,
                                onConfirm: () => makePhoneCall(passengerPhone),
                              );
                            }
                          },
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(5.sp),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.phone,
                                  size: 16.sp,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              SizedBox(width: 6.sp),
                              Text(
                                passengerPhone.isNotEmpty ? passengerPhone : 'Sem número',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Chat button
                    GestureDetector(
                      onTap: () {
                        final uid = appState.currentTripData?['driver'] as String?;
                        if (uid != null && appState.currentTripId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                tripId: appState.currentTripId!,
                                currentUserUid: uid,
                                currentUserType: 'driver',
                                otherUserName: passengerName,
                                otherUserPhotoUrl: photoUrl ?? '',
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(10.sp),
                        width: 50.sp,
                        height: 50.sp,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                          border: Border.all(color: appState.mainColor, width: 1.sp),
                        ),
                        child: Icon(
                          Icons.chat,
                          size: 26.sp,
                          color: Colors.lightGreenAccent,
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Cancel button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          showCancelTripDialog(context, () {
                            if (appState.currentTripId != null) {
                              Provider.of<ITripRepository>(context, listen: false).updateTripStatus(
                                appState.currentTripId!,
                                'cancelled',
                              );
                            }
                            appState.endTrip();
                            showUnacceptedDialog(context);
                          });
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 12.sp,
                            horizontal: 40.sp,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.transparent,
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Start trip button
                    GestureDetector(
                      onTap: () async {
                        if (appState.currentTripId != null) {
                          await Provider.of<ITripRepository>(context, listen: false).updateTripStatus(
                            appState.currentTripId!,
                            'started',
                          );
                        }
                        appState.setIsTripStarted(true);
                        widget.onTap!();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 12.sp,
                          horizontal: 28.sp,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.59),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              AssetPaths.sendIcon,
                              width: 20.sp,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8.sp),
                            Text(
                              "Iniciar Viagem",
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _goingToDestiny() {
    final appState = Provider.of<DriverState>(context);
    final tripData = appState.currentTripData;
    final destinationName =
        tripData?['destination']?['name']?.toString() ?? 'Destino indisponível';

    return Container(
      padding: EdgeInsets.all(20.sp),
      margin: EdgeInsets.all(10.sp),
      height: 260.sp,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.black87, Colors.black54],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, color: Colors.amber, size: 24.sp),
              SizedBox(width: 8.sp),
              Text(
                'Indo até o Destino',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          SizedBox(height: 18.sp),

          // Card do destino
          Container(
            padding: EdgeInsets.all(14.sp),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  destinationName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.sp),
                Text(
                  '10 min • 3 km',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Main buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Interromper
              GestureDetector(
                onTap: () {
                  showInterruptTripDialog(context, (reason) {
                    if (appState.currentTripId != null) {
                      Provider.of<ITripRepository>(
                        context,
                        listen: false,
                      ).updateTripStatus(
                        appState.currentTripId!,
                        'cancelled', // Or a more specific status like 'interrupted' if the DB supports it
                      );
                      // Optionally save the reason to the database here if needed
                    }
                    appState.endTrip();
                    showUnacceptedDialog(context);
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 12.sp,
                    horizontal: 22.sp,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.redAccent.withValues(alpha: 0.85),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.white, size: 20.sp),
                      SizedBox(width: 6.sp),
                      Text(
                        "Interromper",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Concluir
              GestureDetector(
                onTap: () async {
                  if (appState.currentTripId != null) {
                    await Provider.of<ITripRepository>(
                      context,
                      listen: false,
                    ).updateTripStatus(appState.currentTripId!, 'completed');
                  }
                  appState.endTrip();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 12.sp,
                    horizontal: 24.sp,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.amber.withValues(alpha: 0.59),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                      SizedBox(width: 6.sp),
                      Text(
                        "Concluir",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/driver/components/buttons/accept_trip_button.dart';
import 'package:limousineexecutive/driver/components/countdown_text.dart';
import 'package:limousineexecutive/driver/models/driver_state.dart';
import 'package:provider/provider.dart';

class StartTrip extends StatefulWidget {
  const StartTrip({super.key});

  @override
  State<StartTrip> createState() => _StartTripState();
}

class _StartTripState extends State<StartTrip> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<DriverState>(context, listen: false);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(15.sp),
      height: 387.sp,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.29),
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.sp),

          // Trip request text and countdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pedido de Viagem',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.9,
                ),
              ),
              const CountdownText(duration: 15),
            ],
          ),

          SizedBox(height: 25.sp),

          // Passenger details
          Row(
            children: [
              // Passenger icon
              Container(
                padding: EdgeInsets.all(10.sp),
                width: 60.sp,
                height: 60.sp,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey.shade300,
                  border: Border.all(color: appState.mainColor, width: 1.sp),
                ),
                child: Icon(
                  Icons.person,
                  size: 40.sp,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(width: 20.sp),
              // Passenger name and contact
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text('Passageiro', style: TextStyle(fontSize: 15.sp)),
                  SizedBox(height: 5.sp),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 15.sp),
                      SizedBox(width: 5.sp),
                      Text('---', style: TextStyle(fontSize: 15.sp)),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // Chat icon
              Container(
                padding: EdgeInsets.all(10.sp),
                width: 50.sp,
                height: 50.sp,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.grey.shade300,
                  border: Border.all(color: appState.mainColor, width: 1.sp),
                ),
                child: Icon(Icons.chat, size: 30.sp, color: Colors.black87),
              ),
            ],
          ),
          SizedBox(height: 25.sp),

          // Trip route
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rota de Viagem',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.9,
                ),
              ),
              Text(
                '7km(15min)',
                style: TextStyle(fontSize: 15.sp, color: Colors.amber),
              ),
            ],
          ),

          SizedBox(height: 15.sp),

          // Pickup location
          Row(
            children: [
              Icon(Icons.my_location, size: 18.sp, color: Colors.blueAccent),
              SizedBox(width: 5.sp),
              Text(
                'ISCTEM',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          //
          Icon(Icons.more_vert, size: 15.sp),

          // Destination
          Row(
            children: [
              Icon(Icons.location_pin, size: 18.sp, color: Colors.brown),
              SizedBox(width: 5.sp),
              Text(
                'Aeroporto Internacional de Maputo',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          SizedBox(height: 25.sp),

          // Payment
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pagamento',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.normal,
                  letterSpacing: 0.9,
                ),
              ),
              Text(
                '5,000.00Mzn',
                style: TextStyle(fontSize: 15.sp, color: Colors.amber),
              ),
            ],
          ),
          SizedBox(height: 20.sp),

          // Accept trip button
          const AcceptTripButton(),
        ],
      ),
    );
  }
}

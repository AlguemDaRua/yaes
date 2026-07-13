import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/driver/models/driver_state.dart';
import 'package:provider/provider.dart';

class RatingPassenger extends StatefulWidget {
  const RatingPassenger({super.key});

  @override
  State<RatingPassenger> createState() => _RatingPassengerState();
}

class _RatingPassengerState extends State<RatingPassenger> {
  @override
  Widget build(BuildContext context) {
    double rating = 0;
    return Align(
      alignment: Alignment.center,
      child: RatingBar.builder(
        // unratedColor: Colors.transparent,
        glowColor: Colors.black,
        initialRating: 0,
        minRating: 1,
        direction: Axis.horizontal,
        allowHalfRating: true,
        itemCount: 5,
        itemSize: 50.sp,
        // itemPadding: const EdgeInsets.symmetric(horizontal: 10.0),
        itemBuilder: (context, index) {
          return Icon(
            index < rating ? Icons.star : Icons.star,
            color: Colors.amber,
          );
        },
        onRatingUpdate: (rating) {
          setState(() {
            rating = rating;
          });
        },
      ),
    );
  }
}

void showCustomPopup(BuildContext context) {
  final appState = Provider.of<DriverState>(context, listen: false);

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(15.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              Text(
                'viagem concluída com sucesso!',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'Gagalin',
                ),
              ),

              SizedBox(height: 15.sp),

              Text(
                'Distância percorrida: 7km',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),

              SizedBox(height: 15.sp),

              Text(
                'Valor recebido: 5.000,00Mzn',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),

              SizedBox(height: 25.sp),

              Text(
                'Avalie o passageiro',
                style: TextStyle(fontSize: 16.sp, color: appState.mainColor),
              ),

              SizedBox(height: 10.sp),

              const RatingPassenger(),

              SizedBox(height: 15.sp),

              // ElevatedButton(
              //   onPressed: () => Navigator.of(context).pop(),
              //   style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              //   child: Text(
              //     'OK',
              //     style: TextStyle(
              //       fontSize: 18.sp,
              //       color: Colors.black,
              //       fontWeight: FontWeight.normal,
              //       fontFamily: 'Gagalin',
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      );
    },
  );
}

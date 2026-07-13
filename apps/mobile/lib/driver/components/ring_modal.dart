// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:limousineexecutive/driver/components/buttons/accept_trip_button.dart';
// import 'package:limousineexecutive/driver/components/countdown_bar.dart';
// import 'package:limousineexecutive/driver/components/countdown_text.dart';

// class RingModal extends StatefulWidget {
//   const RingModal({super.key});

//   @override
//   State<RingModal> createState() => _RingModalState();
// }

// class _RingModalState extends State<RingModal> {
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeInOut,
//       padding: EdgeInsets.all(15.sp),
//       height: 270.sp,
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(16),
//           topRight: Radius.circular(16),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.29),
//             blurRadius: 10,
//             offset: const Offset(0, -1),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           CountdownBar(duration: 15),
//           SizedBox(height: 16.sp),

//           // Texto Pedido de Viagem e contagem de tempo
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Pedido de Viagem',
//                 style: TextStyle(
//                   fontSize: 15.sp,
//                   fontWeight: FontWeight.w600,
//                   letterSpacing: 0.9,
//                 ),
//               ),
//               CountdownText(duration: 15),
//             ],
//           ),

//           SizedBox(height: 0.sp),

//           // Rating do passageiro
//           Row(
//             children: [
//               Container(
//                 padding: EdgeInsets.all(1.sp),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[300],
//                   borderRadius: BorderRadius.circular(5),
//                   // border: Border.all(color: appState.mainColor, width: 1.sp),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.star, size: 15.sp),
//                     Text('5.0 (325)', style: TextStyle(fontSize: 12.sp)),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 3.sp),

//           Divider(color: Colors.grey[200]),

//           // Rota de viagem
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Rota de Viagem',
//                 style: TextStyle(
//                   fontSize: 15.sp,
//                   fontWeight: FontWeight.w600,
//                   letterSpacing: 0.9,
//                 ),
//               ),
//               Text(
//                 '7km(15min)',
//                 style: TextStyle(fontSize: 15.sp, color: Colors.amber),
//               ),
//             ],
//           ),

//           SizedBox(height: 15.sp),

//           // Local de partida
//           Row(
//             children: [
//               Icon(Icons.my_location, size: 18.sp, color: Colors.blueAccent),
//               SizedBox(width: 5.sp),
//               Text(
//                 'ISCTEM',
//                 style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
//               ),
//             ],
//           ),
//           //
//           Icon(Icons.more_vert, size: 15.sp),

//           // Local de destino
//           Row(
//             children: [
//               Icon(Icons.location_pin, size: 18.sp, color: Colors.brown),
//               SizedBox(width: 5.sp),
//               Text(
//                 'Aeroporto Internacional de Maputo',
//                 style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
//               ),
//             ],
//           ),

//           SizedBox(height: 25.sp),

//           // // Pagamento
//           // Row(
//           //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           //   children: [
//           //     Text(
//           //       'Pagamento',
//           //       style: TextStyle(
//           //         fontSize: 15.sp,
//           //         fontWeight: FontWeight.normal,
//           //         letterSpacing: 0.9,
//           //       ),
//           //     ),
//           //     Text(
//           //       '5,000.00Mzn',
//           //       style: TextStyle(fontSize: 15.sp, color: Colors.amber),
//           //     ),
//           //   ],
//           // ),
//           Spacer(),

//           // Botao de aceitar viagem
//           AcceptTripButton(),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/driver/components/buttons/accept_trip_button.dart';
import 'package:limousineexecutive/driver/components/countdown_bar.dart';
import 'package:limousineexecutive/driver/components/countdown_text.dart';
import 'package:limousineexecutive/driver/models/driver_state.dart';
import 'package:provider/provider.dart';

class RingModal extends StatelessWidget {
  const RingModal({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<DriverState>(context);
    final trip = appState.currentTripData;

    final originName = trip?['origin']?['name'] ?? "Local de recolha";
    final destName = trip?['destination']?['name'] ?? "Destino";
    final price = trip?['estimatedPrice']?.toString() ?? "---";
    // TODO: Fetch calculated distance/duration if not in trip object
    final stats = "7 km • 15 min";

    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
      height: 350.sp,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.black87, Colors.black54],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(40),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header with time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "🚘 Nova Viagem",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const CountdownText(duration: 15),
              ],
            ),

            SizedBox(height: 12.sp),
            const CountdownBar(duration: 15),

            SizedBox(height: 20.sp),

            // Bloco de rota
            Container(
              padding: EdgeInsets.all(12.sp),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.my_location,
                        color: Colors.greenAccent,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.sp),
                      Expanded(
                        child: Text(
                          originName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.sp),
                  Row(
                    children: [
                      Icon(
                        Icons.location_pin,
                        color: Colors.redAccent,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.sp),
                      Expanded(
                        child: Text(
                          destName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 15.sp),

            // Info extra
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 22.sp),
                    Text(
                      "5.0 (325)",
                      style: TextStyle(color: Colors.white, fontSize: 12.sp),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Icon(Icons.route, color: Colors.blueAccent, size: 22.sp),
                    Text(
                      stats,
                      style: TextStyle(color: Colors.white, fontSize: 12.sp),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Icon(
                      Icons.payment,
                      color: Colors.lightGreenAccent,
                      size: 22.sp,
                    ),
                    Text(
                      "$price MZN",
                      style: TextStyle(color: Colors.white, fontSize: 12.sp),
                    ),
                  ],
                ),
              ],
            ),

            const Spacer(),

            // Button
            const AcceptTripButton(),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:limousineexecutive/driver/models/driver_state.dart';
// import 'package:provider/provider.dart';

// class OnlineSwitch extends StatelessWidget {
//   final VoidCallback? onTap;
//   const OnlineSwitch({super.key, this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     final appState = Provider.of<DriverState>(context);

//     return Switch(
//       activeTrackColor: appState.mainColor,
//       inactiveTrackColor: Colors.white,
//       inactiveThumbColor: appState.mainColor,
//       activeThumbColor: Colors.amber,
//       value: appState.isOnline,
//       onChanged: (value) {
//         appState.setIsOnline(value);
//         appState.setIsRinging(value); // Stop ringing when going offline
//         if (onTap != null && value == true) {
//           onTap!();
//         }
//         appState.setShowRoute(value);
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:limousineexecutive/driver/models/driver_state.dart';
import 'package:provider/provider.dart';

class OnlineSwitch extends StatelessWidget {
  final VoidCallback? onTap;
  const OnlineSwitch({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<DriverState>(context);

    return Transform.scale(
      scale: 1.2, // scale up slightly for visual impact
      child: Switch(
        value: appState.isOnline,
        onChanged: (value) {
          // Carteira bloqueada por dívida de comissão: não deixa ficar online.
          if (value && appState.isWalletBlocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Saldo de comissão excedido. Recarrega a carteira para '
                  'voltar a ficar online.',
                ),
                action: SnackBarAction(
                  label: 'Carteira',
                  onPressed: () =>
                      Navigator.pushNamed(context, '/my_gain'),
                ),
              ),
            );
            return;
          }
          appState.setIsOnline(value);
          if (onTap != null && value == true) {
            onTap!();
          }
          appState.setShowRoute(value);
        },

        // Premium theme applied
        activeThumbColor: Colors.amberAccent, // active thumb colour
        inactiveThumbColor: Colors.white.withValues(alpha: 0.8), // inactive thumb
        activeTrackColor: Colors.black.withValues(alpha: 0.7), // dark active track
        inactiveTrackColor: Colors.black.withValues(
          alpha: 0.4,
        ), // dark inactive track
        // Golden glow in active state
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.amberAccent;
          }
          return Colors.white.withValues(alpha: 0.9);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.amber.withValues(alpha: 0.6);
          }
          return Colors.white.withValues(alpha: 0.4);
        }),
      ),
    );
  }
}

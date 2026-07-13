import 'package:flutter/material.dart';

Future<void> showCancelTripDialog(
  BuildContext context,
  VoidCallback onConfirm,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // don't close when tapping outside
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.85),
        title: const Text(
          'Cancelar viagem',
          style: TextStyle(
            color: Colors.amberAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Tem certeza que deseja cancelar a viagem?',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Não', style: TextStyle(color: Colors.white70)),
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amberAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Sim, cancelar'),
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              onConfirm(); // execute cancel action
            },
          ),
        ],
      );
    },
  );
}

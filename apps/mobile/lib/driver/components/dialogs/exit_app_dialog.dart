import 'package:flutter/material.dart';

import 'package:flutter/services.dart'; // para exit(0)

Future<void> showExitAppDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.black.withValues(alpha: 0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
        ),
        title: Text(
          'Sair da aplicação',
          style: TextStyle(
            color: Colors.amberAccent,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 6,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        content: const Text(
          'Tem certeza que deseja sair da aplicação?',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('Não'),
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amberAccent,
              foregroundColor: Colors.black,
              shadowColor: Colors.amber.withValues(alpha: 0.4),
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Sim, sair'),
            onPressed: () {
              SystemNavigator.pop(animated: true);
            },
          ),
        ],
      );
    },
  );
}

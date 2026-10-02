import 'package:flutter/material.dart';

import 'stop_marker.dart';

class MapLegendButton extends StatelessWidget {
  const MapLegendButton({super.key});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 2,
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: 'Legenda do mapa',
      icon: const Icon(Icons.info_outline, color: Color(0xFF202520)),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Legenda do mapa'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.circle, color: Color(0xffe5a400)),
                title: Text('Ponto de partida'),
                subtitle: Text('Local escolhido para o embarque.'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: SizedBox(
                  width: 44,
                  height: 44,
                  child: StopMarker(number: 1),
                ),
                title: Text('Paragens numeradas'),
                subtitle: Text('Os números indicam a ordem no percurso.'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.schedule, color: Colors.black),
                title: Text('Destino'),
                subtitle: Text('A hora no mapa indica a chegada estimada.'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      ),
    ),
  );
}

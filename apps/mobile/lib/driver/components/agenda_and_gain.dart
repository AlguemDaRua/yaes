import 'package:flutter/material.dart';
import 'package:limousineexecutive/driver/components/agenda_box.dart';

class AgendaAndGain extends StatelessWidget {
  const AgendaAndGain({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Agenda Box
        AgendaBox(),
        // Gain Box
        // GainBox(),
      ],
    );
  }
}

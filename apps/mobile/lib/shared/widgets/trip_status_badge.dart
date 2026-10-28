import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/trip_history_entry.dart';

class TripStatusBadge extends StatelessWidget {
  const TripStatusBadge({
    super.key,
    required this.trip,
    this.compact = false,
  });

  final TripHistoryEntry trip;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(trip.status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 11,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        trip.statusLabel,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
    'completed' => const Color(0xFF2E9D5B),
    'cancelled' => const Color(0xFFE24A4A),
    'started' || 'accepted' => const Color(0xFF2583C5),
    _ => const Color(0xFFE5A400),
  };
}

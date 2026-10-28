import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/trip_history_entry.dart';
import '../widgets/trip_status_badge.dart';

const Color _pageBackground = Color(0xFFF7F8FA);
const Color _ink = Color(0xFF28251F);
const Color _mutedInk = Color(0xFF77736B);
const Color _driverAccent = Color(0xFFE5A400);
const Color _passengerAccent = Color(0xFF2583C5);

enum TripDetailsAudience { driver, passenger }

Future<void> openTripDetailsPage(
  BuildContext context, {
  required TripHistoryEntry trip,
  required TripDetailsAudience audience,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (context) => TripDetailsPage(
        trip: trip,
        audience: audience,
      ),
    ),
  );
}

class TripDetailsPage extends StatelessWidget {
  const TripDetailsPage({
    super.key,
    required this.trip,
    required this.audience,
  });

  final TripHistoryEntry trip;
  final TripDetailsAudience audience;

  Color get _accent =>
      audience == TripDetailsAudience.driver ? _driverAccent : _passengerAccent;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: GoogleFonts.poppins(color: _ink),
      child: Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          backgroundColor: _pageBackground,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _ink),
          title: Text(
            'Detalhes da viagem',
            style: GoogleFonts.poppins(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 14),
              _buildRouteCard(),
              const SizedBox(height: 14),
              _buildTripInformationCard(),
              const SizedBox(height: 14),
              _buildPaymentCard(),
              if (trip.isCancelled) ...[
                const SizedBox(height: 14),
                _buildCancellationCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.directions_car_rounded,
                  color: _accent,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Viagem ${trip.tripTypeLabel.toLowerCase()}',
                  style: GoogleFonts.poppins(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          TripStatusBadge(trip: trip),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 16, color: _mutedInk),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Data e hora da viagem: ${trip.createdAtLabel}',
                  style: GoogleFonts.poppins(
                    color: _mutedInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(height: 1, color: Color(0xFFECEAE6)),
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Valor da viagem',
                  style: TextStyle(
                    color: _mutedInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                trip.amountLabel,
                style: GoogleFonts.poppins(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard() {
    final points = <_RoutePointData>[
      _RoutePointData(
        label: 'Ponto de partida',
        name: trip.origin,
        icon: Icons.trip_origin_rounded,
        color: const Color(0xFF2E9D5B),
      ),
      for (var index = 0; index < trip.stops.length; index++)
        _RoutePointData(
          label: 'Paragem ${index + 1}',
          name: trip.stops[index],
          icon: Icons.more_horiz_rounded,
          color: const Color(0xFFE5A400),
        ),
      _RoutePointData(
        label: 'Destino',
        name: trip.destination,
        icon: Icons.location_on_rounded,
        color: const Color(0xFFE24A4A),
      ),
    ];

    return _SectionCard(
      title: 'Percurso',
      accent: _accent,
      children: [
        for (var index = 0; index < points.length; index++) ...[
          _RoutePoint(point: points[index]),
          if (index < points.length - 1)
            const Padding(
              padding: EdgeInsets.only(left: 10, top: 2, bottom: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 2,
                  height: 22,
                  child: ColoredBox(color: Color(0xFFE7E5E1)),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildTripInformationCard() {
    final details = <_TripDetailData>[
      _TripDetailData(
        icon: Icons.confirmation_number_outlined,
        label: 'Identificação',
        value: trip.id.isEmpty ? 'Não disponível' : trip.id,
      ),
      _TripDetailData(
        icon: Icons.person_outline_rounded,
        label: 'Passageiro',
        value: trip.passengerName ?? 'Não informado',
      ),
      if (audience == TripDetailsAudience.passenger)
        _TripDetailData(
          icon: Icons.person_outline_rounded,
          label: 'Motorista',
          value: trip.driverName ?? 'Não informado',
        ),
      _TripDetailData(
        icon: Icons.category_outlined,
        label: 'Tipo de viagem',
        value: trip.tripTypeLabel,
      ),
      _TripDetailData(
        icon: Icons.directions_car_outlined,
        label: 'Categoria do veículo',
        value: trip.vehicleCategory,
      ),
      if (trip.distanceLabel != null)
        _TripDetailData(
          icon: Icons.route_outlined,
          label: 'Distância',
          value: trip.distanceLabel!,
        ),
      if (trip.durationLabel != null)
        _TripDetailData(
          icon: Icons.timelapse_rounded,
          label: 'Duração estimada',
          value: trip.durationLabel!,
        ),
    ];

    return _SectionCard(
      title: 'Dados da viagem',
      accent: _accent,
      children: [
        for (var index = 0; index < details.length; index++) ...[
          _DetailRow(detail: details[index]),
          if (index < details.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: Color(0xFFF0EFEC)),
            ),
        ],
      ],
    );
  }

  Widget _buildPaymentCard() {
    return _SectionCard(
      title: 'Pagamento',
      accent: _accent,
      children: [
        _DetailRow(
          detail: _TripDetailData(
            icon: Icons.payments_outlined,
            label: 'Método de pagamento',
            value: trip.paymentMethod,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: Color(0xFFF0EFEC)),
        ),
        _DetailRow(
          detail: _TripDetailData(
            icon: Icons.receipt_long_outlined,
            label: 'Estado do pagamento',
            value: trip.paymentStatus,
          ),
        ),
      ],
    );
  }

  Widget _buildCancellationCard() {
    return _SectionCard(
      title: 'Informação do cancelamento',
      accent: const Color(0xFFE24A4A),
      children: [
        _DetailRow(
          detail: _TripDetailData(
            icon: Icons.person_outline_rounded,
            label: 'Cancelada por',
            value: trip.cancelledBy,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: Color(0xFFF0EFEC)),
        ),
        _DetailRow(
          detail: _TripDetailData(
            icon: Icons.subject_rounded,
            label: 'Motivo',
            value: trip.cancellationReason,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: Color(0xFFF0EFEC)),
        ),
        _DetailRow(
          detail: _TripDetailData(
            icon: Icons.schedule_rounded,
            label: 'Data e hora',
            value: trip.cancelledAtLabel,
          ),
        ),
      ],
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.accent,
    required this.children,
  });

  final String title;
  final Color accent;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 19,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _RoutePointData {
  const _RoutePointData({
    required this.label,
    required this.name,
    required this.icon,
    required this.color,
  });

  final String label;
  final String name;
  final IconData icon;
  final Color color;
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({required this.point});

  final _RoutePointData point;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Icon(point.icon, color: point.color, size: 18),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                point.label,
                style: GoogleFonts.poppins(
                  color: _mutedInk,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                point.name,
                style: GoogleFonts.poppins(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripDetailData {
  const _TripDetailData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.detail});

  final _TripDetailData detail;

  @override
  Widget build(BuildContext context) {
    final value = detail.value;
    final isLongValue = detail.label == 'Motivo' || detail.label == 'Identificação';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(detail.icon, color: _mutedInk, size: 18),
        const SizedBox(width: 9),
        SizedBox(
          width: 116,
          child: Text(
            detail.label,
            style: GoogleFonts.poppins(
              color: _mutedInk,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: SelectableText(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              color: _ink,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            maxLines: isLongValue ? null : 3,
          ),
        ),
      ],
    );
  }
}

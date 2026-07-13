import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/config/map_config.dart';
import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../shared/widgets/dialogs/form_dialog.dart';
import '../../shared/widgets/feedback/info_card.dart';
import '../../shared/widgets/feedback/timeline.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_field.dart';
import '../../shared/widgets/forms/ya_input.dart';
import '../../shared/widgets/forms/ya_textarea.dart';
import '../../shared/widgets/layout/responsive.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/types.dart';

const _maputoCenter = LatLng(-25.9664, 32.5892);

class TripDetailPage extends ConsumerStatefulWidget {
  const TripDetailPage({required this.id, super.key});
  final String id;

  @override
  ConsumerState<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends ConsumerState<TripDetailPage> {
  bool _showRefund = false;

  @override
  Widget build(BuildContext context) {
    final AdminTrip? trip = ref.watch(adminTripByIdProvider(widget.id)).value;
    final String description = trip == null
        ? '—'
        : '${trip.origin ?? '-'} → ${trip.destination ?? '-'} · '
            '${DateFormat('dd/MM/yyyy HH:mm').format(trip.createdAt)}';

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: widget.id,
              description: description,
              breadcrumb: [
                const BreadcrumbItem(label: 'Corridas', route: '/admin/trips'),
                BreadcrumbItem(label: widget.id),
              ],
              actions: [
                if (trip?.passengerId != null)
                  YaButton.secondary(
                    label: 'Ver passageiro',
                    icon: LucideIcons.user,
                    onPressed: () =>
                        context.go('/admin/users/${trip!.passengerId}'),
                  ),
                if (trip?.driverId != null)
                  YaButton.secondary(
                    label: 'Ver driver',
                    icon: LucideIcons.car,
                    onPressed: () =>
                        context.go('/admin/drivers/${trip!.driverId}'),
                  ),
                if (trip?.status == 'completed')
                  YaButton.destructive(
                    label: 'Emitir reembolso',
                    icon: LucideIcons.undo2,
                    onPressed: () => setState(() => _showRefund = true),
                  ),
              ],
            ),
            const SizedBox(height: YaSpacing.xxl),
            YaResponsiveStack(
              flexes: const [3, 2],
              children: [
                Column(
                  children: [
                    _MapCard(trip: trip),
                    const SizedBox(height: YaSpacing.lg),
                    _TimelineCard(trip: trip),
                  ],
                ),
                Column(
                  children: [
                    _PassengerCard(passengerId: trip?.passengerId),
                    const SizedBox(height: YaSpacing.md),
                    _DriverCard(driverId: trip?.driverId),
                    const SizedBox(height: YaSpacing.md),
                    _PaymentCard(trip: trip),
                  ],
                ),
              ],
            ),
          ],
        ),
        if (_showRefund)
          _RefundDialog(
            tripId: widget.id,
            amount: trip?.amountMtn ?? 0,
            onClose: () => setState(() => _showRefund = false),
          ),
      ],
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({required this.trip});

  final AdminTrip? trip;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileUrl = isDark ? MapConfig.darkTileUrl : MapConfig.streetsTileUrl;

    final LatLng? origin =
        trip != null && trip!.originLat != null && trip!.originLng != null
            ? LatLng(trip!.originLat!, trip!.originLng!)
            : null;
    final LatLng? dest =
        trip != null && trip!.destLat != null && trip!.destLng != null
            ? LatLng(trip!.destLat!, trip!.destLng!)
            : null;
    final LatLng center = origin ?? dest ?? _maputoCenter;

    return ClipRRect(
      borderRadius: YaRadius.brLg,
      child: SizedBox(
        height: 360,
        child: FlutterMap(
          options: MapOptions(initialCenter: center),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              userAgentPackageName: 'mz.ya.painel',
            ),
            if (origin != null && dest != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [origin, dest],
                    color: colors.brand,
                    strokeWidth: 4,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (origin != null)
                  Marker(
                    point: origin,
                    child: Icon(
                      LucideIcons.mapPin,
                      color: colors.success,
                      size: 24,
                    ),
                  ),
                if (dest != null)
                  Marker(
                    point: dest,
                    child: Icon(
                      LucideIcons.mapPin,
                      color: colors.danger,
                      size: 24,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.trip});

  final AdminTrip? trip;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    final created =
        trip == null ? '—' : DateFormat('dd/MM HH:mm').format(trip!.createdAt);
    final status = trip?.status ?? 'pending';
    // Só o createdAt está disponível no modelo do painel; os restantes
    // marcos mostram o progresso do estado sem hora.
    final events = <TimelineEvent>[
      TimelineEvent(label: 'Corrida criada', timestamp: created),
      if (status == 'awaiting_payment')
        const TimelineEvent(
          label: 'A aguardar pagamento',
          timestamp: '',
          variant: StatusVariant.warning,
        ),
      if (status == 'accepted' || status == 'started' || status == 'completed')
        const TimelineEvent(
          label: 'Aceite pelo driver',
          timestamp: '',
          variant: StatusVariant.info,
        ),
      if (status == 'started' || status == 'completed')
        const TimelineEvent(
          label: 'Corrida iniciada',
          timestamp: '',
          variant: StatusVariant.warning,
        ),
      if (status == 'completed')
        const TimelineEvent(
          label: 'Corrida completa',
          timestamp: '',
          variant: StatusVariant.success,
        ),
      if (status == 'cancelled')
        const TimelineEvent(
          label: 'Corrida cancelada',
          timestamp: '',
          variant: StatusVariant.danger,
        ),
    ];

    return Container(
      padding: YaSpacing.cardMd,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: YaRadius.brLg,
        border: Border.all(color: colors.borderSubtle),
        boxShadow: isLight ? YaShadows.sm : YaShadows.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Linha do tempo',
            style: YaText.smMedium.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: YaSpacing.lg),
          Timeline(events: events),
        ],
      ),
    );
  }
}

class _PassengerCard extends ConsumerWidget {
  const _PassengerCard({required this.passengerId});

  final String? passengerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = passengerId;
    final AdminUser? user =
        id == null ? null : ref.watch(adminUserByIdProvider(id)).value;
    return InfoCard(
      title: 'Passageiro',
      rows: [
        InfoCardRow('Nome', user?.name ?? id ?? '—'),
        InfoCardRow('Telefone', user?.phone ?? '—'),
        InfoCardRow(
          'Estado',
          user == null
              ? '—'
              : (user.status == 'suspended' ? 'Bloqueado' : 'Activo'),
        ),
      ],
    );
  }
}

class _DriverCard extends ConsumerWidget {
  const _DriverCard({required this.driverId});

  final String? driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = driverId;
    final AdminDriver? driver =
        id == null ? null : ref.watch(adminDriverByIdProvider(id)).value;
    return InfoCard(
      title: 'Driver',
      rows: [
        InfoCardRow('Nome', driver?.name ?? id ?? 'Sem driver atribuído'),
        InfoCardRow('Telefone', driver?.phone ?? '—'),
        InfoCardRow(
          'Estado',
          driver == null ? '—' : (driver.online ? 'Online' : 'Offline'),
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.trip});

  final AdminTrip? trip;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'pt_PT');
    return InfoCard(
      title: 'Pagamento',
      rows: [
        InfoCardRow(
          'Valor',
          trip == null ? '—' : '${fmt.format(trip!.amountMtn)} MTn',
        ),
        InfoCardRow('Estado', trip?.status ?? '—'),
        InfoCardRow('Partner', trip?.partnerId ?? '—'),
      ],
    );
  }
}

class _RefundDialog extends StatelessWidget {
  const _RefundDialog({
    required this.tripId,
    required this.amount,
    required this.onClose,
  });
  final String tripId;
  final int amount;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Emitir reembolso · $tripId',
      description: 'Devolver valor ao passageiro via M-Pesa.',
      confirmLabel: 'Emitir reembolso',
      destructive: true,
      onCancel: onClose,
      onConfirm: onClose,
      children: [
        YaField(
          label: 'Valor a reembolsar (MTn)',
          child: YaInput(
            placeholder: amount.toString(),
            keyboardType: TextInputType.number,
          ),
        ),
        const YaField(
          label: 'Motivo (visível ao passageiro)',
          child: YaTextarea(placeholder: 'Mínimo 10 caracteres'),
        ),
      ],
    );
  }
}

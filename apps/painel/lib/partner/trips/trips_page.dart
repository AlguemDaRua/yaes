import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/utils/csv_export.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../theme/tokens/dimensions.dart';
import '../data/mock_partner_data.dart';
import '../widgets/partner_common.dart';

class PartnerTripsPage extends ConsumerWidget {
  const PartnerTripsPage({super.key});

  void _exportCsv(
    BuildContext context,
    List<MockTrip> trips,
    Map<String, String> driverNames,
  ) {
    if (trips.isEmpty) {
      partnerToast(context, 'Nada para exportar');
      return;
    }
    final String stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
    downloadCsv('corridas-$stamp.csv', <List<Object?>>[
      <Object?>[
        'id',
        'data',
        'motorista',
        'origem',
        'destino',
        'distancia_km',
        'valor_mtn',
        'estado',
      ],
      for (final MockTrip t in trips)
        <Object?>[
          t.id,
          DateFormat('yyyy-MM-dd HH:mm').format(t.startedAt),
          driverNames[t.driverId] ?? t.driverId,
          t.origin,
          t.destination,
          t.distanceKm,
          t.amountMtn,
          t.status.name,
        ],
    ]);
    partnerToast(context, 'CSV exportado');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<MockTrip> trips =
        ref.watch(tripsProvider).value ?? const <MockTrip>[];
    final Map<String, String> driverNames = <String, String>{
      for (final MockDriver d
          in ref.watch(driversProvider).value ?? const <MockDriver>[])
        d.id: d.name,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PageHeader(
          title: S.of(context).partnerNavTrips,
          description: 'Todas as corridas da tua frota',
          actions: <Widget>[
            YaButton.secondary(
              label: 'Exportar',
              icon: LucideIcons.download,
              onPressed: () => _exportCsv(context, trips, driverNames),
            ),
          ],
        ),
        const SizedBox(height: YaSpacing.xxl),
        const TripsTableSection(),
      ],
    );
  }
}

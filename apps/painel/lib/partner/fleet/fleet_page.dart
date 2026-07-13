import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_tabs.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../theme/tokens/dimensions.dart';
import '../data/mock_partner_data.dart';
import '../widgets/partner_common.dart';

class PartnerFleetPage extends ConsumerWidget {
  const PartnerFleetPage({this.tab = 'drivers', super.key});

  final String tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int activeIndex = tab == 'vehicles' ? 1 : 0;
    final int driversCount = ref.watch(driversProvider).maybeWhen(
          data: (drivers) => drivers.length,
          orElse: () => 0,
        );
    final int vehiclesCount = ref.watch(vehiclesProvider).maybeWhen(
          data: (vehicles) => vehicles.length,
          orElse: () => 0,
        );
    final String fleetName = ref.watch(partnerProfileProvider).maybeWhen(
          data: (MockPartnerProfile p) => p.fleetName,
          orElse: () => MockPartner.fleetName,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PageHeader(
          title: S.of(context).partnerFleetTitle,
          description: 'Gere os teus motoristas e viaturas · $fleetName',
          actions: <Widget>[
            if (activeIndex == 0)
              YaButton.primary(
                label: 'Convidar motorista',
                icon: LucideIcons.userPlus,
                onPressed: () => openInviteDriverDialog(context),
              ),
            if (activeIndex == 1)
              YaButton.primary(
                label: 'Adicionar veículo',
                icon: LucideIcons.plus,
                onPressed: () => openAddVehicleDialog(context),
              ),
          ],
          tabs: YaTabs(
            items: <YaTabItem>[
              YaTabItem(label: 'Motoristas', count: driversCount),
              YaTabItem(label: 'Veículos', count: vehiclesCount),
            ],
            activeIndex: activeIndex,
            onChanged: (int index) {
              final String next = index == 0 ? 'drivers' : 'vehicles';
              context.go('/partner/fleet?tab=$next');
            },
          ),
        ),
        const SizedBox(height: YaSpacing.xxl),
        const FleetSummaryCard(),
        const SizedBox(height: YaSpacing.xxl),
        if (activeIndex == 0)
          const DriversTableSection()
        else
          const VehiclesTableSection(),
      ],
    );
  }
}

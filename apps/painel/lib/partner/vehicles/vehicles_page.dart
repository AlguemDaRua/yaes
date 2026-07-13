import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../theme/tokens/dimensions.dart';
import '../widgets/partner_common.dart';

class PartnerCarsPage extends StatelessWidget {
  const PartnerCarsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PageHeader(
          title: S.of(context).partnerNavVehicles,
          description: 'Todos os veículos da tua frota',
          actions: <Widget>[
            YaButton.primary(
              label: 'Adicionar veículo',
              icon: LucideIcons.plus,
              onPressed: () => openAddVehicleDialog(context),
            ),
          ],
        ),
        const SizedBox(height: YaSpacing.xxl),
        const VehiclesTableSection(),
      ],
    );
  }
}

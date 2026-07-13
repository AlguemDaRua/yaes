import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../theme/tokens/dimensions.dart';
import '../widgets/partner_common.dart';

class PartnerDriversPage extends StatelessWidget {
  const PartnerDriversPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PageHeader(
          title: S.of(context).partnerNavDrivers,
          description: 'Todos os motoristas da tua frota',
          actions: <Widget>[
            YaButton.primary(
              label: 'Convidar motorista',
              icon: LucideIcons.userPlus,
              onPressed: () => openInviteDriverDialog(context),
            ),
          ],
        ),
        const SizedBox(height: YaSpacing.xxl),
        const DriversTableSection(),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../theme/tokens/dimensions.dart';
import '../data/mock_types.dart';
import '../widgets/partner_common.dart';

class PartnerDocumentsPage extends StatelessWidget {
  const PartnerDocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<(String, MockDocumentStatus, DateTime?, String)> docs =
        <(String, MockDocumentStatus, DateTime?, String)>[
      ('NUIT scan', MockDocumentStatus.ok, null, 'Substituir'),
      (
        'Alvará comercial',
        MockDocumentStatus.ok,
        DateTime(2026, 12, 31),
        'Substituir',
      ),
      ('Contrato com YA', MockDocumentStatus.ok, null, 'Ver'),
      ('IRPC último ano', MockDocumentStatus.ok, null, 'Substituir'),
      (
        'IVA mensal recente',
        MockDocumentStatus.expiringSoon,
        DateTime(2026, 5, 30),
        'Substituir',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PageHeader(
          title: S.of(context).partnerNavDocuments,
          description:
              'Documentos legais e fiscais do partner · não inclui motoristas/veículos',
        ),
        const SizedBox(height: YaSpacing.xxl),
        for (final (
              String title,
              MockDocumentStatus status,
              DateTime? expiry,
              String action
            ) in docs) ...<Widget>[
          DocumentCard(
            title: title,
            status: status,
            expiresAt: expiry,
            actionLabel: action,
            onTap: () {
              if (action == 'Ver') {
                partnerToast(context, 'Pré-visualização aberta');
              } else {
                openUploadDocumentDialog(context, title);
              }
            },
          ),
          const SizedBox(height: YaSpacing.md),
        ],
      ],
    );
  }
}

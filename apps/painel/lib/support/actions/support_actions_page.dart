import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/feedback/empty_state.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_input.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../shared/widgets/table/cells.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/mock_types.dart';
import '../widgets/support_common.dart';

class SupportActionsPage extends ConsumerStatefulWidget {
  const SupportActionsPage({super.key});

  @override
  ConsumerState<SupportActionsPage> createState() => _SupportActionsPageState();
}

class _SupportActionsPageState extends ConsumerState<SupportActionsPage> {
  String _query = '';

  String? get _error {
    final String q = _query.trim();
    final bool onlyDigits = RegExp(r'^\d+$').hasMatch(q);
    if (onlyDigits && q.length != 9) return 'NUIT deve ter 9 dígitos';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final List<SupportQuickResult> results = _error == null
        ? (ref.watch(supportQuickSearchProvider(_query.trim())).value ??
            const <SupportQuickResult>[])
        : <SupportQuickResult>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PageHeader(
          title: S.of(context).supportNavActions,
          description: 'Pesquisa global e ações corretivas',
        ),
        const SizedBox(height: YaSpacing.xxl),
        SupportCard(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: YaSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Pesquisar utilizador, driver, corrida ou partner',
                style: YaText.sans(
                  size: 12,
                  height: 16,
                  weight: FontWeight.w500,
                ).copyWith(color: YaColors.of(context).textSecondary),
              ),
              const SizedBox(height: YaSpacing.md),
              YaInput(
                placeholder: 'ID, telefone, NUIT, matrícula, email...',
                icon: LucideIcons.search,
                size: YaInputSize.lg,
                errorText: _error,
                onChanged: (String value) => setState(() => _query = value),
              ),
              const SizedBox(height: YaSpacing.sm),
              Text(
                'Resultados aparecem abaixo',
                style: YaText.sans(size: 12, height: 16)
                    .copyWith(color: YaColors.of(context).textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: YaSpacing.xxl),
        if (results.isEmpty)
          SupportCard(
            child: EmptyState(
              icon: LucideIcons.searchX,
              title: 'Sem correspondências',
              description: 'Não há resultados para "${_query.trim()}".',
            ),
          )
        else
          Column(
            children: <Widget>[
              for (final SupportQuickResult result in results) ...<Widget>[
                _QuickResultCard(result: result),
                const SizedBox(height: YaSpacing.md),
              ],
            ],
          ),
      ],
    );
  }
}

class _QuickResultCard extends StatefulWidget {
  const _QuickResultCard({required this.result});

  final SupportQuickResult result;

  @override
  State<_QuickResultCard> createState() => _QuickResultCardState();
}

class _QuickResultCardState extends State<_QuickResultCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    final SupportQuickResult result = widget.result;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () => openQuickActionsDialog(context, result),
        child: SupportCard(
          backgroundColor: _hovering ? colors.bgSubtle : null,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 620;
              final Widget leading = Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.brandSubtle,
                  borderRadius: YaRadius.brMd,
                ),
                child: Icon(
                  supportQuickTypeIcon(result.type),
                  size: 20,
                  color: colors.brand,
                ),
              );

              final Widget body = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          result.title,
                          style: YaText.smMedium
                              .copyWith(color: colors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: YaSpacing.sm),
                      StatusBadge(
                        variant: StatusVariant.brand,
                        label: supportQuickTypeLabel(result.type),
                        size: StatusBadgeSize.sm,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.subtitle,
                    style: YaText.sans(size: 12, height: 16)
                        .copyWith(color: colors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        leading,
                        const SizedBox(width: YaSpacing.md),
                        Expanded(child: body),
                      ],
                    ),
                    const SizedBox(height: YaSpacing.md),
                    IdCell(result.id),
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  leading,
                  const SizedBox(width: YaSpacing.md),
                  Expanded(child: body),
                  const SizedBox(width: YaSpacing.lg),
                  IdCell(result.id),
                  const SizedBox(width: YaSpacing.md),
                  YaButton.ghost(
                    label: 'Abrir',
                    size: YaButtonSize.sm,
                    icon: LucideIcons.arrowRight,
                    onPressed: () => openQuickActionsDialog(context, result),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

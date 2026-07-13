import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../shared/widgets/dialogs/form_dialog.dart';
import '../../shared/widgets/feedback/empty_state.dart';
import '../../shared/widgets/feedback/skeleton.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/mock_partner_data.dart';
import '../data/mock_types.dart';
import '../widgets/partner_common.dart';

class PartnerIncentivesPage extends ConsumerWidget {
  const PartnerIncentivesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MockIncentive>> async =
        ref.watch(incentivesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const PageHeader(
          title: 'Incentivos',
          description: 'Campanhas activas e oportunidades de bónus',
        ),
        const SizedBox(height: YaSpacing.xxl),
        async.when(
          data: (List<MockIncentive> incentives) {
            if (incentives.isEmpty) {
              return const EmptyState(
                icon: LucideIcons.gift,
                title: 'Sem campanhas activas',
                description: 'Volta em breve para novas oportunidades.',
              );
            }
            return Wrap(
              spacing: YaSpacing.lg,
              runSpacing: YaSpacing.lg,
              children: <Widget>[
                for (final MockIncentive incentive in incentives)
                  SizedBox(
                    width: 340,
                    child: _IncentiveCard(incentive: incentive),
                  ),
              ],
            );
          },
          loading: () => const Skeleton(width: double.infinity, height: 200),
          error: (Object e, StackTrace _) => EmptyState(
            icon: LucideIcons.circleAlert,
            title: 'Erro a carregar incentivos',
            description: '$e',
          ),
        ),
      ],
    );
  }
}

class _IncentiveCard extends StatelessWidget {
  const _IncentiveCard({required this.incentive});

  final MockIncentive incentive;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    final int days =
        incentive.endsAt.difference(DateTime.now()).inDays;

    return PartnerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: YaSpacing.sm,
            runSpacing: YaSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              StatusBadge(
                variant: incentive.status == MockIncentiveStatus.active
                    ? StatusVariant.success
                    : StatusVariant.info,
                label: incentive.status == MockIncentiveStatus.active
                    ? 'Activa'
                    : 'Agendada',
                size: StatusBadgeSize.sm,
              ),
              Text(
                incentive.title,
                style: YaText.mdMedium.copyWith(color: colors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: YaSpacing.md),
          Text(
            incentive.target,
            style: YaText.sm.copyWith(color: colors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: YaSpacing.xl),
          ClipRRect(
            borderRadius: YaRadius.brFull,
            child: LinearProgressIndicator(
              minHeight: 6,
              value: incentive.progress.clamp(0, 1).toDouble(),
              backgroundColor: colors.bgSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(colors.brand),
            ),
          ),
          const SizedBox(height: YaSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${(incentive.progress * 100).round()}% completo',
                  style: YaText.smMedium.copyWith(color: colors.textPrimary),
                ),
              ),
              Text(
                '$days dias restantes',
                style: YaText.sans(size: 12, height: 16)
                    .copyWith(color: colors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: YaSpacing.md),
          Text(
            '+${partnerFormatInt(incentive.rewardMtn)} MTn ao atingir meta',
            style: YaText.smMedium.copyWith(color: colors.brand),
          ),
          const SizedBox(height: YaSpacing.lg),
          YaButton.link(
            label: 'Detalhes ->',
            onPressed: () => _openDetails(context, incentive),
          ),
        ],
      ),
    );
  }

  void _openDetails(BuildContext context, MockIncentive incentive) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return FormDialog(
          title: incentive.title,
          description: 'Regras completas da campanha.',
          confirmLabel: 'Fechar',
          onConfirm: () => Navigator.of(dialogContext).pop(),
          children: <Widget>[
            Text(
              'Cumpre a meta indicada dentro do período da campanha. '
              'O bónus é creditado automaticamente no próximo payout.',
              style:
                  YaText.sm.copyWith(color: YaColors.of(context).textSecondary),
            ),
          ],
        );
      },
    );
  }
}

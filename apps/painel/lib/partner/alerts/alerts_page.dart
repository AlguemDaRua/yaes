import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/feedback/empty_state.dart';
import '../../shared/widgets/feedback/skeleton.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/filters/filter_bar.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/mock_partner_data.dart';
import '../data/mock_types.dart';
import '../widgets/partner_common.dart';

class PartnerAlertsPage extends ConsumerStatefulWidget {
  const PartnerAlertsPage({super.key});

  @override
  ConsumerState<PartnerAlertsPage> createState() => _PartnerAlertsPageState();
}

class _PartnerAlertsPageState extends ConsumerState<PartnerAlertsPage> {
  String _chip = 'all';
  final Set<String> _resolved = <String>{};

  List<MockAlert> _filtered(List<MockAlert> source) {
    return source.where((MockAlert alert) {
      final bool resolved = _resolved.contains(alert.id);
      return switch (_chip) {
        'critical' => alert.severity == MockAlertSeverity.critical,
        'active' => !resolved,
        'resolved' => resolved,
        _ => true,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<MockAlert>> alertsAsync = ref.watch(alertsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PageHeader(
          title: S.of(context).partnerNavAlerts,
          description: 'Eventos que requerem a tua atenção',
        ),
        const SizedBox(height: YaSpacing.xxl),
        FilterBar(
          chips: const <FilterChipSpec>[
            FilterChipSpec(id: 'all', label: 'Todos'),
            FilterChipSpec(
              id: 'critical',
              label: 'Críticos',
              variant: StatusVariant.danger,
            ),
            FilterChipSpec(
              id: 'active',
              label: 'Activos',
              variant: StatusVariant.warning,
            ),
            FilterChipSpec(
              id: 'resolved',
              label: 'Resolvidos',
              variant: StatusVariant.success,
            ),
          ],
          activeChipId: _chip,
          onChipSelected: (String id) => setState(() => _chip = id),
          searchPlaceholder: 'Pesquisar alertas...',
        ),
        const SizedBox(height: YaSpacing.lg),
        ...alertsAsync.when(
          data: (List<MockAlert> source) {
            final List<MockAlert> filtered = _filtered(source);
            if (filtered.isEmpty) {
              return <Widget>[
                const EmptyState(
                  icon: LucideIcons.circleCheck,
                  title: 'Tudo em ordem',
                  description: 'Sem alertas activos neste filtro.',
                ),
              ];
            }
            return <Widget>[
              for (final MockAlert alert in filtered) ...<Widget>[
                _AlertCard(
                  alert: alert,
                  resolved: _resolved.contains(alert.id),
                  onToggle: () {
                    setState(() {
                      if (_resolved.contains(alert.id)) {
                        _resolved.remove(alert.id);
                      } else {
                        _resolved.add(alert.id);
                      }
                    });
                    partnerToast(
                      context,
                      _resolved.contains(alert.id)
                          ? 'Alerta resolvido'
                          : 'Alerta marcado como activo',
                    );
                  },
                ),
                const SizedBox(height: YaSpacing.md),
              ],
            ];
          },
          loading: () => const <Widget>[
            Skeleton(width: double.infinity, height: 96),
            SizedBox(height: YaSpacing.md),
            Skeleton(width: double.infinity, height: 96),
            SizedBox(height: YaSpacing.md),
            Skeleton(width: double.infinity, height: 96),
          ],
          error: (Object err, StackTrace _) => <Widget>[
            EmptyState(
              icon: LucideIcons.circleAlert,
              title: 'Erro a carregar alertas',
              description: '$err',
            ),
          ],
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.resolved,
    required this.onToggle,
  });

  final MockAlert alert;
  final bool resolved;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    final StatusVariant variant = switch (alert.severity) {
      MockAlertSeverity.critical => StatusVariant.danger,
      MockAlertSeverity.warning => StatusVariant.warning,
      MockAlertSeverity.info => StatusVariant.info,
    };
    final ({Color bg, Color text}) palette = variant.resolve(colors);
    final String? route = alert.driverId != null
        ? '/partner/fleet/driver/${alert.driverId}'
        : alert.vehicleId != null
            ? '/partner/fleet/vehicle/${alert.vehicleId}'
            : null;

    final Widget icon = Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: YaRadius.brMd,
      ),
      child: Icon(
        alert.severity == MockAlertSeverity.info
            ? LucideIcons.info
            : LucideIcons.triangleAlert,
        size: 18,
        color: palette.text,
      ),
    );
    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          alert.title,
          style: YaText.baseMedium.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: 3),
        Text(
          alert.description,
          style: YaText.sm.copyWith(color: colors.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: YaSpacing.xs,
          children: <Widget>[
            Text(
              partnerRelativeWhen(alert.createdAt),
              style: YaText.sans(size: 12, height: 16)
                  .copyWith(color: colors.textMuted),
            ),
            if (route != null)
              YaButton.link(
                label: 'Ver entidade ->',
                size: YaButtonSize.sm,
                onPressed: () => context.go(route),
              ),
          ],
        ),
      ],
    );
    final Widget actions = Wrap(
      spacing: YaSpacing.sm,
      runSpacing: YaSpacing.sm,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        StatusBadge(
          variant: variant,
          label: alert.severity == MockAlertSeverity.critical
              ? 'Crítico'
              : alert.severity == MockAlertSeverity.warning
                  ? 'Atenção'
                  : 'Info',
          size: StatusBadgeSize.sm,
        ),
        YaButton.ghost(
          label: resolved ? 'Marcar activo' : 'Marcar resolvido',
          icon: resolved ? LucideIcons.undo2 : LucideIcons.check,
          onPressed: onToggle,
        ),
      ],
    );

    return Opacity(
      opacity: resolved ? 0.62 : 1,
      child: PartnerCard(
        borderColor: palette.text,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact =
                constraints.maxWidth.isFinite && constraints.maxWidth < 520;
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      icon,
                      const SizedBox(width: YaSpacing.md),
                      Expanded(child: body),
                    ],
                  ),
                  const SizedBox(height: YaSpacing.md),
                  actions,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                icon,
                const SizedBox(width: YaSpacing.md),
                Expanded(child: body),
                const SizedBox(width: YaSpacing.md),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

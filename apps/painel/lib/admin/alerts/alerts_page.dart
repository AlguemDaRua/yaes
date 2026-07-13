import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/snack.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/filters/filter_bar.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/types.dart';

class AlertsPage extends ConsumerStatefulWidget {
  const AlertsPage({super.key});

  @override
  ConsumerState<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends ConsumerState<AlertsPage> {
  String _activeChip = 'all';

  static const _chips = [
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
  ];

  Future<void> _resolve(String id) async {
    try {
      await ref.read(adminDataRepositoryProvider).resolveAlert(id);
      if (!mounted) return;
      ref.invalidate(adminAlertsProvider);
      yaSnack(context, 'Alerta resolvido');
    } catch (e) {
      if (!mounted) return;
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  List<_Alert> _filteredRows(List<_Alert> rows) {
    if (_activeChip == 'all') return rows;
    if (_activeChip == 'critical') {
      return rows.where((alert) => alert.severity == 'critical').toList();
    }
    if (_activeChip == 'active') {
      return rows.where((alert) => !alert.resolved).toList();
    }
    return rows.where((alert) => alert.resolved).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final alertsAsync = ref.watch(adminAlertsProvider);

    return AsyncView<List<AdminAlert>>(
      value: alertsAsync,
      onRetry: () => ref.invalidate(adminAlertsProvider),
      data: (alerts) {
        final rows = alerts.map(_Alert.fromAdmin).toList();
        final filtered = _filteredRows(rows);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: S.of(context).adminAlertsTitle,
              description: 'Ocorrências que requerem atenção',
            ),
            const SizedBox(height: YaSpacing.xxl),
            FilterBar(
              chips: _chips,
              activeChipId: _activeChip,
              onChipSelected: (id) => setState(() => _activeChip = id),
              searchPlaceholder: 'Pesquisar alertas...',
            ),
            const SizedBox(height: YaSpacing.lg),
            for (final alert in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: YaSpacing.md),
                child: _AlertCard(
                  alert: alert,
                  onResolve: () => _resolve(alert.id),
                ),
              ),
            if (filtered.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(YaSpacing.huge),
                  child: Text(
                    'Sem alertas',
                    style: YaText.sm.copyWith(color: colors.textMuted),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.onResolve});

  final _Alert alert;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final variant = alert.severity == 'critical'
        ? StatusVariant.danger
        : StatusVariant.warning;
    final palette = variant.resolve(colors);

    return Container(
      padding: YaSpacing.cardMd,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: YaRadius.brLg,
        border: Border.all(
          color: alert.resolved
              ? colors.borderSubtle
              : palette.text.withValues(alpha: 0.3),
        ),
        boxShadow: isLight ? YaShadows.sm : YaShadows.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration:
                BoxDecoration(color: palette.bg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(
              alert.severity == 'critical'
                  ? LucideIcons.triangleAlert
                  : LucideIcons.circleAlert,
              size: 16,
              color: palette.text,
            ),
          ),
          const SizedBox(height: YaSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: YaSpacing.sm,
                runSpacing: YaSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusBadge.fromMapping(
                    StatusMapping(
                      variant,
                      alert.severity == 'critical' ? 'Crítico' : 'Atenção',
                    ),
                  ),
                  Text(
                    alert.title,
                    style:
                        YaText.baseMedium.copyWith(color: colors.textPrimary),
                  ),
                  if (alert.resolved)
                    StatusBadge.fromMapping(
                      const StatusMapping(
                        StatusVariant.success,
                        'Resolvido',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                alert.description,
                style: YaText.sm.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                '${alert.category} · ${alert.when}',
                style: YaText.sans(size: 11, height: 16)
                    .copyWith(color: colors.textMuted),
              ),
            ],
          ),
          if (!alert.resolved) ...[
            const SizedBox(height: YaSpacing.md),
            Wrap(
              spacing: YaSpacing.sm,
              runSpacing: YaSpacing.sm,
              children: [
                YaButton.secondary(
                  label: 'Marcar resolvido',
                  icon: LucideIcons.check,
                  onPressed: onResolve,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Alert {
  const _Alert(
    this.id,
    this.title,
    this.description,
    this.category,
    this.severity,
    this.resolved,
    this.when,
  );

  final String id;
  final String title;
  final String description;
  final String category;
  final String severity;
  final bool resolved;
  final String when;

  factory _Alert.fromAdmin(AdminAlert alert) {
    return _Alert(
      alert.id,
      alert.title,
      alert.description ?? '',
      alert.partnerId ?? 'Sistema',
      alert.severity,
      alert.resolved,
      _formatWhen(alert.createdAt),
    );
  }

  static String _formatWhen(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    return 'há ${diff.inDays} dias';
  }
}

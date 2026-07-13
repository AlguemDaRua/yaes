import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/filters/filter_bar.dart';
import '../../shared/widgets/forms/ya_avatar.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/types.dart';

class AuditPage extends ConsumerStatefulWidget {
  const AuditPage({super.key});

  @override
  ConsumerState<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends ConsumerState<AuditPage> {
  String _activeChip = 'all';

  static const _chips = [
    FilterChipSpec(id: 'all', label: 'Todos'),
    FilterChipSpec(id: 'auth', label: 'Auth'),
    FilterChipSpec(id: 'partners', label: 'Partners'),
    FilterChipSpec(id: 'drivers', label: 'Drivers'),
    FilterChipSpec(id: 'finance', label: 'Finanças'),
    FilterChipSpec(id: 'system', label: 'Sistema'),
  ];

  List<_AuditEntry> _rowsFrom(List<AdminAuditLog> logs) {
    return logs.map(_AuditEntry.fromAdmin).toList();
  }

  List<_AuditEntry> _filteredRows(List<_AuditEntry> rows) {
    if (_activeChip == 'all') return rows;
    return rows.where((entry) => entry.categoryKey == _activeChip).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final logsAsync = ref.watch(adminAuditLogsProvider);

    return AsyncView<List<AdminAuditLog>>(
      value: logsAsync,
      onRetry: () => ref.invalidate(adminAuditLogsProvider),
      data: (logs) {
        final rows = _rowsFrom(logs);
        final filtered = _filteredRows(rows);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: S.of(context).adminAuditTitle,
              description: 'Registo de todas as acções administrativas',
            ),
            const SizedBox(height: YaSpacing.xxl),
            FilterBar(
              chips: _chips,
              activeChipId: _activeChip,
              onChipSelected: (id) => setState(() => _activeChip = id),
              searchPlaceholder: 'Pesquisar por utilizador ou acção...',
            ),
            const SizedBox(height: YaSpacing.lg),
            for (final entry in filtered) _AuditEntryWidget(entry: entry),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(YaSpacing.huge),
                child: Center(
                  child: Text(
                    'Sem entradas',
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

class _AuditEntryWidget extends StatefulWidget {
  const _AuditEntryWidget({required this.entry});

  final _AuditEntry entry;

  @override
  State<_AuditEntryWidget> createState() => _AuditEntryWidgetState();
}

class _AuditEntryWidgetState extends State<_AuditEntryWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final entry = widget.entry;
    final dot = entry.variant.resolve(colors).text;
    final hasDiff = entry.diff.isNotEmpty;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                Expanded(
                  child: Center(
                    child: Container(width: 1, color: colors.borderSubtle),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: YaSpacing.md),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: YaSpacing.md),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: YaRadius.brLg,
                border: Border.all(color: colors.borderSubtle),
                boxShadow: isLight ? YaShadows.sm : YaShadows.none,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(YaSpacing.md),
                    child: Row(
                      children: [
                        YaAvatar.fromName(entry.author),
                        const SizedBox(width: YaSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: YaText.sm
                                      .copyWith(color: colors.textPrimary),
                                  children: [
                                    TextSpan(
                                      text: entry.author,
                                      style: YaText.smMedium
                                          .copyWith(color: colors.textPrimary),
                                    ),
                                    TextSpan(text: ' ${entry.action}'),
                                  ],
                                ),
                              ),
                              Text(
                                '${entry.when} · IP ${entry.ip}',
                                style: YaText.sans(size: 11, height: 16)
                                    .copyWith(color: colors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        if (hasDiff)
                          GestureDetector(
                            onTap: () => setState(() => _expanded = !_expanded),
                            child: Icon(
                              _expanded
                                  ? LucideIcons.chevronUp
                                  : LucideIcons.chevronDown,
                              size: 14,
                              color: colors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_expanded && hasDiff)
                    Container(
                      padding: const EdgeInsets.all(YaSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.bgSubtle,
                        border: Border(
                          top: BorderSide(color: colors.borderSubtle),
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final item in entry.diff.entries)
                            Text(
                              '${item.key}: ${item.value}',
                              style: YaText.monoSm
                                  .copyWith(color: colors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditEntry {
  const _AuditEntry(
    this.author,
    this.action,
    this.category,
    this.when,
    this.ip,
    this.variant,
    this.diff,
  );

  final String author;
  final String action;
  final String category;
  final String when;
  final String ip;
  final StatusVariant variant;
  final Map<String, String> diff;

  factory _AuditEntry.fromAdmin(AdminAuditLog log) {
    final metadata = log.metadata.map((key, value) {
      return MapEntry(key, value?.toString() ?? '');
    });
    return _AuditEntry(
      log.actorUid,
      log.action,
      _categoryFromAction(log.action),
      _formatWhen(log.createdAt),
      metadata['ip'] ?? '-',
      StatusVariant.neutral,
      metadata,
    );
  }

  String get categoryKey => switch (category) {
        'Auth' => 'auth',
        'Partners' => 'partners',
        'Drivers' => 'drivers',
        'Finanças' => 'finance',
        'Sistema' => 'system',
        _ => category.toLowerCase(),
      };

  static String _categoryFromAction(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('auth') || lower.contains('login')) return 'Auth';
    if (lower.contains('partner')) return 'Partners';
    if (lower.contains('driver')) return 'Drivers';
    if (lower.contains('commission') || lower.contains('finance')) {
      return 'Finanças';
    }
    return 'Sistema';
  }

  static String _formatWhen(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    return 'há ${diff.inDays} dias';
  }
}

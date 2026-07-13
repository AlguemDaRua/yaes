import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/utils/csv_export.dart';
import '../../shared/widgets/feedback/snack.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';

/// Relatórios gerados no cliente (CSV) a partir dos dados live; a data da
/// última geração fica em `/config/reports/{id}/lastGeneratedAt`.
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  String? _generating;

  static const _templates = [
    _ReportTemplate(
      'revenue',
      'Receita por partner',
      'Corridas completas e receita deste mês por cada partner.',
      LucideIcons.trendingUp,
    ),
    _ReportTemplate(
      'drivers',
      'Performance de drivers',
      'Estado, rating e corridas acumuladas por driver.',
      LucideIcons.user,
    ),
    _ReportTemplate(
      'documents',
      'Documentos a expirar',
      'Documentos com validade nos próximos 30 dias (ou já expirados).',
      LucideIcons.fileText,
    ),
    _ReportTemplate(
      'cancellations',
      'Cancelamentos',
      'Corridas canceladas com partner e data.',
      LucideIcons.ban,
    ),
    _ReportTemplate(
      'reconciliation',
      'Reconciliação financeira',
      'Pagamentos e payouts para validação contabilística.',
      LucideIcons.receipt,
    ),
  ];

  Future<List<List<Object?>>> _datasetFor(String id) async {
    final repo = ref.read(adminDataRepositoryProvider);
    final df = DateFormat('yyyy-MM-dd HH:mm');
    switch (id) {
      case 'revenue':
        final partners = await repo.listPartners();
        final trips = await repo.listTrips();
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month);
        return <List<Object?>>[
          <Object?>['partner', 'corridas_mes', 'receita_mtn'],
          for (final p in partners)
            <Object?>[
              p.name,
              trips
                  .where(
                    (t) =>
                        t.partnerId == p.id &&
                        t.status == 'completed' &&
                        !t.createdAt.isBefore(monthStart),
                  )
                  .length,
              trips
                  .where(
                    (t) =>
                        t.partnerId == p.id &&
                        t.status == 'completed' &&
                        !t.createdAt.isBefore(monthStart),
                  )
                  .fold<int>(0, (s, t) => s + t.amountMtn),
            ],
        ];
      case 'drivers':
        final drivers = await repo.listDrivers();
        return <List<Object?>>[
          <Object?>['driver', 'estado', 'online', 'rating', 'corridas'],
          for (final d in drivers)
            <Object?>[d.name, d.status, d.online, d.rating, d.tripsCount],
        ];
      case 'documents':
        final docs = await repo.listDocuments();
        final limit = DateTime.now().add(const Duration(days: 30));
        return <List<Object?>>[
          <Object?>['dono', 'tipo_dono', 'documento', 'estado', 'expira_em'],
          for (final d in docs)
            if (d.expiresAt != null && d.expiresAt!.isBefore(limit))
              <Object?>[
                d.ownerId,
                d.ownerType,
                d.type,
                d.status,
                df.format(d.expiresAt!),
              ],
        ];
      case 'cancellations':
        final trips = await repo.listTrips();
        return <List<Object?>>[
          <Object?>['trip', 'partner', 'passageiro', 'quando'],
          for (final t in trips)
            if (t.status == 'cancelled')
              <Object?>[
                t.id,
                t.partnerId ?? '-',
                t.passengerId ?? '-',
                df.format(t.createdAt),
              ],
        ];
      case 'reconciliation':
        final payments = await repo.listPayments();
        final payouts = await repo.listPayouts();
        return <List<Object?>>[
          <Object?>[
            'tipo',
            'id',
            'referencia',
            'valor_mtn',
            'estado',
            'quando',
          ],
          for (final p in payments)
            <Object?>[
              'pagamento',
              p.id,
              p.pspRef ?? '-',
              p.amountMtn,
              p.status,
              df.format(p.createdAt),
            ],
          for (final p in payouts)
            <Object?>[
              'payout',
              p.id,
              p.reference ?? '-',
              p.amountMtn,
              p.status,
              df.format(p.createdAt),
            ],
        ];
      default:
        return const <List<Object?>>[];
    }
  }

  Future<void> _generate(_ReportTemplate template) async {
    if (_generating != null) return;
    setState(() => _generating = template.id);
    try {
      final rows = await _datasetFor(template.id);
      if (rows.length <= 1) {
        if (mounted) {
          yaSnack(
            context,
            'Sem dados para este relatório',
            variant: StatusVariant.warning,
          );
        }
        return;
      }
      final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
      downloadCsv('${template.id}-$stamp.csv', rows);
      await ref.read(adminDataRepositoryProvider).setConfig(
        'reports/${template.id}',
        <String, Object?>{
          'lastGeneratedAt': DateTime.now().toIso8601String(),
        },
      );
      ref.invalidate(adminConfigProvider('reports'));
      if (mounted) yaSnack(context, 'Relatório gerado');
    } catch (e) {
      if (mounted) {
        yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
      }
    } finally {
      if (mounted) setState(() => _generating = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(adminConfigProvider('reports')).asData?.value ??
        const <String, dynamic>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: S.of(context).adminNavReports,
          description: 'Exportações CSV geradas a partir dos dados live',
        ),
        const SizedBox(height: YaSpacing.xxl),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth =
                constraints.maxWidth.isFinite && constraints.maxWidth < 340
                    ? constraints.maxWidth
                    : 320.0;

            return Wrap(
              spacing: YaSpacing.lg,
              runSpacing: YaSpacing.lg,
              children: _templates
                  .map(
                    (template) => SizedBox(
                      width: cardWidth,
                      child: _ReportCard(
                        template: template,
                        lastGenerated: _lastGenerated(meta, template.id),
                        generating: _generating == template.id,
                        onGenerate: () => _generate(template),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  String _lastGenerated(Map<String, dynamic> meta, String id) {
    final entry = meta[id];
    if (entry is! Map) return '—';
    final raw = entry['lastGeneratedAt'];
    final date = raw is String ? DateTime.tryParse(raw) : null;
    if (date == null) return '—';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.template,
    required this.lastGenerated,
    required this.generating,
    required this.onGenerate,
  });

  final _ReportTemplate template;
  final String lastGenerated;
  final bool generating;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: YaSpacing.cardMd,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: YaRadius.brLg,
        border: Border.all(color: colors.borderSubtle),
        boxShadow: isLight ? YaShadows.sm : YaShadows.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.brandSubtle,
                  borderRadius: YaRadius.brMd,
                ),
                alignment: Alignment.center,
                child: Icon(template.icon, size: 18, color: colors.brand),
              ),
              const SizedBox(width: YaSpacing.md),
              Expanded(
                child: Text(
                  template.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: YaText.smMedium.copyWith(color: colors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: YaSpacing.md),
          Text(
            template.description,
            style: YaText.sm.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: YaSpacing.sm),
          Text(
            'Última geração: $lastGenerated',
            style: YaText.sans(size: 11, height: 16)
                .copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: YaSpacing.lg),
          YaButton.secondary(
            label: generating ? 'A gerar...' : 'Gerar agora',
            icon: LucideIcons.play,
            onPressed: generating ? null : onGenerate,
          ),
        ],
      ),
    );
  }
}

class _ReportTemplate {
  const _ReportTemplate(this.id, this.title, this.description, this.icon);

  final String id;
  final String title;
  final String description;
  final IconData icon;
}

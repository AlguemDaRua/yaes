import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/charts/chart_card.dart';
import '../../shared/widgets/feedback/snack.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_field.dart';
import '../../shared/widgets/forms/ya_input.dart';
import '../../shared/widgets/forms/ya_select.dart';
import '../../shared/widgets/forms/ya_textarea.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../shared/widgets/table/cells.dart';
import '../../shared/widgets/table/data_table.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/types.dart';

/// Broadcast push via FCM topics (callable `sendBroadcast`); o histórico vem
/// de `/broadcasts`. Só apps com a subscrição de tópicos recebem.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  String _audience = 'all';
  String _title = '';
  String _body = '';
  bool _sending = false;

  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  static const _audienceItems = [
    YaSelectItem(value: 'all', label: 'Todos'),
    YaSelectItem(value: 'drivers', label: 'Apenas drivers'),
    YaSelectItem(value: 'passengers', label: 'Apenas passageiros'),
  ];

  static const _audienceLabels = {
    'all': 'Todos',
    'drivers': 'Drivers',
    'passengers': 'Passageiros',
  };

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(() => setState(() => _title = _titleCtrl.text));
    _bodyCtrl.addListener(() => setState(() => _body = _bodyCtrl.text));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      yaSnack(
        context,
        'Preenche o título e o corpo da mensagem.',
        variant: StatusVariant.danger,
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(cloudFunctionsServiceProvider).sendBroadcast(
            title: title,
            body: body,
            audience: _audience,
          );
      if (!mounted) return;
      _titleCtrl.clear();
      _bodyCtrl.clear();
      ref.invalidate(adminBroadcastsProvider);
      yaSnack(context, 'Broadcast enviado');
    } catch (e) {
      if (!mounted) return;
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final history = ref.watch(adminBroadcastsProvider).asData?.value ??
        const <AdminBroadcast>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: S.of(context).adminNavNotifications,
          description: 'Envia push para segmentos da plataforma (FCM topics)',
        ),
        const SizedBox(height: YaSpacing.xxl),
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth =
                constraints.maxWidth.isFinite ? constraints.maxWidth : 820.0;
            final contentWidth = availableWidth < 820 ? 820.0 : availableWidth;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: contentWidth,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
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
                            Text(
                              'Nova notificação push',
                              style: YaText.mdMedium
                                  .copyWith(color: colors.textPrimary),
                            ),
                            const SizedBox(height: YaSpacing.xxl),
                            YaField(
                              label: 'Audiência',
                              child: YaSelect<String>(
                                items: _audienceItems,
                                value: _audience,
                                onChanged: (value) =>
                                    setState(() => _audience = value),
                                width: 360,
                              ),
                            ),
                            const SizedBox(height: YaSpacing.lg),
                            YaField(
                              label: 'Título',
                              hint: '${_title.length}/50 caracteres',
                              child: YaInput(
                                controller: _titleCtrl,
                                placeholder: 'Ex: Manutenção programada amanhã',
                              ),
                            ),
                            const SizedBox(height: YaSpacing.lg),
                            YaField(
                              label: 'Corpo',
                              hint: '${_body.length}/200 caracteres',
                              child: YaTextarea(
                                controller: _bodyCtrl,
                                placeholder: 'Detalhe a mensagem...',
                                maxLines: 6,
                              ),
                            ),
                            const SizedBox(height: YaSpacing.xxl),
                            Wrap(
                              spacing: YaSpacing.sm,
                              runSpacing: YaSpacing.sm,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Chega a apps com a versão actual instalada',
                                  style: YaText.sm
                                      .copyWith(color: colors.textMuted),
                                ),
                                YaButton.primary(
                                  label:
                                      _sending ? 'A enviar...' : 'Enviar agora',
                                  icon: LucideIcons.send,
                                  onPressed: _sending ? null : _send,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: YaSpacing.lg),
                    SizedBox(
                      width: 280,
                      child: _NotificationPreview(title: _title, body: _body),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: YaSpacing.xxl),
        ChartCard(
          title: 'Histórico de broadcasts',
          chartHeight: 220,
          child: SingleChildScrollView(
            child: YaDataTable<AdminBroadcast>(
              density: YaTableDensity.compact,
              columns: [
                YaColumn(
                  key: 'title',
                  label: 'Título',
                  cellBuilder: (row) => TextCell(row.title),
                ),
                YaColumn(
                  key: 'audience',
                  label: 'Audiência',
                  width: 140,
                  cellBuilder: (row) => TextCell(
                    _audienceLabels[row.audience] ?? row.audience,
                  ),
                ),
                YaColumn(
                  key: 'status',
                  label: 'Estado',
                  width: 100,
                  cellBuilder: (row) => StatusBadge.fromMapping(
                    StatusMapping(
                      StatusVariant.success,
                      row.status == 'sent' ? 'Enviado' : row.status,
                    ),
                  ),
                ),
                YaColumn(
                  key: 'when',
                  label: 'Enviado',
                  width: 150,
                  cellBuilder: (row) => WhenCell(
                    DateFormat('dd/MM HH:mm').format(row.createdAt),
                  ),
                ),
              ],
              rows: history,
              keyExtractor: (row) => row.id,
              emptyIcon: LucideIcons.send,
              emptyTitle: 'Sem broadcasts',
              emptyDescription: 'As notificações enviadas aparecem aqui.',
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationPreview extends StatelessWidget {
  const _NotificationPreview({required this.title, required this.body});

  final String title;
  final String body;

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
          Text(
            'Pré-visualização',
            style: YaText.smMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: YaSpacing.lg),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgSubtle,
              borderRadius: YaRadius.brMd,
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.brand,
                    borderRadius: YaRadius.brSm,
                  ),
                  child: const Icon(
                    LucideIcons.zap,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isEmpty ? 'Título da notificação' : title,
                        style: YaText.smMedium.copyWith(
                          color: title.isEmpty
                              ? colors.textMuted
                              : colors.textPrimary,
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body.isEmpty
                            ? 'Corpo da mensagem aparece aqui...'
                            : body,
                        style: YaText.sans(size: 12, height: 16).copyWith(
                          color: body.isEmpty
                              ? colors.textMuted
                              : colors.textSecondary,
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

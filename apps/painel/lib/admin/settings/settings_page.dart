import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/locale_provider.dart';
import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/dialogs/form_dialog.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/snack.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_field.dart';
import '../../shared/widgets/forms/ya_input.dart';
import '../../shared/widgets/forms/ya_select.dart';
import '../../shared/widgets/forms/ya_switch.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/types.dart';

const _sections = [
  (id: 'general', label: 'Geral', icon: LucideIcons.settings),
  (id: 'flags', label: 'Feature flags', icon: LucideIcons.toggleLeft),
  (id: 'security', label: 'Segurança', icon: LucideIcons.shield),
  (id: 'limits', label: 'Limites', icon: LucideIcons.slidersHorizontal),
  (id: 'integrations', label: 'Integrações', icon: LucideIcons.plug),
  (id: 'webhooks', label: 'Webhooks', icon: LucideIcons.webhook),
  (id: 'branding', label: 'Branding', icon: LucideIcons.palette),
];

/// Configurações da plataforma, persistidas em `/config/platform`
/// (write admin-only via regras RTDB).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(adminConfigProvider('platform'));

    return AsyncView<Map<String, dynamic>>(
      value: configAsync,
      onRetry: () => ref.invalidate(adminConfigProvider('platform')),
      data: (config) => _SettingsBody(config: config),
    );
  }
}

class _SettingsBody extends ConsumerStatefulWidget {
  const _SettingsBody({required this.config});

  final Map<String, dynamic> config;

  @override
  ConsumerState<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends ConsumerState<_SettingsBody> {
  String _activeSection = 'general';
  bool _busy = false;

  // Geral
  late final TextEditingController _name = TextEditingController(
    text: _string('name') ?? 'YA',
  );
  late String _timezone = _string('timezone') ?? 'Africa/Maputo';
  late String _currency = _string('currency') ?? 'MTn';

  // Feature flags
  late bool _maintenance = _flag('maintenance', false);
  late bool _signupsEnabled = _flag('signupsEnabled', true);
  late bool _paymentsEnabled = _flag('paymentsEnabled', true);
  late bool _schedulingEnabled = _flag('schedulingEnabled', true);

  // Limites
  late final TextEditingController _maxDriversPerPartner =
      TextEditingController(text: _limit('maxDriversPerPartner', 100));
  late final TextEditingController _acceptTimeoutSeconds =
      TextEditingController(text: _limit('acceptTimeoutSeconds', 30));
  late int _payoutDayOfWeek = _payoutDay();

  String? _string(String key) {
    final Object? value = widget.config[key];
    return value is String ? value : null;
  }

  bool _flag(String key, bool fallback) {
    final Object? flags = widget.config['featureFlags'];
    if (flags is! Map) return fallback;
    final Object? value = flags[key];
    return value is bool ? value : fallback;
  }

  String _limit(String key, int fallback) {
    final Object? limits = widget.config['limits'];
    if (limits is! Map) return fallback.toString();
    final Object? value = limits[key];
    return value is num ? value.toInt().toString() : fallback.toString();
  }

  /// Dia ISO da semana (1=segunda .. 7=domingo) em que a YA processa os
  /// payouts semanais dos partners. Default sexta-feira.
  int _payoutDay() {
    final Object? schedule = widget.config['payoutSchedule'];
    if (schedule is! Map) return DateTime.friday;
    final Object? value = schedule['dayOfWeek'];
    return value is num && value >= 1 && value <= 7
        ? value.toInt()
        : DateTime.friday;
  }

  @override
  void dispose() {
    _name.dispose();
    _maxDriversPerPartner.dispose();
    _acceptTimeoutSeconds.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    final int? maxDrivers = int.tryParse(_maxDriversPerPartner.text.trim());
    final int? timeout = int.tryParse(_acceptTimeoutSeconds.text.trim());
    if (maxDrivers == null ||
        maxDrivers <= 0 ||
        timeout == null ||
        timeout <= 0) {
      yaSnack(context, 'Limites inválidos.', variant: StatusVariant.danger);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(adminDataRepositoryProvider).setConfig(
        'platform',
        <String, Object?>{
          'name': _name.text.trim().isEmpty ? 'YA' : _name.text.trim(),
          'timezone': _timezone,
          'currency': _currency,
          'featureFlags': <String, Object?>{
            'maintenance': _maintenance,
            'signupsEnabled': _signupsEnabled,
            'paymentsEnabled': _paymentsEnabled,
            'schedulingEnabled': _schedulingEnabled,
          },
          'limits': <String, Object?>{
            'maxDriversPerPartner': maxDrivers,
            'acceptTimeoutSeconds': timeout,
          },
          'payoutSchedule': <String, Object?>{
            'dayOfWeek': _payoutDayOfWeek,
          },
        },
      );
      if (!mounted) return;
      ref.invalidate(adminConfigProvider('platform'));
      yaSnack(context, 'Configurações guardadas');
    } catch (e) {
      if (!mounted) return;
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: S.of(context).adminSettingsTitle,
          description: 'Configurações gerais da plataforma YA',
          actions: [
            YaButton.primary(
              label: _busy ? 'A guardar...' : 'Guardar',
              icon: LucideIcons.save,
              onPressed: _busy ? null : _save,
            ),
          ],
        ),
        const SizedBox(height: YaSpacing.xxl),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth.isFinite && constraints.maxWidth < 780;
            final nav = SizedBox(
              width: compact ? double.infinity : 240,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: YaRadius.brLg,
                  border: Border.all(color: colors.borderSubtle),
                  boxShadow: isLight ? YaShadows.sm : YaShadows.none,
                ),
                child: Column(
                  children: [
                    for (final section in _sections)
                      _SettingsNavItem(
                        label: section.label,
                        icon: section.icon,
                        active: _activeSection == section.id,
                        onTap: () =>
                            setState(() => _activeSection = section.id),
                      ),
                  ],
                ),
              ),
            );
            final content = _sectionContent(_activeSection, colors, isLight);

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  nav,
                  const SizedBox(height: YaSpacing.lg),
                  content,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                nav,
                const SizedBox(width: YaSpacing.xxl),
                Expanded(child: content),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _sectionContent(String id, YaColors colors, bool isLight) {
    return switch (id) {
      'general' => _buildGeneral(colors, isLight),
      'flags' => _buildFlags(colors, isLight),
      'security' => _SectionSecurity(colors: colors, isLight: isLight),
      'limits' => _buildLimits(colors, isLight),
      'integrations' => _SectionIntegrations(colors: colors, isLight: isLight),
      'webhooks' => _SectionWebhooks(colors: colors, isLight: isLight),
      'branding' => _SectionBranding(colors: colors, isLight: isLight),
      _ => _buildGeneral(colors, isLight),
    };
  }

  Widget _buildGeneral(YaColors colors, bool isLight) {
    final S s = S.of(context);
    final Locale locale = ref.watch(localeProv);
    return _SettingsCard(
      title: 'Geral',
      colors: colors,
      isLight: isLight,
      child: Column(
        children: [
          YaField(
            label: 'Nome da plataforma',
            child: YaInput(controller: _name, placeholder: 'YA'),
          ),
          const SizedBox(height: YaSpacing.lg),
          YaField(
            label: 'Fuso horário',
            child: YaSelect<String>(
              items: const [
                YaSelectItem(
                  value: 'Africa/Maputo',
                  label: 'Africa/Maputo (UTC+2)',
                ),
                YaSelectItem(value: 'UTC', label: 'UTC'),
              ],
              value: _timezone,
              onChanged: (value) => setState(() => _timezone = value),
              width: 360,
            ),
          ),
          const SizedBox(height: YaSpacing.lg),
          YaField(
            label: 'Moeda',
            child: YaSelect<String>(
              items: const [
                YaSelectItem(value: 'MTn', label: 'Metical (MTn)'),
              ],
              value: _currency,
              onChanged: (value) => setState(() => _currency = value),
              width: 360,
            ),
          ),
          const SizedBox(height: YaSpacing.lg),
          YaField(
            label: s.commonLanguage,
            child: YaSelect<String>(
              items: const <YaSelectItem<String>>[
                YaSelectItem<String>(value: 'pt', label: 'Português'),
                YaSelectItem<String>(value: 'en', label: 'English'),
              ],
              value: locale.languageCode,
              onChanged: (String code) async {
                await LocaleNotifier.save(Locale(code), ref);
              },
              width: 360,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlags(YaColors colors, bool isLight) {
    return _SettingsCard(
      title: 'Feature flags',
      colors: colors,
      isLight: isLight,
      child: Column(
        children: [
          YaSwitch(
            value: _maintenance,
            onChanged: (value) => setState(() => _maintenance = value),
            label: 'Modo manutenção',
            subtitle: 'Sinaliza manutenção em /config/platform/featureFlags',
          ),
          const SizedBox(height: YaSpacing.lg),
          YaSwitch(
            value: _signupsEnabled,
            onChanged: (value) => setState(() => _signupsEnabled = value),
            label: 'Novos registos',
            subtitle: 'Permite registo de novos drivers e passageiros',
          ),
          const SizedBox(height: YaSpacing.lg),
          YaSwitch(
            value: _paymentsEnabled,
            onChanged: (value) => setState(() => _paymentsEnabled = value),
            label: 'Pagamentos online',
            subtitle: 'Habilita pagamento via M-Pesa e e-Mola',
          ),
          const SizedBox(height: YaSpacing.lg),
          YaSwitch(
            value: _schedulingEnabled,
            onChanged: (value) => setState(() => _schedulingEnabled = value),
            label: 'Corridas agendadas',
            subtitle: 'Permite agendar corridas com antecedência',
          ),
        ],
      ),
    );
  }

  Widget _buildLimits(YaColors colors, bool isLight) {
    return _SettingsCard(
      title: 'Limites operacionais',
      colors: colors,
      isLight: isLight,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Máx. drivers por partner',
                  style: YaText.sm.copyWith(color: colors.textSecondary),
                ),
              ),
              SizedBox(
                width: 100,
                child: YaInput(
                  controller: _maxDriversPerPartner,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: YaSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Timeout de aceitação (segundos)',
                  style: YaText.sm.copyWith(color: colors.textSecondary),
                ),
              ),
              SizedBox(
                width: 100,
                child: YaInput(
                  controller: _acceptTimeoutSeconds,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: YaSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Dia do payout semanal dos partners',
                  style: YaText.sm.copyWith(color: colors.textSecondary),
                ),
              ),
              SizedBox(
                width: 180,
                child: YaSelect<int>(
                  value: _payoutDayOfWeek,
                  items: const [
                    YaSelectItem<int>(value: DateTime.monday, label: 'Segunda'),
                    YaSelectItem<int>(value: DateTime.tuesday, label: 'Terça'),
                    YaSelectItem<int>(value: DateTime.wednesday, label: 'Quarta'),
                    YaSelectItem<int>(value: DateTime.thursday, label: 'Quinta'),
                    YaSelectItem<int>(value: DateTime.friday, label: 'Sexta'),
                    YaSelectItem<int>(value: DateTime.saturday, label: 'Sábado'),
                    YaSelectItem<int>(value: DateTime.sunday, label: 'Domingo'),
                  ],
                  onChanged: (int value) =>
                      setState(() => _payoutDayOfWeek = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsNavItem extends StatelessWidget {
  const _SettingsNavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: YaSpacing.lg,
          vertical: YaSpacing.md,
        ),
        decoration: BoxDecoration(
          color: active ? colors.brandSubtle : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: active ? colors.brand : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? colors.brand : colors.textMuted,
            ),
            const SizedBox(width: YaSpacing.sm),
            Text(
              label,
              style: YaText.sm.copyWith(
                color: active ? colors.brand : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Segurança: revogação de sessões por gestor. O Firebase Auth não expõe a
/// lista de sessões individuais — apenas a invalidação global por utilizador.
class _SectionSecurity extends ConsumerWidget {
  const _SectionSecurity({required this.colors, required this.isLight});

  final YaColors colors;
  final bool isLight;

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    AdminUser user,
  ) async {
    try {
      await ref.read(cloudFunctionsServiceProvider).revokeUserSessions(user.id);
      if (!context.mounted) return;
      yaSnack(context, 'Sessões revogadas — novo login obrigatório');
    } catch (e) {
      if (!context.mounted) return;
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users =
        ref.watch(adminUsersProvider).asData?.value ?? const <AdminUser>[];
    final managers =
        users.where((u) => u.type == 'admin' || u.type == 'support').toList();

    return _SettingsCard(
      title: 'Segurança',
      colors: colors,
      isLight: isLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revogar sessões termina o acesso de um gestor em todos os '
            'dispositivos (o próximo pedido exige novo login).',
            style: YaText.sm.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: YaSpacing.lg),
          if (managers.isEmpty)
            Text(
              'Sem gestores registados.',
              style: YaText.sm.copyWith(color: colors.textMuted),
            ),
          for (final manager in managers)
            Padding(
              padding: const EdgeInsets.only(bottom: YaSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          manager.email ?? manager.name ?? manager.id,
                          style: YaText.smMedium
                              .copyWith(color: colors.textPrimary),
                        ),
                        Text(
                          manager.type == 'admin' ? 'Admin' : 'Suporte',
                          style: YaText.sans(size: 12, height: 16)
                              .copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  YaButton.ghost(
                    label: 'Revogar sessões',
                    icon: LucideIcons.x,
                    onPressed: () => _revoke(context, ref, manager),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Estado honesto: as credenciais de pagamento vivem no Secret Manager do
/// GCP e são geridas por CLI (`firebase functions:secrets:set`), não aqui.
class _SectionIntegrations extends StatelessWidget {
  const _SectionIntegrations({required this.colors, required this.isLight});

  final YaColors colors;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'Integrações externas',
      colors: colors,
      isLight: isLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'As chaves M-Pesa e e-Mola são geridas via Secret Manager no '
            'Google Cloud (firebase functions:secrets:set). Enquanto as '
            'chaves reais não forem definidas, os pagamentos correm em '
            'modo sandbox.',
            style: YaText.sm.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: YaSpacing.lg),
          for (final item in const [
            ('MPESA_API_KEY / MPESA_PUBLIC_KEY / MPESA_SERVICE_PROVIDER_CODE'),
            ('EMOLA_API_KEY / EMOLA_WALLET_ID'),
            ('PAYMENTS_WEBHOOK_SECRET'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: YaSpacing.sm),
              child: Text(
                item,
                style: YaText.monoSm.copyWith(color: colors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

const _webhookEvents = ['trip.status', 'payment.updated'];

/// Webhooks de saída: `/config/webhooks/{id}` — as Functions assinam o POST
/// com HMAC (`X-Ya-Signature`) nos eventos trip.status e payment.updated.
class _SectionWebhooks extends ConsumerWidget {
  const _SectionWebhooks({required this.colors, required this.isLight});

  final YaColors colors;
  final bool isLight;

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    String id,
    Map<String, dynamic> hook,
    bool active,
  ) async {
    try {
      await ref.read(adminDataRepositoryProvider).setConfig(
        'webhooks/$id',
        <String, Object?>{...hook, 'active': active},
      );
      ref.invalidate(adminConfigProvider('webhooks'));
    } catch (e) {
      if (!context.mounted) return;
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(adminDataRepositoryProvider).removeConfig('webhooks/$id');
      ref.invalidate(adminConfigProvider('webhooks'));
      if (!context.mounted) return;
      yaSnack(context, 'Webhook removido');
    } catch (e) {
      if (!context.mounted) return;
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hooks = ref.watch(adminConfigProvider('webhooks')).asData?.value ??
        const <String, dynamic>{};

    return _SettingsCard(
      title: 'Webhooks de saída',
      colors: colors,
      isLight: isLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Endpoints HTTP notificados nos eventos da plataforma. Cada '
            'POST é assinado com HMAC-SHA256 no header X-Ya-Signature.',
            style: YaText.sm.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: YaSpacing.lg),
          if (hooks.isEmpty)
            Text(
              'Sem webhooks configurados.',
              style: YaText.sm.copyWith(color: colors.textMuted),
            ),
          for (final entry in hooks.entries)
            if (entry.value is Map)
              Padding(
                padding: const EdgeInsets.only(bottom: YaSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (entry.value as Map)['url']?.toString() ?? '-',
                            style: YaText.monoSm
                                .copyWith(color: colors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _eventsLabel(entry.value as Map),
                            style: YaText.sans(size: 12, height: 16)
                                .copyWith(color: colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    YaSwitch(
                      value: (entry.value as Map)['active'] == true,
                      onChanged: (value) => _toggle(
                        context,
                        ref,
                        entry.key,
                        Map<String, dynamic>.from(entry.value as Map),
                        value,
                      ),
                      label: (entry.value as Map)['active'] == true
                          ? 'Activo'
                          : 'Inactivo',
                    ),
                    const SizedBox(width: YaSpacing.sm),
                    YaButton.ghost(
                      label: 'Remover',
                      icon: LucideIcons.trash2,
                      onPressed: () => _delete(context, ref, entry.key),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: YaSpacing.md),
          YaButton.secondary(
            label: 'Adicionar webhook',
            icon: LucideIcons.plus,
            onPressed: () => showDialog<void>(
              context: context,
              builder: (BuildContext _) => const _WebhookDialog(),
            ),
          ),
        ],
      ),
    );
  }

  String _eventsLabel(Map<dynamic, dynamic> hook) {
    final events = hook['events'];
    if (events is List) return events.join(' · ');
    if (events is Map) {
      return events.entries
          .where((e) => e.value == true)
          .map((e) => e.key)
          .join(' · ');
    }
    return 'sem eventos';
  }
}

class _WebhookDialog extends ConsumerStatefulWidget {
  const _WebhookDialog();

  @override
  ConsumerState<_WebhookDialog> createState() => _WebhookDialogState();
}

class _WebhookDialogState extends ConsumerState<_WebhookDialog> {
  final TextEditingController _url = TextEditingController();
  final TextEditingController _secret = TextEditingController();
  final Set<String> _events = {..._webhookEvents};
  bool _busy = false;

  @override
  void dispose() {
    _url.dispose();
    _secret.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final url = _url.text.trim();
    if (!url.startsWith('https://')) {
      yaSnack(
        context,
        'Indica um URL https:// válido.',
        variant: StatusVariant.danger,
      );
      return;
    }
    if (_events.isEmpty) {
      yaSnack(
        context,
        'Seleciona pelo menos um evento.',
        variant: StatusVariant.danger,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      await ref.read(adminDataRepositoryProvider).setConfig(
        'webhooks/$id',
        <String, Object?>{
          'url': url,
          'secret': _secret.text.trim(),
          'events': _events.toList(),
          'active': true,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      if (!mounted) return;
      ref.invalidate(adminConfigProvider('webhooks'));
      Navigator.of(context).pop();
      yaSnack(context, 'Webhook adicionado');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Novo webhook',
      description: 'O endpoint recebe POSTs JSON assinados com o secret.',
      confirmLabel: 'Adicionar',
      submitting: _busy,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _submit,
      children: <Widget>[
        YaField(
          label: 'URL (https)',
          child: YaInput(
            controller: _url,
            placeholder: 'https://exemplo.com/ya-webhook',
          ),
        ),
        YaField(
          label: 'Secret (para a assinatura HMAC)',
          child: YaInput(
            controller: _secret,
            placeholder: 'opcional mas recomendado',
          ),
        ),
        YaField(
          label: 'Eventos',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final event in _webhookEvents)
                YaSwitch(
                  value: _events.contains(event),
                  onChanged: (value) => setState(() {
                    if (value) {
                      _events.add(event);
                    } else {
                      _events.remove(event);
                    }
                  }),
                  label: event,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Branding: `/config/branding` — nome, cor primária e logo. A aplicação do
/// tema na app móvel exige release novo (tema compilado).
class _SectionBranding extends ConsumerStatefulWidget {
  const _SectionBranding({required this.colors, required this.isLight});

  final YaColors colors;
  final bool isLight;

  @override
  ConsumerState<_SectionBranding> createState() => _SectionBrandingState();
}

class _SectionBrandingState extends ConsumerState<_SectionBranding> {
  final TextEditingController _appName = TextEditingController();
  final TextEditingController _colorHex = TextEditingController();
  final TextEditingController _logoUrl = TextEditingController();
  bool _loaded = false;
  bool _busy = false;

  @override
  void dispose() {
    _appName.dispose();
    _colorHex.dispose();
    _logoUrl.dispose();
    super.dispose();
  }

  void _hydrate(Map<String, dynamic> config) {
    if (_loaded) return;
    _loaded = true;
    _appName.text = config['appName']?.toString() ?? 'YA';
    _colorHex.text = config['primaryColorHex']?.toString() ?? '#E5A400';
    _logoUrl.text = config['logoUrl']?.toString() ?? '';
  }

  Future<void> _save() async {
    if (_busy) return;
    final hex = _colorHex.text.trim();
    if (!RegExp(r'^#([0-9a-fA-F]{6})$').hasMatch(hex)) {
      yaSnack(
        context,
        'Cor inválida — usa o formato #RRGGBB.',
        variant: StatusVariant.danger,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(adminDataRepositoryProvider).setConfig(
        'branding',
        <String, Object?>{
          'appName': _appName.text.trim().isEmpty ? 'YA' : _appName.text.trim(),
          'primaryColorHex': hex,
          'logoUrl': _logoUrl.text.trim(),
        },
      );
      if (!mounted) return;
      ref.invalidate(adminConfigProvider('branding'));
      yaSnack(context, 'Branding guardado');
    } catch (e) {
      if (!mounted) return;
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(adminConfigProvider('branding')).asData?.value ??
        const <String, dynamic>{};
    _hydrate(config);

    Color? preview;
    final hex = _colorHex.text.trim();
    if (RegExp(r'^#([0-9a-fA-F]{6})$').hasMatch(hex)) {
      preview = Color(int.parse('FF${hex.substring(1)}', radix: 16));
    }

    return _SettingsCard(
      title: 'Branding',
      colors: widget.colors,
      isLight: widget.isLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YaField(
            label: 'Nome da app',
            child: YaInput(controller: _appName, placeholder: 'YA'),
          ),
          const SizedBox(height: YaSpacing.lg),
          YaField(
            label: 'Cor primária (#RRGGBB)',
            child: Row(
              children: [
                SizedBox(
                  width: 160,
                  child: YaInput(
                    controller: _colorHex,
                    placeholder: '#E5A400',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: YaSpacing.sm),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: preview ?? Colors.transparent,
                    borderRadius: YaRadius.brSm,
                    border: Border.all(color: widget.colors.borderSubtle),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: YaSpacing.lg),
          YaField(
            label: 'URL do logo',
            child: YaInput(
              controller: _logoUrl,
              placeholder: 'https://.../logo.png',
            ),
          ),
          const SizedBox(height: YaSpacing.lg),
          Text(
            'O tema da app móvel é compilado — mudanças de cor/logo na app '
            'exigem um release novo.',
            style: YaText.sans(size: 12, height: 16)
                .copyWith(color: widget.colors.textMuted),
          ),
          const SizedBox(height: YaSpacing.lg),
          YaButton.primary(
            label: _busy ? 'A guardar...' : 'Guardar branding',
            icon: LucideIcons.save,
            onPressed: _busy ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.child,
    required this.colors,
    required this.isLight,
  });

  final String title;
  final Widget child;
  final YaColors colors;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: YaSpacing.cardLg,
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
            title,
            style: YaText.mdMedium.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: YaSpacing.xxl),
          child,
        ],
      ),
    );
  }
}

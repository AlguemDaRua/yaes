import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/locale_provider.dart';
import '../../data/providers.dart';
import '../../core/constants/status_mapping.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/dialogs/form_dialog.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/empty_state.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_field.dart';
import '../../shared/widgets/forms/ya_input.dart';
import '../../shared/widgets/forms/ya_select.dart';
import '../../shared/widgets/forms/ya_switch.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/mock_partner_data.dart';
import '../widgets/partner_common.dart';

/// Definições do partner. Empresa e Contactos persistem via `updateProfile`;
/// Equipa persiste via `invitePartnerStaff`/`partners/{id}/staff`. Pagamentos,
/// Notificações e gestão de sessões dependem de backend ainda inexistente
/// (ver docs/PANEL_BACKLOG.md).
class PartnerSettingsPage extends ConsumerStatefulWidget {
  const PartnerSettingsPage({super.key});

  @override
  ConsumerState<PartnerSettingsPage> createState() =>
      _PartnerSettingsPageState();
}

class _PartnerSettingsPageState extends ConsumerState<PartnerSettingsPage> {
  String _section = 'Empresa';

  static const List<_SettingsSection> _sections = <_SettingsSection>[
    _SettingsSection('Empresa', LucideIcons.building2),
    _SettingsSection('Contactos', LucideIcons.phone),
    _SettingsSection('Equipa', LucideIcons.users),
    _SettingsSection('Pagamentos', LucideIcons.banknote),
    _SettingsSection('Notificações', LucideIcons.bell),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PageHeader(
          title: S.of(context).commonSettings,
          description: 'Configuração da conta partner e da tua operação',
        ),
        const SizedBox(height: YaSpacing.xxl),
        PartnerCard(
          padding: EdgeInsets.zero,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact =
                  constraints.maxWidth.isFinite && constraints.maxWidth < 860;
              if (compact) {
                return Column(
                  children: <Widget>[
                    _SettingsNav(
                      sections: _sections,
                      selected: _section,
                      onTap: (String value) => setState(() => _section = value),
                    ),
                    Divider(
                        height: 1, color: YaColors.of(context).borderSubtle,),
                    Padding(
                      padding: const EdgeInsets.all(YaSpacing.xl),
                      child: _content(),
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 240,
                    child: _SettingsNav(
                      sections: _sections,
                      selected: _section,
                      onTap: (String value) => setState(() => _section = value),
                    ),
                  ),
                  Container(
                    width: 1,
                    constraints: const BoxConstraints(minHeight: 420),
                    color: YaColors.of(context).borderSubtle,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(YaSpacing.xl),
                      child: _content(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _content() {
    return switch (_section) {
      'Contactos' => const _ContactsSection(),
      'Equipa' => const _TeamSection(),
      'Pagamentos' => const _PaymentsSection(),
      'Notificações' => const _NotificationsSection(),
      _ => const _CompanySection(),
    };
  }
}

class _SettingsNav extends StatelessWidget {
  const _SettingsNav({
    required this.sections,
    required this.selected,
    required this.onTap,
  });

  final List<_SettingsSection> sections;
  final String selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(YaSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final _SettingsSection section in sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: InkWell(
                onTap: () => onTap(section.label),
                borderRadius: YaRadius.brMd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: YaSpacing.md,
                    vertical: YaSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: section.label == selected
                        ? colors.brandSubtle
                        : Colors.transparent,
                    borderRadius: YaRadius.brMd,
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        section.icon,
                        size: 16,
                        color: section.label == selected
                            ? colors.brand
                            : colors.textSecondary,
                      ),
                      const SizedBox(width: YaSpacing.sm),
                      Expanded(
                        child: Text(
                          section.label,
                          style: YaText.smMedium.copyWith(
                            color: section.label == selected
                                ? colors.brand
                                : colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompanySection extends ConsumerStatefulWidget {
  const _CompanySection();

  @override
  ConsumerState<_CompanySection> createState() => _CompanySectionState();
}

class _CompanySectionState extends ConsumerState<_CompanySection> {
  final TextEditingController _name = TextEditingController();
  bool _seeded = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _seed(MockPartnerProfile? profile) {
    if (_seeded || profile == null) return;
    _name.text = profile.name;
    _seeded = true;
  }

  Future<void> _save() async {
    if (_busy) return;
    final String name = _name.text.trim();
    if (name.length < 2) {
      partnerToast(
        context,
        'Nome inválido (mínimo 2 caracteres).',
        variant: StatusVariant.danger,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(partnerDataRepositoryProvider)
          .updateProfile(<String, dynamic>{'name': name});
      ref.invalidate(partnerProfileProvider);
      if (mounted) partnerToast(context, 'Perfil actualizado');
    } catch (e) {
      if (mounted) {
        partnerToast(context, 'Erro: $e', variant: StatusVariant.danger);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final Locale locale = ref.watch(localeProv);
    final MockPartnerProfile? profile =
        ref.watch(partnerProfileProvider).value;
    _seed(profile);
    return _SettingsForm(
      title: 'Empresa',
      children: <Widget>[
        YaInput(
          label: 'Nome da empresa',
          controller: _name,
          placeholder: 'Nome da empresa',
        ),
        YaInput(
          label: 'NUIT',
          placeholder: profile?.nuit ?? '—',
          enabled: false,
        ),
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
        YaButton.primary(
          label: _busy ? 'A guardar…' : 'Guardar alterações',
          onPressed: _busy ? null : _save,
        ),
      ],
    );
  }
}

class _ContactsSection extends ConsumerStatefulWidget {
  const _ContactsSection();

  @override
  ConsumerState<_ContactsSection> createState() => _ContactsSectionState();
}

class _ContactsSectionState extends ConsumerState<_ContactsSection> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  bool _seeded = false;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _seed(MockPartnerProfile? profile) {
    if (_seeded || profile == null) return;
    _phone.text = profile.phone;
    _email.text = profile.email;
    _seeded = true;
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(partnerDataRepositoryProvider)
          .updateProfile(<String, dynamic>{
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
      });
      ref.invalidate(partnerProfileProvider);
      if (mounted) partnerToast(context, 'Contactos actualizados');
    } catch (e) {
      if (mounted) {
        partnerToast(context, 'Erro: $e', variant: StatusVariant.danger);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MockPartnerProfile? profile =
        ref.watch(partnerProfileProvider).value;
    _seed(profile);
    return _SettingsForm(
      title: 'Contactos',
      children: <Widget>[
        YaInput(
          label: 'Telefone principal',
          controller: _phone,
          placeholder: '+258 84 000 0000',
        ),
        YaInput(
          label: 'Email principal',
          controller: _email,
          placeholder: 'empresa@exemplo.co.mz',
        ),
        YaButton.primary(
          label: _busy ? 'A guardar…' : 'Guardar alterações',
          onPressed: _busy ? null : _save,
        ),
      ],
    );
  }
}

class _PaymentsSection extends ConsumerStatefulWidget {
  const _PaymentsSection();

  @override
  ConsumerState<_PaymentsSection> createState() => _PaymentsSectionState();
}

class _PaymentsSectionState extends ConsumerState<_PaymentsSection> {
  final TextEditingController _mpesaNumber = TextEditingController();
  final TextEditingController _iban = TextEditingController();
  String _method = 'none';
  bool _seeded = false;
  bool _busy = false;

  @override
  void dispose() {
    _mpesaNumber.dispose();
    _iban.dispose();
    super.dispose();
  }

  void _seed(MockPartnerProfile? profile) {
    if (_seeded || profile == null) return;
    _method = profile.payoutMethod;
    _mpesaNumber.text = profile.payoutMpesaNumber ?? '';
    _iban.text = profile.payoutIban ?? '';
    _seeded = true;
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_method == 'mpesa' && _mpesaNumber.text.trim().length < 9) {
      partnerToast(
        context,
        'Número M-Pesa inválido.',
        variant: StatusVariant.danger,
      );
      return;
    }
    if (_method == 'iban' && _iban.text.trim().length < 8) {
      partnerToast(
        context,
        'IBAN inválido.',
        variant: StatusVariant.danger,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(partnerDataRepositoryProvider).updateProfile(
        <String, dynamic>{
          'payout': <String, dynamic>{
            'method': _method,
            if (_method == 'mpesa') 'mpesaNumber': _mpesaNumber.text.trim(),
            if (_method == 'iban') 'iban': _iban.text.trim(),
          },
        },
      );
      ref.invalidate(partnerProfileProvider);
      if (mounted) partnerToast(context, 'Método de pagamento actualizado');
    } catch (e) {
      if (mounted) {
        partnerToast(context, 'Erro: $e', variant: StatusVariant.danger);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MockPartnerProfile? profile =
        ref.watch(partnerProfileProvider).value;
    _seed(profile);
    return _SettingsForm(
      title: 'Pagamentos',
      children: <Widget>[
        YaField(
          label: 'Como recebes os payouts da YA',
          child: YaSelect<String>(
            width: 320,
            items: const <YaSelectItem<String>>[
              YaSelectItem<String>(value: 'none', label: 'Não definido'),
              YaSelectItem<String>(value: 'mpesa', label: 'M-Pesa'),
              YaSelectItem<String>(value: 'iban', label: 'Transferência bancária (IBAN)'),
            ],
            value: _method,
            onChanged: (String value) => setState(() => _method = value),
          ),
        ),
        if (_method == 'mpesa')
          YaInput(
            label: 'Número M-Pesa',
            controller: _mpesaNumber,
            placeholder: '+258 84 000 0000',
          ),
        if (_method == 'iban')
          YaInput(
            label: 'IBAN',
            controller: _iban,
            placeholder: 'MZ00 0000 0000 0000 0000 0',
          ),
        YaButton.primary(
          label: _busy ? 'A guardar…' : 'Guardar alterações',
          onPressed: _busy ? null : _save,
        ),
      ],
    );
  }
}

class _NotificationsSection extends ConsumerStatefulWidget {
  const _NotificationsSection();

  @override
  ConsumerState<_NotificationsSection> createState() =>
      _NotificationsSectionState();
}

class _NotificationsSectionState extends ConsumerState<_NotificationsSection> {
  bool _busy = false;

  Future<void> _toggle(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(partnerDataRepositoryProvider).updateProfile(
        <String, dynamic>{
          'notificationPrefs': <String, dynamic>{'broadcastsEnabled': value},
        },
      );
      ref.invalidate(partnerProfileProvider);
      if (mounted) {
        partnerToast(
          context,
          value
              ? 'Notificações da YA reativadas para a frota'
              : 'Frota deixa de receber notificações da YA',
        );
      }
    } catch (e) {
      if (mounted) {
        partnerToast(context, 'Erro: $e', variant: StatusVariant.danger);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MockPartnerProfile? profile =
        ref.watch(partnerProfileProvider).value;
    return _SettingsForm(
      title: 'Notificações',
      children: <Widget>[
        YaSwitch(
          label: 'Notificações da YA para a frota',
          subtitle: 'Campanhas e avisos gerais enviados pela YA aos teus '
              'motoristas. Não afecta notificações de viagens.',
          value: profile?.broadcastsEnabled ?? true,
          onChanged: _busy || profile == null ? null : _toggle,
        ),
      ],
    );
  }
}

class _TeamSection extends ConsumerWidget {
  const _TeamSection();

  static String _roleLabel(String role) {
    return switch (role) {
      'partner_owner' => 'Dono',
      _ => 'Equipa',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final YaColors colors = YaColors.of(context);
    final AsyncValue<List<MockPartnerStaff>> staffAsync =
        ref.watch(staffProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PartnerSectionTitle(
          title: 'Equipa',
          subtitle: 'Contas de login com acesso a este painel',
          action: YaButton.primary(
            label: 'Convidar',
            icon: LucideIcons.userPlus,
            onPressed: () => showDialog<void>(
              context: context,
              builder: (BuildContext _) => const _InvitePartnerStaffDialog(),
            ),
          ),
        ),
        const SizedBox(height: YaSpacing.lg),
        AsyncView<List<MockPartnerStaff>>(
          value: staffAsync,
          onRetry: () => ref.invalidate(staffProvider),
          data: (List<MockPartnerStaff> staff) {
            if (staff.isEmpty) {
              return const EmptyState(
                icon: LucideIcons.users,
                title: 'Sem membros da equipa',
                description: 'Convida alguém para gerir o painel contigo.',
              );
            }
            return Column(
              children: <Widget>[
                for (int i = 0; i < staff.length; i++) ...<Widget>[
                  _StaffRow(staff: staff[i], roleLabel: _roleLabel),
                  if (i < staff.length - 1)
                    Divider(height: YaSpacing.lg, color: colors.borderSubtle),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({required this.staff, required this.roleLabel});

  final MockPartnerStaff staff;
  final String Function(String role) roleLabel;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    return Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.brandSubtle,
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.user, size: 18, color: colors.brand),
        ),
        const SizedBox(width: YaSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                staff.name,
                style: YaText.smMedium.copyWith(color: colors.textPrimary),
              ),
              Text(
                staff.email,
                style: YaText.sans(size: 12, height: 16)
                    .copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
        Text(
          roleLabel(staff.role),
          style: YaText.smMedium.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _InvitePartnerStaffDialog extends ConsumerStatefulWidget {
  const _InvitePartnerStaffDialog();

  @override
  ConsumerState<_InvitePartnerStaffDialog> createState() =>
      _InvitePartnerStaffDialogState();
}

class _InvitePartnerStaffDialogState
    extends ConsumerState<_InvitePartnerStaffDialog> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _name = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final String email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Indica um email válido.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final String partnerId = ref.read(partnerDataRepositoryProvider).partnerId;
      final String name = _name.text.trim();
      final result =
          await ref.read(cloudFunctionsServiceProvider).invitePartnerStaff(
                partnerId: partnerId,
                email: email,
                name: name.isEmpty ? null : name,
              );
      if (!mounted) return;
      ref.invalidate(staffProvider);
      Navigator.of(context).pop();
      showDialog<void>(
        context: context,
        builder: (BuildContext _) =>
            _StaffLinkDialog(email: email, resetLink: result.resetLink),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Não foi possível criar a conta. Tenta novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Convidar para a equipa',
      description: 'Cria uma conta de acesso a este painel. Vais receber um '
          'link de definição de password para partilhar.',
      confirmLabel: 'Criar conta',
      submitting: _busy,
      errorBanner: _error,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _submit,
      children: <Widget>[
        YaField(
          label: 'Email',
          child: YaInput(controller: _email, placeholder: 'equipa@exemplo.co.mz'),
        ),
        YaField(
          label: 'Nome (opcional)',
          child: YaInput(controller: _name, placeholder: 'Nome completo'),
        ),
      ],
    );
  }
}

class _StaffLinkDialog extends StatelessWidget {
  const _StaffLinkDialog({required this.email, required this.resetLink});

  final String email;
  final String resetLink;

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    return FormDialog(
      title: 'Conta criada',
      description: 'Partilha este link com $email para definir a password. '
          'O link expira; gera outro com "Esqueci a password" se necessário.',
      confirmLabel: 'Copiar link',
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: () {
        Clipboard.setData(ClipboardData(text: resetLink));
        Navigator.of(context).pop();
        partnerToast(context, 'Link copiado');
      },
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(YaSpacing.md),
          decoration: BoxDecoration(
            color: colors.bgSubtle,
            borderRadius: YaRadius.brSm,
            border: Border.all(color: colors.borderSubtle),
          ),
          child: SelectableText(
            resetLink,
            style: YaText.monoSm.copyWith(color: colors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _SettingsForm extends StatelessWidget {
  const _SettingsForm({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PartnerSectionTitle(title: title),
        const SizedBox(height: YaSpacing.lg),
        for (int i = 0; i < children.length; i++) ...<Widget>[
          children[i],
          if (i < children.length - 1) const SizedBox(height: YaSpacing.lg),
        ],
      ],
    );
  }
}

class _SettingsSection {
  const _SettingsSection(this.label, this.icon);

  final String label;
  final IconData icon;
}

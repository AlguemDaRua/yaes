import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/dialogs/form_dialog.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/snack.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_field.dart';
import '../../shared/widgets/forms/ya_input.dart';
import '../../shared/widgets/forms/ya_select.dart';
import '../../shared/widgets/forms/ya_tabs.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../shared/widgets/table/cells.dart';
import '../../shared/widgets/table/data_table.dart';
import '../../shared/widgets/table/row_context_menu.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/types.dart';

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  int _tab = 0;

  Future<void> _setStatus(String uid, String status, String okMessage) async {
    try {
      await ref.read(cloudFunctionsServiceProvider).setUserStatus(
            uid: uid,
            status: status,
          );
      if (!mounted) return;
      ref.invalidate(adminUsersProvider);
      yaSnack(context, okMessage);
    } catch (e) {
      if (!mounted) return;
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  void _copyPhone(String? phone) {
    if (phone == null || phone.isEmpty || phone == '-') {
      yaSnack(context, 'Sem telefone para copiar', variant: StatusVariant.warning);
      return;
    }
    Clipboard.setData(ClipboardData(text: phone));
    yaSnack(context, 'Telefone copiado');
  }

  void _openInvite() {
    showDialog<void>(
      context: context,
      builder: (BuildContext _) => const _InviteManagerDialog(),
    );
  }

  void _openEditRole(AdminUser user) {
    showDialog<void>(
      context: context,
      builder: (BuildContext _) => _EditRoleDialog(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final trips =
        ref.watch(adminTripsProvider).asData?.value ?? const <AdminTrip>[];

    return AsyncView<List<AdminUser>>(
      value: usersAsync,
      onRetry: () => ref.invalidate(adminUsersProvider),
      data: (users) {
        final passengers =
            users.where((user) => user.type == 'passenger').toList();
        final managers = users.where((user) {
          return user.type == 'admin' || user.type == 'support';
        }).toList();
        final drivers = users.where((user) => user.type == 'driver').length;
        final tripsByPassenger = <String, int>{};
        for (final trip in trips) {
          final pid = trip.passengerId;
          if (pid != null) {
            tripsByPassenger[pid] = (tripsByPassenger[pid] ?? 0) + 1;
          }
        }
        final tabs = [
          YaTabItem(label: 'Passageiros', count: passengers.length),
          YaTabItem(label: 'Drivers', count: drivers),
          YaTabItem(label: 'Gestores', count: managers.length),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: S.of(context).adminUsersTitle,
              description: 'Passageiros, drivers e gestores da plataforma',
              actions: [
                if (_tab == 2)
                  YaButton.primary(
                    label: 'Convidar gestor',
                    icon: LucideIcons.userPlus,
                    onPressed: _openInvite,
                  ),
              ],
              tabs: YaTabs(
                items: tabs,
                activeIndex: _tab,
                onChanged: (index) => setState(() => _tab = index),
              ),
            ),
            const SizedBox(height: YaSpacing.xxl),
            switch (_tab) {
              0 => _TabPassengers(
                  rows: passengers,
                  tripsByPassenger: tripsByPassenger,
                  onCopyPhone: (AdminUser u) => _copyPhone(u.phone),
                  onBlock: (String id) =>
                      _setStatus(id, 'suspended', 'Utilizador bloqueado'),
                ),
              1 => const _TabDriversLink(),
              2 => _TabManagers(
                  rows: managers,
                  onEditRole: _openEditRole,
                  onRevoke: (String id) =>
                      _setStatus(id, 'suspended', 'Acesso revogado'),
                ),
              _ => const SizedBox.shrink(),
            },
          ],
        );
      },
    );
  }
}

class _TabPassengers extends StatelessWidget {
  const _TabPassengers({
    required this.rows,
    required this.tripsByPassenger,
    required this.onCopyPhone,
    required this.onBlock,
  });

  final List<AdminUser> rows;
  final Map<String, int> tripsByPassenger;
  final ValueChanged<AdminUser> onCopyPhone;
  final ValueChanged<String> onBlock;

  @override
  Widget build(BuildContext context) {
    return YaDataTable<AdminUser>(
      columns: [
        YaColumn(
          key: 'name',
          label: 'Nome',
          width: 220,
          cellBuilder: (row) => PersonCell(
            name: row.name ?? row.phone ?? row.email ?? row.id,
            subtitle: '',
          ),
        ),
        YaColumn(
          key: 'phone',
          label: 'Telefone',
          width: 150,
          cellBuilder: (row) => IdCell(row.phone ?? '-'),
        ),
        YaColumn(
          key: 'trips',
          label: 'Corridas',
          width: 80,
          align: Alignment.centerRight,
          cellBuilder: (row) => TextCell(
            (tripsByPassenger[row.id] ?? 0).toString(),
            alignEnd: true,
          ),
        ),
        YaColumn(
          key: 'status',
          label: 'Estado',
          width: 110,
          cellBuilder: (row) => StatusBadge.fromMapping(
            StatusMapping(
              row.status == 'suspended'
                  ? StatusVariant.danger
                  : StatusVariant.success,
              row.status == 'suspended' ? 'Bloqueado' : 'Activo',
            ),
          ),
        ),
        YaColumn(
          key: 'more',
          label: '',
          width: 48,
          cellBuilder: (row) => RowContextMenu(
            items: [
              YaMenuItem(
                label: 'Ver detalhe',
                icon: LucideIcons.eye,
                onTap: () => context.go('/admin/users/${row.id}'),
              ),
              YaMenuItem(
                label: 'Copiar telefone',
                icon: LucideIcons.copy,
                onTap: () => onCopyPhone(row),
              ),
              const YaMenuDivider(),
              YaMenuItem(
                label: 'Bloquear',
                icon: LucideIcons.ban,
                destructive: true,
                onTap: () => onBlock(row.id),
              ),
            ],
          ),
        ),
      ],
      rows: rows,
      keyExtractor: (row) => row.id,
      onRowTap: (row) => context.go('/admin/users/${row.id}'),
      emptyIcon: LucideIcons.users,
      emptyTitle: 'Sem passageiros',
      emptyDescription: 'Nenhum passageiro registado.',
    );
  }
}

class _TabDriversLink extends StatelessWidget {
  const _TabDriversLink();

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: YaSpacing.huge),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.users, size: 48, color: colors.textMuted),
            const SizedBox(height: YaSpacing.lg),
            Text(
              'A gestão de drivers está na página dedicada.',
              style: YaText.sm.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: YaSpacing.md),
            YaButton.primary(
              label: 'Ir para Drivers',
              icon: LucideIcons.arrowRight,
              onPressed: () => context.go('/admin/drivers'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabManagers extends StatelessWidget {
  const _TabManagers({
    required this.rows,
    required this.onEditRole,
    required this.onRevoke,
  });

  final List<AdminUser> rows;
  final ValueChanged<AdminUser> onEditRole;
  final ValueChanged<String> onRevoke;

  @override
  Widget build(BuildContext context) {
    return YaDataTable<AdminUser>(
      columns: [
        YaColumn(
          key: 'email',
          label: 'Email',
          width: 240,
          cellBuilder: (row) => PersonCell(
            name: row.email ?? row.name ?? row.id,
            subtitle: row.name ?? '',
          ),
        ),
        YaColumn(
          key: 'role',
          label: 'Role',
          width: 140,
          cellBuilder: (row) => StatusBadge.fromMapping(
            StatusMapping(
              row.type == 'admin' ? StatusVariant.brand : StatusVariant.neutral,
              row.type == 'admin' ? 'Admin' : 'Suporte',
            ),
          ),
        ),
        YaColumn(
          key: 'status',
          label: 'Estado',
          width: 120,
          cellBuilder: (row) => StatusBadge.fromMapping(
            StatusMapping(
              row.status == 'suspended'
                  ? StatusVariant.danger
                  : StatusVariant.success,
              row.status == 'suspended' ? 'Suspenso' : 'Activo',
            ),
          ),
        ),
        YaColumn(
          key: 'created',
          label: 'Criado',
          width: 140,
          cellBuilder: (row) => WhenCell(
            '${row.createdAt.day.toString().padLeft(2, '0')}/'
            '${row.createdAt.month.toString().padLeft(2, '0')}/'
            '${row.createdAt.year}',
          ),
        ),
        YaColumn(
          key: 'more',
          label: '',
          width: 48,
          cellBuilder: (row) => RowContextMenu(
            items: [
              YaMenuItem(
                label: 'Editar role',
                icon: LucideIcons.pencil,
                onTap: () => onEditRole(row),
              ),
              const YaMenuDivider(),
              YaMenuItem(
                label: 'Revogar acesso',
                icon: LucideIcons.userX,
                destructive: true,
                onTap: () => onRevoke(row.id),
              ),
            ],
          ),
        ),
      ],
      rows: rows,
      keyExtractor: (row) => row.id,
      emptyIcon: LucideIcons.shield,
      emptyTitle: 'Sem gestores',
      emptyDescription: 'Convida o primeiro gestor para a plataforma.',
    );
  }
}

class _InviteManagerDialog extends ConsumerStatefulWidget {
  const _InviteManagerDialog();

  @override
  ConsumerState<_InviteManagerDialog> createState() =>
      _InviteManagerDialogState();
}

class _InviteManagerDialogState extends ConsumerState<_InviteManagerDialog> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _name = TextEditingController();
  String _role = 'support';
  bool _busy = false;

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
      yaSnack(context, 'Indica um email válido.', variant: StatusVariant.danger);
      return;
    }
    setState(() => _busy = true);
    try {
      final String name = _name.text.trim();
      final result = await ref.read(cloudFunctionsServiceProvider).inviteManager(
            email: email,
            role: _role,
            name: name.isEmpty ? null : name,
          );
      if (!mounted) return;
      ref.invalidate(adminUsersProvider);
      Navigator.of(context).pop();
      showDialog<void>(
        context: context,
        builder: (BuildContext _) =>
            _InviteLinkDialog(email: email, resetLink: result.resetLink),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Convidar gestor',
      description: 'Cria uma conta de acesso ao painel. Vais receber um link '
          'de definição de password para partilhar.',
      confirmLabel: 'Criar conta',
      submitting: _busy,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _submit,
      children: <Widget>[
        YaField(
          label: 'Email',
          child: YaInput(
            controller: _email,
            placeholder: 'gestor@ya.mz',
          ),
        ),
        YaField(
          label: 'Nome (opcional)',
          child: YaInput(
            controller: _name,
            placeholder: 'Nome do gestor',
          ),
        ),
        YaField(
          label: 'Role',
          child: YaSelect<String>(
            width: 320,
            items: const <YaSelectItem<String>>[
              YaSelectItem<String>(value: 'support', label: 'Suporte'),
              YaSelectItem<String>(value: 'admin', label: 'Admin'),
            ],
            value: _role,
            onChanged: (String value) => setState(() => _role = value),
          ),
        ),
      ],
    );
  }
}

class _InviteLinkDialog extends StatelessWidget {
  const _InviteLinkDialog({required this.email, required this.resetLink});

  final String email;
  final String resetLink;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return FormDialog(
      title: 'Conta criada',
      description: 'Partilha este link com $email para definir a password. '
          'O link expira; gera outro com "Esqueci a password" se necessário.',
      confirmLabel: 'Copiar link',
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: () {
        Clipboard.setData(ClipboardData(text: resetLink));
        Navigator.of(context).pop();
        yaSnack(context, 'Link copiado');
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

class _EditRoleDialog extends ConsumerStatefulWidget {
  const _EditRoleDialog({required this.user});

  final AdminUser user;

  @override
  ConsumerState<_EditRoleDialog> createState() => _EditRoleDialogState();
}

class _EditRoleDialogState extends ConsumerState<_EditRoleDialog> {
  late String _role = widget.user.type == 'admin' ? 'admin' : 'support';
  bool _busy = false;

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(cloudFunctionsServiceProvider).setUserRole(
            uid: widget.user.id,
            role: _role,
          );
      if (!mounted) return;
      ref.invalidate(adminUsersProvider);
      Navigator.of(context).pop();
      yaSnack(context, 'Role actualizado');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String who =
        widget.user.email ?? widget.user.name ?? widget.user.id;
    return FormDialog(
      title: 'Editar role',
      description: 'Altera o nível de acesso de $who.',
      confirmLabel: 'Guardar',
      submitting: _busy,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _submit,
      children: <Widget>[
        YaField(
          label: 'Role',
          child: YaSelect<String>(
            width: 320,
            items: const <YaSelectItem<String>>[
              YaSelectItem<String>(value: 'support', label: 'Suporte'),
              YaSelectItem<String>(value: 'admin', label: 'Admin'),
            ],
            value: _role,
            onChanged: (String value) => setState(() => _role = value),
          ),
        ),
      ],
    );
  }
}

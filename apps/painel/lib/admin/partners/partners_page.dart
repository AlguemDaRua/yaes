import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/dialogs/form_dialog.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/snack.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/filters/filter_bar.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_field.dart';
import '../../shared/widgets/forms/ya_input.dart';
import '../../shared/widgets/forms/ya_switch.dart';
import '../../shared/widgets/kpi/kpi_card.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../shared/widgets/table/cells.dart';
import '../../shared/widgets/table/data_table.dart';
import '../../shared/widgets/table/row_context_menu.dart';
import '../../shared/utils/csv_export.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/types.dart';

class PartnersPage extends ConsumerStatefulWidget {
  const PartnersPage({super.key});

  @override
  ConsumerState<PartnersPage> createState() => _PartnersPageState();
}

class _PartnersPageState extends ConsumerState<PartnersPage> {
  String _activeChip = 'all';
  bool _busy = false;

  void _openCreate() {
    showDialog<void>(
      context: context,
      builder: (BuildContext _) => const _CreatePartnerDialog(),
    );
  }

  Future<void> _run(Future<void> Function() action, String okMessage) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ref.invalidate(adminPartnersProvider);
      yaSnack(context, okMessage);
    } catch (e) {
      if (!mounted) return;
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _approve(String id) => _run(
        () => ref.read(cloudFunctionsServiceProvider).approvePartner(id),
        'Partner aprovado',
      );

  void _reactivate(String id) => _run(
        () => ref.read(cloudFunctionsServiceProvider).approvePartner(id),
        'Partner reactivado',
      );

  void _suspend(String id) => _run(
        () => ref
            .read(cloudFunctionsServiceProvider)
            .suspendPartner(partnerId: id),
        'Partner suspenso',
      );

  List<_Partner> _rowsFrom(
    List<AdminPartner> partners,
    List<AdminCommission> commissions,
    List<AdminTrip> trips,
  ) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    return partners.map((partner) {
      final commission = commissions
              .where((c) => c.partnerId == partner.id)
              .map((c) => (c.rate * 100).round())
              .firstOrNull ??
          12;
      final revenue = trips
          .where(
            (t) =>
                t.partnerId == partner.id &&
                t.status == 'completed' &&
                !t.createdAt.isBefore(monthStart),
          )
          .fold<int>(0, (sum, t) => sum + t.amountMtn);
      return _Partner.fromAdmin(partner, commission, revenue);
    }).toList();
  }

  List<FilterChipSpec> _chipsFor(List<_Partner> rows) {
    int count(String status) =>
        rows.where((row) => row.status == status).length;
    return [
      FilterChipSpec(id: 'all', label: 'Todos', count: rows.length),
      FilterChipSpec(
        id: 'active',
        label: 'Activos',
        count: count('active'),
        variant: StatusVariant.success,
      ),
      FilterChipSpec(
        id: 'pending',
        label: 'Pendentes',
        count: count('pending'),
        variant: StatusVariant.warning,
      ),
      FilterChipSpec(
        id: 'suspended',
        label: 'Suspensos',
        count: count('suspended'),
        variant: StatusVariant.danger,
      ),
    ];
  }

  List<_Partner> _filteredRows(List<_Partner> rows) {
    if (_activeChip == 'all') return rows;
    return rows.where((row) => row.status == _activeChip).toList();
  }

  void _export(List<_Partner> rows) {
    if (rows.isEmpty) {
      yaSnack(context, 'Nada para exportar', variant: StatusVariant.warning);
      return;
    }
    final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
    downloadCsv('partners-$stamp.csv', <List<Object?>>[
      <Object?>[
        'id',
        'nome',
        'nuit',
        'cidade',
        'drivers',
        'veiculos',
        'estado',
      ],
      for (final p in rows)
        <Object?>[
          p.id,
          p.name,
          p.nuit,
          p.city,
          p.driversCount,
          p.vehiclesCount,
          p.status,
        ],
    ]);
    yaSnack(context, 'CSV exportado');
  }

  List<Object> _menuFor(_Partner row) {
    return [
      YaMenuItem(
        label: 'Ver detalhe',
        icon: LucideIcons.eye,
        onTap: () => context.go('/admin/partners/${row.id}'),
      ),
      if (row.status == 'pending')
        YaMenuItem(
          label: 'Aprovar',
          icon: LucideIcons.check,
          onTap: () => _approve(row.id),
        ),
      if (row.status == 'active')
        YaMenuItem(
          label: 'Editar comissão',
          icon: LucideIcons.percent,
          onTap: () => context.go('/admin/partners/${row.id}'),
        ),
      if (row.status == 'active') ...[
        const YaMenuDivider(),
        YaMenuItem(
          label: 'Suspender',
          icon: LucideIcons.ban,
          destructive: true,
          onTap: () => _suspend(row.id),
        ),
      ],
      if (row.status == 'suspended')
        YaMenuItem(
          label: 'Reactivar',
          icon: LucideIcons.circleCheck,
          onTap: () => _reactivate(row.id),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final moneyFormat = NumberFormat('#,##0', 'pt_PT');
    final partnersAsync = ref.watch(adminPartnersProvider);
    final commissions =
        ref.watch(adminCommissionsProvider).asData?.value ?? const [];
    final trips = ref.watch(adminTripsProvider).asData?.value ?? const [];

    return AsyncView<List<AdminPartner>>(
      value: partnersAsync,
      onRetry: () => ref.invalidate(adminPartnersProvider),
      data: (partners) {
        final rows = _rowsFrom(partners, commissions, trips);
        final filtered = _filteredRows(rows);
        final active = rows.where((row) => row.status == 'active').length;
        final pending = rows.where((row) => row.status == 'pending').length;
        final suspended = rows.where((row) => row.status == 'suspended').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: S.of(context).adminPartnersTitle,
              description: 'Empresas que operam frotas em nome da YA',
              actions: [
                YaButton.secondary(
                  label: 'Exportar',
                  icon: LucideIcons.download,
                  onPressed: () => _export(filtered),
                ),
                YaButton.primary(
                  label: 'Novo partner',
                  icon: LucideIcons.plus,
                  onPressed: _openCreate,
                ),
              ],
            ),
            const SizedBox(height: YaSpacing.xxl),
            KpiRow(
              children: [
                KpiCard(
                  label: 'Total',
                  value: rows.length.toString(),
                  icon: LucideIcons.building2,
                ),
                KpiCard(
                  label: 'Activos',
                  value: active.toString(),
                  icon: LucideIcons.circleCheck,
                ),
                KpiCard(
                  label: 'Pendentes',
                  value: pending.toString(),
                  icon: LucideIcons.clock,
                ),
                KpiCard(
                  label: 'Suspensos',
                  value: suspended.toString(),
                  icon: LucideIcons.ban,
                ),
              ],
            ),
            const SizedBox(height: YaSpacing.xxl),
            FilterBar(
              chips: _chipsFor(rows),
              activeChipId: _activeChip,
              onChipSelected: (id) => setState(() => _activeChip = id),
              searchPlaceholder: 'Pesquisar por nome, NUIT ou cidade...',
            ),
            const SizedBox(height: YaSpacing.lg),
            YaDataTable<_Partner>(
              columns: [
                YaColumn(
                  key: 'name',
                  label: 'Empresa',
                  width: 240,
                  cellBuilder: (row) => PersonCell(
                    name: row.name,
                    subtitle: row.city,
                  ),
                ),
                YaColumn(
                  key: 'nuit',
                  label: 'NUIT',
                  width: 130,
                  cellBuilder: (row) => IdCell(row.nuit),
                ),
                YaColumn(
                  key: 'drivers',
                  label: 'Drivers',
                  width: 80,
                  align: Alignment.centerRight,
                  cellBuilder: (row) => TextCell(
                    row.driversCount.toString(),
                    alignEnd: true,
                  ),
                ),
                YaColumn(
                  key: 'vehicles',
                  label: 'Veículos',
                  width: 90,
                  align: Alignment.centerRight,
                  cellBuilder: (row) => TextCell(
                    row.vehiclesCount.toString(),
                    alignEnd: true,
                  ),
                ),
                YaColumn(
                  key: 'revenue',
                  label: 'Receita (mês)',
                  width: 140,
                  align: Alignment.centerRight,
                  cellBuilder: (row) => MoneyCell(
                    amount: row.revenue == 0
                        ? '-'
                        : moneyFormat.format(row.revenue),
                  ),
                ),
                YaColumn(
                  key: 'commission',
                  label: 'Comissão',
                  width: 90,
                  cellBuilder: (row) => TextCell('${row.commission}%'),
                ),
                YaColumn(
                  key: 'status',
                  label: 'Estado',
                  width: 160,
                  cellBuilder: (row) => StatusBadge.fromMapping(
                    YaStatus.fromPartnerStatus(row.status),
                  ),
                ),
                YaColumn(
                  key: 'more',
                  label: '',
                  width: 48,
                  cellBuilder: (row) => RowContextMenu(items: _menuFor(row)),
                ),
              ],
              rows: filtered,
              keyExtractor: (row) => row.id,
              onRowTap: (row) => context.go('/admin/partners/${row.id}'),
              emptyIcon: LucideIcons.building2,
              emptyTitle: 'Sem partners',
              emptyDescription: 'Cria o primeiro partner para começares.',
              footer: YaTablePagination(
                currentPage: 1,
                totalPages: 1,
                onPageChange: (_) {},
                summary: 'A mostrar ${filtered.length} de ${rows.length}',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Partner {
  const _Partner(
    this.id,
    this.name,
    this.nuit,
    this.city,
    this.driversCount,
    this.vehiclesCount,
    this.revenue,
    this.commission,
    this.status,
  );

  final String id;
  final String name;
  final String nuit;
  final String city;
  final int driversCount;
  final int vehiclesCount;
  final int revenue;
  final int commission;
  final String status;

  factory _Partner.fromAdmin(
    AdminPartner partner,
    int commission,
    int revenue,
  ) {
    return _Partner(
      partner.id,
      partner.name,
      partner.nuit ?? '-',
      partner.city,
      partner.driversCount,
      partner.vehiclesCount,
      revenue,
      commission,
      partner.status,
    );
  }
}

class _CreatePartnerDialog extends ConsumerStatefulWidget {
  const _CreatePartnerDialog();

  @override
  ConsumerState<_CreatePartnerDialog> createState() =>
      _CreatePartnerDialogState();
}

class _CreatePartnerDialogState extends ConsumerState<_CreatePartnerDialog> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _nuit = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _ownerEmail = TextEditingController();
  final TextEditingController _ownerName = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _commissionFloat =
      TextEditingController(text: '400');
  bool _requiresWalletSettlement = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _nuit.dispose();
    _city.dispose();
    _ownerEmail.dispose();
    _ownerName.dispose();
    _phone.dispose();
    _commissionFloat.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final String name = _name.text.trim();
    final String nuit = _nuit.text.trim();
    final String city = _city.text.trim();
    final String ownerEmail = _ownerEmail.text.trim();
    if (name.isEmpty || nuit.isEmpty || city.isEmpty) {
      yaSnack(
        context,
        'Nome, NUIT e cidade são obrigatórios.',
        variant: StatusVariant.danger,
      );
      return;
    }
    if (!ownerEmail.contains('@')) {
      yaSnack(
        context,
        'Indica o email do dono (será o login dele no painel).',
        variant: StatusVariant.danger,
      );
      return;
    }
    final int? commissionFloatMtn = int.tryParse(_commissionFloat.text.trim());
    if (_requiresWalletSettlement &&
        (commissionFloatMtn == null || commissionFloatMtn < 0)) {
      yaSnack(
        context,
        'Float de comissão inválido.',
        variant: StatusVariant.danger,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final result =
          await ref.read(cloudFunctionsServiceProvider).createPartnerWithOwner(
                name: name,
                nuit: nuit,
                city: city,
                ownerEmail: ownerEmail,
                ownerName: _ownerName.text.trim().isEmpty
                    ? null
                    : _ownerName.text.trim(),
                phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
                requiresWalletSettlement: _requiresWalletSettlement,
                commissionFloatMtn:
                    _requiresWalletSettlement ? commissionFloatMtn : null,
              );
      if (!mounted) return;
      ref.invalidate(adminPartnersProvider);
      Navigator.of(context).pop();
      showDialog<void>(
        context: context,
        builder: (BuildContext _) => _OwnerLinkDialog(
          email: ownerEmail,
          resetLink: result.resetLink,
        ),
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
      title: 'Novo partner',
      description: 'Cria a empresa e a conta de acesso do dono ao painel. '
          'Recebes um link para ele definir a password. Nasce pendente de '
          'aprovação.',
      confirmLabel: 'Criar partner',
      submitting: _busy,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _submit,
      children: [
        YaField(
          label: 'Nome da empresa',
          child: YaInput(controller: _name, placeholder: 'Maputo Executive'),
        ),
        YaField(
          label: 'NUIT',
          child: YaInput(controller: _nuit, placeholder: '400 123 456'),
        ),
        YaField(
          label: 'Cidade',
          child: YaInput(controller: _city, placeholder: 'Maputo'),
        ),
        YaField(
          label: 'Email do dono (login do painel)',
          child: YaInput(
            controller: _ownerEmail,
            placeholder: 'dono@empresa.co.mz',
          ),
        ),
        YaField(
          label: 'Nome do dono (opcional)',
          child: YaInput(controller: _ownerName, placeholder: 'Nome do gestor'),
        ),
        YaField(
          label: 'Telefone (opcional)',
          child: YaInput(controller: _phone, placeholder: '+258 84 000 0000'),
        ),
        YaSwitch(
          label: 'Frota YA Direct',
          subtitle: 'Motoristas sem parceiro próprio (ex.: Nampula) — a '
              'comissão é debitada de uma carteira em vez de paga por payout.',
          value: _requiresWalletSettlement,
          onChanged: (bool value) =>
              setState(() => _requiresWalletSettlement = value),
        ),
        if (_requiresWalletSettlement)
          YaField(
            label: 'Float de comissão (MTn)',
            child: YaInput(
              controller: _commissionFloat,
              placeholder: '400',
              keyboardType: TextInputType.number,
            ),
          ),
      ],
    );
  }
}

class _OwnerLinkDialog extends StatelessWidget {
  const _OwnerLinkDialog({required this.email, required this.resetLink});

  final String email;
  final String resetLink;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return FormDialog(
      title: 'Partner criado',
      description: 'Partilha este link com $email para definir a password. '
          'Depois entra no painel com esse email. O partner está pendente — '
          'aprova-o na lista.',
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

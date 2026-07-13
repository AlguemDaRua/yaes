import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/dialogs/confirm_dialog.dart';
import '../../shared/widgets/dialogs/form_dialog.dart';
import '../../shared/widgets/feedback/empty_state.dart';
import '../../shared/widgets/feedback/info_banner.dart';
import '../../shared/widgets/feedback/snack.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/feedback/timeline.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_field.dart';
import '../../shared/widgets/forms/ya_input.dart';
import '../../shared/widgets/forms/ya_tabs.dart';
import '../../shared/widgets/forms/ya_textarea.dart';
import '../../shared/widgets/kpi/kpi_card.dart';
import '../../shared/widgets/shell/detail_header.dart';
import '../../shared/widgets/table/cells.dart';
import '../../shared/widgets/table/data_table.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/types.dart';

class PartnerDetailPage extends ConsumerStatefulWidget {
  const PartnerDetailPage({required this.id, super.key});
  final String id;

  @override
  ConsumerState<PartnerDetailPage> createState() => _PartnerDetailPageState();
}

class _PartnerDetailPageState extends ConsumerState<PartnerDetailPage> {
  int _tab = 0;
  bool _showEditCommission = false;
  bool _showSuspend = false;
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String okMessage) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ref.invalidate(adminPartnerByIdProvider(widget.id));
      ref.invalidate(adminPartnersProvider);
      yaSnack(context, okMessage);
    } catch (e) {
      if (!mounted) return;
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve() => _run(
        () => ref.read(cloudFunctionsServiceProvider).approvePartner(widget.id),
        'Partner aprovado',
      );

  Future<void> _reactivate() => _run(
        () => ref.read(cloudFunctionsServiceProvider).approvePartner(widget.id),
        'Partner reactivado',
      );

  // Nota: cada partner tem exactamente uma frota — não há tab "Frotas".
  // A frota associada é acessível via /admin/fleets/{id}.
  static const _tabs = [
    YaTabItem(label: 'Visão geral'),
    YaTabItem(label: 'Drivers'),
    YaTabItem(label: 'Conformidade'),
    YaTabItem(label: 'Financeiro'),
    YaTabItem(label: 'Histórico'),
  ];

  @override
  Widget build(BuildContext context) {
    final partnerAsync = ref.watch(adminPartnerByIdProvider(widget.id));
    final commissions =
        ref.watch(adminCommissionsProvider).asData?.value ?? const [];
    final trips = ref.watch(adminTripsProvider).asData?.value ?? const [];

    return AsyncView<AdminPartner?>(
      value: partnerAsync,
      onRetry: () => ref.invalidate(adminPartnerByIdProvider(widget.id)),
      data: (partner) {
        if (partner == null) {
          return const EmptyState(
            icon: LucideIcons.building2,
            title: 'Partner não encontrado',
            description: 'Este partner pode ter sido removido.',
          );
        }
        final p = _PartnerData.fromAdmin(partner, commissions, trips);
        return _buildDetail(context, p);
      },
    );
  }

  Widget _buildDetail(BuildContext context, _PartnerData p) {
    final status = YaStatus.fromPartnerStatus(p.status);
    final isSuspended = p.status == 'suspended';

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DetailHeader(
              name: p.name,
              statusBadge: StatusBadge.fromMapping(status),
              subtitle: 'NUIT ${p.nuit} · ${p.city}',
              meta: 'Criado por ${p.createdBy} · ${p.createdAgo}',
              banner: isSuspended
                  ? const InfoBanner(
                      message: 'Partner suspenso — drivers offline.',
                      variant: StatusVariant.danger,
                    )
                  : null,
              breadcrumb: _Breadcrumb(
                onBack: () => context.go('/admin/partners'),
                name: p.name,
              ),
              actions: [
                YaButton.secondary(
                  label: 'Editar comissão',
                  icon: LucideIcons.percent,
                  onPressed: () => setState(() => _showEditCommission = true),
                ),
                if (p.status == 'pending')
                  YaButton.primary(
                    label: 'Aprovar',
                    icon: LucideIcons.check,
                    onPressed: _busy ? null : () => _approve(),
                  ),
                if (p.status == 'active')
                  YaButton.destructive(
                    label: 'Suspender',
                    icon: LucideIcons.ban,
                    onPressed: () => setState(() => _showSuspend = true),
                  ),
                if (p.status == 'suspended')
                  YaButton.primary(
                    label: 'Reactivar',
                    icon: LucideIcons.rotateCcw,
                    onPressed: _busy ? null : () => _reactivate(),
                  ),
              ],
              tabs: YaTabs(
                items: _tabs,
                activeIndex: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
            const SizedBox(height: YaSpacing.xxl),
            _tabContent(context, p),
          ],
        ),
        if (_showEditCommission)
          _EditCommissionDialog(
            partnerId: widget.id,
            partnerName: p.name,
            currentCommission: p.commission,
            onClose: () => setState(() => _showEditCommission = false),
          ),
        if (_showSuspend)
          _SuspendDialog(
            partnerId: widget.id,
            partnerName: p.name,
            onClose: () => setState(() => _showSuspend = false),
          ),
      ],
    );
  }

  Widget _tabContent(BuildContext context, _PartnerData p) {
    return switch (_tab) {
      0 => _TabVisaoGeral(
          p: p,
          onEditCommission: () => setState(() => _showEditCommission = true),
        ),
      1 => _TabDrivers(partnerId: widget.id),
      2 => _TabConformidade(partnerId: widget.id),
      3 => _TabFinanceiro(partnerId: widget.id),
      4 => _TabHistorico(partnerId: widget.id),
      _ => const SizedBox.shrink(),
    };
  }
}

class _TabVisaoGeral extends StatelessWidget {
  const _TabVisaoGeral({required this.p, required this.onEditCommission});
  final _PartnerData p;
  final VoidCallback onEditCommission;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KpiRow(
          children: [
            KpiCard(
              label: 'Drivers',
              value: p.driversCount.toString(),
              icon: LucideIcons.user,
            ),
            KpiCard(
              label: 'Veículos',
              value: p.vehiclesCount.toString(),
              icon: LucideIcons.car,
            ),
            KpiCard(
              label: 'Corridas (mês)',
              value: p.tripsMonth.toString(),
              icon: LucideIcons.route,
            ),
            KpiCard(
              label: 'Receita (mês)',
              value: p.revenueMonth,
              icon: LucideIcons.trendingUp,
            ),
          ],
        ),
        const SizedBox(height: YaSpacing.xxl),
        _CommissionCard(commission: p.commission, onEdit: onEditCommission),
      ],
    );
  }
}

class _CommissionCard extends StatelessWidget {
  const _CommissionCard({required this.commission, required this.onEdit});
  final int commission;
  final VoidCallback onEdit;

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth.isFinite && constraints.maxWidth < 360;
          final summary = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TAXA DE COMISSÃO',
                style: YaText.eyebrowKpi.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$commission%',
                style: YaText.xxxl.copyWith(color: colors.textPrimary),
              ),
              Text(
                'padrão da plataforma',
                style: YaText.sans(size: 12, height: 16)
                    .copyWith(color: colors.textMuted),
              ),
            ],
          );
          final action = YaButton.secondary(
            label: 'Editar',
            icon: LucideIcons.pencil,
            onPressed: onEdit,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                summary,
                const SizedBox(height: YaSpacing.md),
                action,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: summary),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _TabDrivers extends ConsumerWidget {
  const _TabDrivers({required this.partnerId});
  final String partnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drivers =
        ref.watch(adminDriversProvider).asData?.value ?? const <AdminDriver>[];
    final rows = drivers
        .where((d) => d.partnerId == partnerId)
        .map(
          (d) => _DriverRow(
            d.name,
            d.status,
            d.online,
            d.vehicleId ?? '—',
            d.rating,
            d.tripsCount,
            0,
          ),
        )
        .toList();
    return YaDataTable<_DriverRow>(
      columns: [
        YaColumn(
          key: 'driver',
          label: 'Driver',
          width: 240,
          cellBuilder: (r) => PersonCell(name: r.name, subtitle: ''),
        ),
        YaColumn(
          key: 'status',
          label: 'Estado',
          width: 130,
          cellBuilder: (r) => StatusBadge.fromMapping(
            YaStatus.fromDriverStatus(r.status, online: r.online),
          ),
        ),
        YaColumn(
          key: 'vehicle',
          label: 'Veículo',
          width: 110,
          cellBuilder: (r) => TextCell(r.vehicle, muted: r.vehicle == '—'),
        ),
        YaColumn(
          key: 'rating',
          label: 'Rating',
          width: 100,
          align: Alignment.centerRight,
          cellBuilder: (r) => TextCell(
            r.rating > 0 ? '${r.rating} ★' : '—',
            alignEnd: true,
          ),
        ),
        YaColumn(
          key: 'trips',
          label: 'Corridas',
          width: 80,
          align: Alignment.centerRight,
          cellBuilder: (r) => TextCell(r.trips.toString(), alignEnd: true),
        ),
      ],
      rows: rows,
      keyExtractor: (r) => r.name,
      emptyIcon: LucideIcons.user,
      emptyTitle: 'Sem drivers',
      emptyDescription: 'Este partner ainda não convidou drivers.',
    );
  }
}

class _TabConformidade extends ConsumerWidget {
  const _TabConformidade({required this.partnerId});
  final String partnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = (ref.watch(adminDocumentsProvider).asData?.value ??
            const <AdminDocument>[])
        .where((d) => d.ownerType == 'partner' && d.ownerId == partnerId)
        .toList();
    return YaDataTable<AdminDocument>(
      density: YaTableDensity.compact,
      columns: [
        YaColumn(
          key: 'type',
          label: 'Documento',
          cellBuilder: (d) => TextCell(d.type),
        ),
        YaColumn(
          key: 'status',
          label: 'Estado',
          width: 130,
          cellBuilder: (d) => StatusBadge.fromMapping(
            YaStatus.fromDocStatus(d.status),
          ),
        ),
        YaColumn(
          key: 'expires',
          label: 'Validade',
          width: 120,
          cellBuilder: (d) => TextCell(
            d.expiresAt == null
                ? '—'
                : DateFormat('dd/MM/yyyy').format(d.expiresAt!),
            muted: d.expiresAt == null,
          ),
        ),
      ],
      rows: docs,
      keyExtractor: (d) => d.id,
      emptyIcon: LucideIcons.fileText,
      emptyTitle: 'Sem documentos',
      emptyDescription: 'Este partner ainda não submeteu documentos.',
    );
  }
}

class _TabFinanceiro extends ConsumerWidget {
  const _TabFinanceiro({required this.partnerId});
  final String partnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payouts = (ref.watch(adminPayoutsProvider).asData?.value ??
            const <AdminPayout>[])
        .where((p) => p.partnerId == partnerId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return YaDataTable<AdminPayout>(
      density: YaTableDensity.compact,
      columns: [
        YaColumn(
          key: 'label',
          label: 'Pagamento',
          cellBuilder: (p) => TextCell(p.label ?? p.reference ?? p.id),
        ),
        YaColumn(
          key: 'method',
          label: 'Método',
          width: 120,
          cellBuilder: (p) => TextCell(p.method, muted: true),
        ),
        YaColumn(
          key: 'amount',
          label: 'Valor',
          width: 120,
          align: Alignment.centerRight,
          cellBuilder: (p) => MoneyCell(
            amount: NumberFormat('#,##0', 'pt_PT').format(p.amountMtn),
          ),
        ),
        YaColumn(
          key: 'status',
          label: 'Estado',
          width: 120,
          cellBuilder: (p) => StatusBadge.fromMapping(
            YaStatus.fromTransactionStatus(p.status),
          ),
        ),
        YaColumn(
          key: 'when',
          label: 'Data',
          width: 110,
          cellBuilder: (p) =>
              WhenCell(DateFormat('dd/MM/yyyy').format(p.createdAt)),
        ),
      ],
      rows: payouts,
      keyExtractor: (p) => p.id,
      emptyIcon: LucideIcons.banknote,
      emptyTitle: 'Sem pagamentos',
      emptyDescription: 'Ainda não há payouts registados para este partner.',
    );
  }
}

class _TabHistorico extends ConsumerWidget {
  const _TabHistorico({required this.partnerId});
  final String partnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(adminAuditLogsProvider).asData?.value ??
        const <AdminAuditLog>[];
    final events = logs
        .where((l) => l.targetPath?.contains(partnerId) ?? false)
        .map(
          (l) => TimelineEvent(
            label: '${l.action} · por ${l.actorUid}',
            timestamp: DateFormat('dd/MM/yyyy HH:mm').format(l.createdAt),
            variant: StatusVariant.info,
          ),
        )
        .toList();
    if (events.isEmpty) {
      return const EmptyState(
        icon: LucideIcons.history,
        title: 'Sem histórico',
        description:
            'As ações administrativas sobre este partner aparecem aqui.',
      );
    }
    return Timeline(events: events);
  }
}

class _EditCommissionDialog extends ConsumerStatefulWidget {
  const _EditCommissionDialog({
    required this.partnerId,
    required this.partnerName,
    required this.currentCommission,
    required this.onClose,
  });
  final String partnerId;
  final String partnerName;
  final int currentCommission;
  final VoidCallback onClose;

  @override
  ConsumerState<_EditCommissionDialog> createState() =>
      _EditCommissionDialogState();
}

class _EditCommissionDialogState extends ConsumerState<_EditCommissionDialog> {
  final TextEditingController _rate = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _rate.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final double? pct = double.tryParse(_rate.text.trim().replaceAll(',', '.'));
    if (pct == null || pct < 0 || pct > 100) {
      yaSnack(context, 'Taxa inválida (0–100%)', variant: StatusVariant.danger);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(cloudFunctionsServiceProvider).setCommission(
            partnerId: widget.partnerId,
            rate: pct / 100,
          );
      if (!mounted) return;
      ref.invalidate(adminPartnerByIdProvider(widget.partnerId));
      ref.invalidate(adminCommissionsProvider);
      widget.onClose();
      yaSnack(context, 'Comissão actualizada');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Editar comissão de ${widget.partnerName}',
      description:
          'Esta alteração entra em vigor imediatamente e fica registada no audit log.',
      confirmLabel: 'Alterar comissão',
      submitting: _busy,
      onCancel: widget.onClose,
      onConfirm: _submit,
      children: [
        YaField(
          label: 'Nova taxa (%)',
          child: YaInput(
            controller: _rate,
            placeholder: widget.currentCommission.toString(),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }
}

class _SuspendDialog extends ConsumerStatefulWidget {
  const _SuspendDialog({
    required this.partnerId,
    required this.partnerName,
    required this.onClose,
  });
  final String partnerId;
  final String partnerName;
  final VoidCallback onClose;

  @override
  ConsumerState<_SuspendDialog> createState() => _SuspendDialogState();
}

class _SuspendDialogState extends ConsumerState<_SuspendDialog> {
  final TextEditingController _reason = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final String reason = _reason.text.trim();
      await ref.read(cloudFunctionsServiceProvider).suspendPartner(
            partnerId: widget.partnerId,
            reason: reason.isEmpty ? null : reason,
          );
      if (!mounted) return;
      ref.invalidate(adminPartnerByIdProvider(widget.partnerId));
      ref.invalidate(adminPartnersProvider);
      widget.onClose();
      yaSnack(context, 'Partner suspenso');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmDialog(
      title: 'Suspender ${widget.partnerName}?',
      description:
          'Todos os drivers ficam imediatamente offline. Corridas em curso terminam normalmente.',
      confirmLabel: _busy ? 'A suspender…' : 'Suspender',
      onCancel: _busy ? null : widget.onClose,
      onConfirm: _busy ? null : _submit,
      body: YaField(
        label: 'Motivo da suspensão',
        hint: 'Opcional',
        child: YaTextarea(
          controller: _reason,
          placeholder: 'Ex: Documentos expirados',
        ),
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.onBack, required this.name});
  final VoidCallback onBack;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onBack,
          child: Text(
            'Partners',
            style: YaText.sm.copyWith(color: colors.textMuted),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '›',
            style: YaText.sm.copyWith(color: colors.textMuted),
          ),
        ),
        Text(
          name,
          style: YaText.sm.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _PartnerData {
  const _PartnerData({
    required this.id,
    required this.name,
    required this.nuit,
    required this.city,
    required this.status,
    required this.commission,
    required this.createdBy,
    required this.createdAgo,
    required this.driversCount,
    required this.vehiclesCount,
    required this.tripsMonth,
    required this.revenueMonth,
  });
  final String id,
      name,
      nuit,
      city,
      status,
      createdBy,
      createdAgo,
      revenueMonth;
  final int commission, driversCount, vehiclesCount, tripsMonth;

  factory _PartnerData.fromAdmin(
    AdminPartner partner,
    List<AdminCommission> commissions,
    List<AdminTrip> trips,
  ) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final monthTrips = trips
        .where(
          (t) =>
              t.partnerId == partner.id &&
              t.status == 'completed' &&
              !t.createdAt.isBefore(monthStart),
        )
        .toList();
    final revenue = monthTrips.fold<int>(0, (sum, t) => sum + t.amountMtn);
    final commission = commissions
        .where((c) => c.partnerId == partner.id)
        .map((c) => (c.rate * 100).round())
        .firstOrNull;
    return _PartnerData(
      id: partner.id,
      name: partner.name,
      nuit: partner.nuit ?? '-',
      city: partner.city,
      status: partner.status,
      commission: commission ?? 12,
      createdBy: 'painel',
      createdAgo: DateFormat('dd/MM/yyyy').format(partner.createdAt),
      driversCount: partner.driversCount,
      vehiclesCount: partner.vehiclesCount,
      tripsMonth: monthTrips.length,
      revenueMonth: '${NumberFormat('#,##0', 'pt_PT').format(revenue)} MTn',
    );
  }
}

class _DriverRow {
  const _DriverRow(
    this.name,
    this.status,
    this.online,
    this.vehicle,
    this.rating,
    this.trips,
    this.earned,
  );
  final String name, status, vehicle;
  final bool online;
  final double rating;
  final int trips, earned;
}

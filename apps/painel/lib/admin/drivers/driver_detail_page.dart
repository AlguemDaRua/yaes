import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../shared/widgets/dialogs/form_dialog.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/empty_state.dart';
import '../../shared/widgets/feedback/snack.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/feedback/timeline.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_field.dart';
import '../../shared/widgets/forms/ya_input.dart';
import '../../shared/widgets/forms/ya_tabs.dart';
import '../../shared/widgets/kpi/kpi_card.dart';
import '../../shared/widgets/shell/detail_header.dart';
import '../../shared/widgets/table/cells.dart';
import '../../shared/widgets/table/data_table.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/types.dart';

class DriverDetailPage extends ConsumerStatefulWidget {
  const DriverDetailPage({required this.id, super.key});
  final String id;

  @override
  ConsumerState<DriverDetailPage> createState() => _DriverDetailPageState();
}

class _DriverDetailPageState extends ConsumerState<DriverDetailPage> {
  int _tab = 0;
  bool _busy = false;

  static const _tabs = [
    YaTabItem(label: 'Visão geral'),
    YaTabItem(label: 'Documentos'),
    YaTabItem(label: 'Corridas'),
    YaTabItem(label: 'Carteira'),
    YaTabItem(label: 'Histórico'),
  ];

  Future<void> _setStatus(String status, String okMessage) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(cloudFunctionsServiceProvider).setUserStatus(
            uid: widget.id,
            status: status,
          );
      if (!mounted) return;
      ref.invalidate(adminDriverByIdProvider(widget.id));
      ref.invalidate(adminDriversProvider);
      yaSnack(context, okMessage);
    } catch (e) {
      if (!mounted) return;
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverAsync = ref.watch(adminDriverByIdProvider(widget.id));
    final trips = ref.watch(adminTripsProvider).asData?.value ?? const [];

    return AsyncView<AdminDriver?>(
      value: driverAsync,
      onRetry: () => ref.invalidate(adminDriverByIdProvider(widget.id)),
      data: (driver) {
        if (driver == null) {
          return const EmptyState(
            icon: LucideIcons.user,
            title: 'Driver não encontrado',
            description: 'Este driver pode ter sido removido.',
          );
        }
        return _buildDetail(
          context,
          _DriverData.fromAdmin(driver, trips),
        );
      },
    );
  }

  Widget _buildDetail(BuildContext context, _DriverData d) {
    final status = YaStatus.fromDriverStatus(d.status, online: d.online);
    final partnerName = (d.partner == '-' || d.partner.isEmpty)
        ? '—'
        : (ref.watch(adminPartnerByIdProvider(d.partner)).asData?.value?.name ??
            d.partner);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailHeader(
          name: d.name,
          statusBadge: StatusBadge.fromMapping(status),
          subtitle: '${d.phone} · ${d.email}',
          meta: 'Partner: $partnerName',
          breadcrumb: _Breadcrumb(
            onBack: () => context.go('/admin/drivers'),
            name: d.name,
          ),
          actions: [
            if (d.status == 'active')
              YaButton.destructive(
                label: 'Suspender',
                icon: LucideIcons.ban,
                onPressed: _busy
                    ? null
                    : () => _setStatus('suspended', 'Driver suspenso'),
              ),
            if (d.status == 'suspended')
              YaButton.primary(
                label: 'Reactivar',
                icon: LucideIcons.rotateCcw,
                onPressed: _busy
                    ? null
                    : () => _setStatus('active', 'Driver reactivado'),
              ),
          ],
          tabs: YaTabs(
            items: _tabs,
            activeIndex: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
        ),
        const SizedBox(height: YaSpacing.xxl),
        _tabContent(context, d),
      ],
    );
  }

  Widget _tabContent(BuildContext context, _DriverData d) {
    return switch (_tab) {
      0 => _TabDriverGeral(d: d),
      1 => _TabDriverDocumentos(driverId: widget.id),
      2 => _TabDriverCorridas(driverId: widget.id),
      3 => _TabDriverCarteira(driverId: widget.id, partnerId: d.partner),
      4 => _TabDriverHistorico(driverId: widget.id),
      _ => const SizedBox.shrink(),
    };
  }
}

class _TabDriverDocumentos extends ConsumerWidget {
  const _TabDriverDocumentos({required this.driverId});
  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = (ref.watch(adminDocumentsProvider).asData?.value ??
            const <AdminDocument>[])
        .where((d) => d.ownerType == 'driver' && d.ownerId == driverId)
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
      emptyDescription: 'Este driver ainda não tem documentos registados.',
    );
  }
}

class _TabDriverCarteira extends ConsumerWidget {
  const _TabDriverCarteira({required this.driverId, required this.partnerId});
  final String driverId;
  final String partnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partner = ref.watch(adminPartnerByIdProvider(partnerId)).asData?.value;
    if (partner == null || !partner.requiresWalletSettlement) {
      return const EmptyState(
        icon: LucideIcons.wallet,
        title: 'Sem liquidação por carteira',
        description: 'Este parceiro não usa liquidação por carteira.',
      );
    }

    final key = (partnerId: partnerId, driverId: driverId);
    final walletAsync = ref.watch(adminDriverWalletProvider(key));

    return AsyncView<AdminDriverWallet?>(
      value: walletAsync,
      onRetry: () => ref.invalidate(adminDriverWalletProvider(key)),
      data: (wallet) => _CarteiraContent(
        partnerId: partnerId,
        driverId: driverId,
        wallet: wallet,
      ),
    );
  }
}

class _CarteiraContent extends ConsumerWidget {
  const _CarteiraContent({
    required this.partnerId,
    required this.driverId,
    required this.wallet,
  });

  final String partnerId;
  final String driverId;
  final AdminDriverWallet? wallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = YaColors.of(context);
    final moneyFormat = NumberFormat('#,##0', 'pt_PT');
    final balance = wallet?.balance ?? 0;
    final blocked = wallet?.blockedAt != null;
    final entries = wallet?.entries ?? const <AdminWalletEntry>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: KpiRow(
                children: [
                  KpiCard(
                    label: 'Saldo',
                    value: '${moneyFormat.format(balance)} MTn',
                    icon: LucideIcons.wallet,
                  ),
                  KpiCard(
                    label: 'Estado',
                    value: blocked ? 'Bloqueado' : 'Activo',
                    icon: blocked ? LucideIcons.ban : LucideIcons.circleCheck,
                  ),
                ],
              ),
            ),
            const SizedBox(width: YaSpacing.md),
            YaButton.primary(
              label: 'Ajustar saldo',
              icon: LucideIcons.pencil,
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _AdjustWalletDialog(
                  partnerId: partnerId,
                  driverId: driverId,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: YaSpacing.xxl),
        YaDataTable<AdminWalletEntry>(
          density: YaTableDensity.compact,
          columns: [
            YaColumn(
              key: 'when',
              label: 'Data',
              width: 130,
              cellBuilder: (e) =>
                  WhenCell(DateFormat('dd/MM/yyyy HH:mm').format(e.createdAt)),
            ),
            YaColumn(
              key: 'type',
              label: 'Tipo',
              width: 110,
              cellBuilder: (e) => StatusBadge(
                variant: switch (e.type) {
                  'commission' => StatusVariant.warning,
                  'topup' => StatusVariant.success,
                  'earning' => StatusVariant.success,
                  _ => StatusVariant.info,
                },
                label: switch (e.type) {
                  'commission' => 'Comissão',
                  'topup' => 'Recarga',
                  'earning' => 'Ganho (digital)',
                  _ => 'Ajuste',
                },
              ),
            ),
            YaColumn(
              key: 'amount',
              label: 'Valor',
              width: 110,
              align: Alignment.centerRight,
              cellBuilder: (e) => Text(
                '${e.amountMtn > 0 ? '+' : ''}${moneyFormat.format(e.amountMtn)} MTn',
                style: YaText.mono(size: 13, height: 18, weight: FontWeight.w500)
                    .copyWith(color: e.amountMtn < 0 ? colors.danger : colors.success),
              ),
            ),
            YaColumn(
              key: 'ref',
              label: 'Ref',
              cellBuilder: (e) => TextCell(
                e.tripId ?? e.mpesaRef ?? e.note ?? '-',
                muted: true,
              ),
            ),
          ],
          rows: entries,
          keyExtractor: (e) => e.id,
          emptyIcon: LucideIcons.wallet,
          emptyTitle: 'Sem movimentos',
          emptyDescription: 'Esta carteira ainda não tem lançamentos.',
        ),
      ],
    );
  }
}

class _AdjustWalletDialog extends ConsumerStatefulWidget {
  const _AdjustWalletDialog({required this.partnerId, required this.driverId});
  final String partnerId;
  final String driverId;

  @override
  ConsumerState<_AdjustWalletDialog> createState() =>
      _AdjustWalletDialogState();
}

class _AdjustWalletDialogState extends ConsumerState<_AdjustWalletDialog> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _note = TextEditingController();
  bool _credit = true;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final int? value = int.tryParse(_amount.text.trim());
    if (value == null || value <= 0) {
      yaSnack(context, 'Indica um valor válido.', variant: StatusVariant.danger);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(cloudFunctionsServiceProvider).adjustDriverWallet(
            partnerId: widget.partnerId,
            driverId: widget.driverId,
            amountMtn: _credit ? value : -value,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (!mounted) return;
      ref.invalidate(
        adminDriverWalletProvider(
          (partnerId: widget.partnerId, driverId: widget.driverId),
        ),
      );
      Navigator.of(context).pop();
      yaSnack(context, 'Saldo ajustado');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Ajustar saldo da carteira',
      description: 'Correção manual do saldo de comissão do motorista.',
      confirmLabel: 'Aplicar ajuste',
      submitting: _busy,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _submit,
      children: [
        YaField(
          label: 'Tipo',
          hint: _credit
              ? 'Vai aumentar o saldo (a favor do motorista).'
              : 'Vai reduzir o saldo (dívida do motorista).',
          child: Row(
            children: [
              Expanded(
                child: YaButton.secondary(
                  label: 'Crédito',
                  icon: LucideIcons.plus,
                  onPressed: () => setState(() => _credit = true),
                ),
              ),
              const SizedBox(width: YaSpacing.sm),
              Expanded(
                child: YaButton.secondary(
                  label: 'Débito',
                  icon: LucideIcons.minus,
                  onPressed: () => setState(() => _credit = false),
                ),
              ),
            ],
          ),
        ),
        YaField(
          label: 'Valor (MTn)',
          child: YaInput(
            controller: _amount,
            placeholder: '500',
            keyboardType: TextInputType.number,
          ),
        ),
        YaField(
          label: 'Nota (opcional)',
          child: YaInput(controller: _note, placeholder: 'Motivo do ajuste'),
        ),
      ],
    );
  }
}

class _TabDriverGeral extends StatelessWidget {
  const _TabDriverGeral({required this.d});
  final _DriverData d;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KpiRow(
          children: [
            KpiCard(
              label: 'Total corridas',
              value: d.totalTrips.toString(),
              icon: LucideIcons.route,
            ),
            KpiCard(
              label: 'Total ganho',
              value: d.totalEarned,
              icon: LucideIcons.trendingUp,
            ),
            KpiCard(
              label: 'Rating médio',
              value: '${d.rating} ★',
              icon: LucideIcons.star,
            ),
            KpiCard(
              label: 'Última actividade',
              value: d.lastActive,
              icon: LucideIcons.clock,
            ),
          ],
        ),
      ],
    );
  }
}

class _TabDriverCorridas extends ConsumerWidget {
  const _TabDriverCorridas({required this.driverId});
  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips =
        ref.watch(adminTripsProvider).asData?.value ?? const <AdminTrip>[];
    final rows = trips
        .where((t) => t.driverId == driverId)
        .map(
          (t) => _TripRow(
            t.id,
            t.origin ?? '-',
            t.destination ?? '-',
            t.amountMtn.toString(),
            t.status,
            DateFormat('dd/MM HH:mm').format(t.createdAt),
          ),
        )
        .toList();
    return YaDataTable<_TripRow>(
      density: YaTableDensity.compact,
      columns: [
        YaColumn(
          key: 'id',
          label: 'ID',
          width: 100,
          cellBuilder: (r) => IdCell(r.id),
        ),
        YaColumn(
          key: 'route',
          label: 'Rota',
          cellBuilder: (r) => RouteCell(from: r.from, to: r.to),
        ),
        YaColumn(
          key: 'amount',
          label: 'Valor',
          width: 100,
          align: Alignment.centerRight,
          cellBuilder: (r) => MoneyCell(amount: r.amount),
        ),
        YaColumn(
          key: 'status',
          label: 'Estado',
          width: 110,
          cellBuilder: (r) => StatusBadge.fromMapping(
            YaStatus.fromTripStatus(r.status),
          ),
        ),
        YaColumn(
          key: 'when',
          label: 'Quando',
          width: 100,
          cellBuilder: (r) => WhenCell(r.when),
        ),
      ],
      rows: rows,
      keyExtractor: (r) => r.id,
      emptyIcon: LucideIcons.route,
      emptyTitle: 'Sem corridas',
      emptyDescription: 'Este driver ainda não completou corridas.',
    );
  }
}

class _TabDriverHistorico extends ConsumerWidget {
  const _TabDriverHistorico({required this.driverId});
  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(adminAuditLogsProvider).asData?.value ??
        const <AdminAuditLog>[];
    final events = logs
        .where((l) => l.targetPath?.contains(driverId) ?? false)
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
            'As ações administrativas sobre este driver aparecem aqui.',
      );
    }
    return Timeline(events: events);
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
            'Drivers',
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

class _DriverData {
  const _DriverData({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.partner,
    required this.status,
    required this.online,
    required this.totalTrips,
    required this.totalEarned,
    required this.rating,
    required this.lastActive,
  });
  final String id, name, phone, email, partner, status, totalEarned, lastActive;
  final bool online;
  final int totalTrips;
  final double rating;

  factory _DriverData.fromAdmin(AdminDriver driver, List<AdminTrip> trips) {
    final driverTrips = trips.where((t) => t.driverId == driver.id).toList();
    final completed =
        driverTrips.where((t) => t.status == 'completed').toList();
    final volume = completed.fold<int>(0, (sum, t) => sum + t.amountMtn);
    final last = driverTrips.isEmpty
        ? null
        : driverTrips
            .map((t) => t.createdAt)
            .reduce((a, b) => a.isAfter(b) ? a : b);
    return _DriverData(
      id: driver.id,
      name: driver.name,
      phone: driver.phone ?? '-',
      email: driver.email ?? '-',
      partner: driver.partnerId ?? '-',
      status: driver.status,
      online: driver.online,
      totalTrips: driver.tripsCount > 0 ? driver.tripsCount : completed.length,
      totalEarned: '${NumberFormat('#,##0', 'pt_PT').format(volume)} MTn',
      rating: driver.rating,
      lastActive: last == null ? '-' : DateFormat('dd/MM HH:mm').format(last),
    );
  }
}

class _TripRow {
  const _TripRow(
    this.id,
    this.from,
    this.to,
    this.amount,
    this.status,
    this.when,
  );
  final String id, from, to, amount, status, when;
}

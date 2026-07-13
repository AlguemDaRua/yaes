import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/charts/bar_chart.dart';
import '../../shared/widgets/charts/chart_card.dart';
import '../../shared/widgets/charts/line_chart.dart';
import '../../shared/widgets/dialogs/form_dialog.dart';
import '../../shared/widgets/feedback/snack.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/filters/filter_bar.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_field.dart';
import '../../shared/widgets/forms/ya_input.dart';
import '../../shared/widgets/forms/ya_select.dart';
import '../../shared/widgets/kpi/kpi_card.dart';
import '../../shared/widgets/layout/responsive.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../shared/widgets/table/cells.dart';
import '../../shared/widgets/table/data_table.dart';
import '../../shared/utils/csv_export.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../data/types.dart';

class FinancePage extends ConsumerStatefulWidget {
  const FinancePage({super.key});

  @override
  ConsumerState<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends ConsumerState<FinancePage> {
  String _activeChip = 'all';

  void _openPayout() {
    showDialog<void>(
      context: context,
      builder: (BuildContext _) => const _PayoutDialog(),
    );
  }

  static const _chips = [
    FilterChipSpec(id: 'all', label: 'Todas'),
    FilterChipSpec(
      id: 'payment',
      label: 'Pagamentos',
      variant: StatusVariant.success,
    ),
    FilterChipSpec(
      id: 'payout',
      label: 'Payouts',
      variant: StatusVariant.info,
    ),
    FilterChipSpec(
      id: 'refund',
      label: 'Reembolsos',
      variant: StatusVariant.warning,
    ),
    FilterChipSpec(
      id: 'failed',
      label: 'Falhadas',
      variant: StatusVariant.danger,
    ),
  ];

  List<_Tx> _filtered(List<_Tx> all) {
    if (_activeChip == 'all') return all;
    return all.where((t) => t.type == _activeChip).toList();
  }

  _Tx _txFromPayment(AdminPayment p) {
    return _Tx(
      p.id,
      _methodLabel(p.method),
      p.status == 'failed' ? 'failed' : 'payment',
      p.amountMtn,
      p.status,
      DateFormat('dd/MM HH:mm').format(p.createdAt),
      p.createdAt,
    );
  }

  _Tx _txFromPayout(AdminPayout p, Map<String, String> partnerNames) {
    return _Tx(
      p.id,
      partnerNames[p.partnerId] ?? p.partnerId,
      'payout',
      p.amountMtn,
      p.status,
      DateFormat('dd/MM HH:mm').format(p.createdAt),
      p.createdAt,
    );
  }

  void _exportCsv(List<_Tx> rows) {
    if (rows.isEmpty) {
      yaSnack(context, 'Nada para exportar', variant: StatusVariant.warning);
      return;
    }
    final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
    downloadCsv('transacoes-$stamp.csv', <List<Object?>>[
      <Object?>['id', 'partner/metodo', 'tipo', 'valor_mtn', 'estado', 'data'],
      for (final r in rows)
        <Object?>[r.id, r.partner, r.type, r.amount, r.status, r.when],
    ]);
    yaSnack(context, 'CSV exportado');
  }

  String _methodLabel(String method) => switch (method) {
        'mpesa' => 'M-Pesa',
        'emola' => 'e-Mola',
        _ => method,
      };

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final List<AdminPayment> payments =
        ref.watch(adminPaymentsProvider).asData?.value ?? <AdminPayment>[];
    final List<AdminTrip> trips =
        ref.watch(adminTripsProvider).asData?.value ?? <AdminTrip>[];
    final List<AdminPartner> partners =
        ref.watch(adminPartnersProvider).asData?.value ?? <AdminPartner>[];
    final List<AdminPayout> payouts =
        ref.watch(adminPayoutsProvider).asData?.value ?? <AdminPayout>[];
    final Map<String, String> partnerNames = <String, String>{
      for (final AdminPartner p in partners) p.id: p.name,
    };
    final List<_Tx> txs = <_Tx>[
      ...payments.map(_txFromPayment),
      ...payouts.map((p) => _txFromPayout(p, partnerNames)),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final List<_Tx> filtered = _filtered(txs);

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    bool completedIn(AdminTrip t, DateTime from, DateTime to) =>
        t.status == 'completed' &&
        !t.createdAt.isBefore(from) &&
        t.createdAt.isBefore(to);

    final grossMonth = trips
        .where((t) => completedIn(t, monthStart, nextMonth))
        .fold<int>(0, (sum, t) => sum + t.amountMtn);
    final digitalMonth = payments
        .where((p) => p.status == 'paid' && !p.createdAt.isBefore(monthStart))
        .fold<int>(0, (sum, p) => sum + p.amountMtn);
    final pendingCount = payments.where((p) => p.status == 'pending').length;
    final failedCount = payments.where((p) => p.status == 'failed').length;
    final payoutsMonth = payouts
        .where((p) => !p.createdAt.isBefore(monthStart))
        .fold<int>(0, (sum, p) => sum + p.amountMtn);

    final fmt = NumberFormat('#,##0', 'pt_PT');

    final revenueLabels = <String>[];
    final revenueValues = <double>[];
    for (var i = 11; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i);
      final next = DateTime(m.year, m.month + 1);
      final total = trips
          .where((t) => completedIn(t, m, next))
          .fold<int>(0, (sum, t) => sum + t.amountMtn);
      final label = DateFormat('MMM', 'pt_PT').format(m);
      revenueLabels.add(
        label.isEmpty
            ? label
            : '${label[0].toUpperCase()}${label.substring(1)}',
      );
      revenueValues.add(total / 1000000);
    }

    final topPartners = [
      for (final p in partners)
        (
          p.name,
          trips
              .where(
                (t) =>
                    t.partnerId == p.id &&
                    completedIn(t, monthStart, nextMonth),
              )
              .fold<int>(0, (sum, t) => sum + t.amountMtn)
        ),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    final top5 = topPartners.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: S.of(context).adminFinanceTitle,
          description: 'Receita, comissões e movimentos financeiros',
          actions: [
            YaButton.secondary(
              label: 'Exportar',
              icon: LucideIcons.download,
              onPressed: () => _exportCsv(filtered),
            ),
            YaButton.primary(
              label: 'Novo payout',
              icon: LucideIcons.arrowUpRight,
              onPressed: _openPayout,
            ),
          ],
        ),
        const SizedBox(height: YaSpacing.xxl),
        KpiRow(
          children: [
            KpiCard(
              label: 'Receita bruta (mês)',
              value: fmt.format(grossMonth),
              valueSuffix: 'MTn',
              icon: LucideIcons.trendingUp,
            ),
            KpiCard(
              label: 'Pagamentos digitais (mês)',
              value: fmt.format(digitalMonth),
              valueSuffix: 'MTn',
              icon: LucideIcons.smartphone,
            ),
            KpiCard(
              label: 'Payouts (mês)',
              value: fmt.format(payoutsMonth),
              valueSuffix: 'MTn',
              icon: LucideIcons.arrowUpRight,
            ),
            KpiCard(
              label: 'Pendentes / falhados',
              value: '$pendingCount / $failedCount',
              icon: LucideIcons.triangleAlert,
            ),
          ],
        ),
        const SizedBox(height: YaSpacing.xxl),
        YaResponsiveStack(
          flexes: const [3, 2],
          children: [
            ChartCard(
              title: 'Receita mensal',
              subtitle: 'Últimos 12 meses · em milhões MTn',
              chartHeight: 200,
              child: YaLineChart(
                labels: revenueLabels,
                series: [
                  YaLineSeries(
                    values: revenueValues,
                    color: colors.brand,
                  ),
                ],
              ),
            ),
            ChartCard(
              title: 'Top partners por receita',
              subtitle: 'Este mês · em MTn',
              chartHeight: 200,
              child: top5.isEmpty
                  ? const Center(child: Text('Sem dados este mês'))
                  : YaBarChart(
                      labels: [for (final p in top5) p.$1],
                      values: [for (final p in top5) p.$2.toDouble()],
                      primaryColor: colors.brand,
                    ),
            ),
          ],
        ),
        const SizedBox(height: YaSpacing.xxl),
        ChartCard(
          title: 'Transações recentes',
          chartHeight: 470,
          child: SingleChildScrollView(
            child: Column(
              children: [
                FilterBar(
                  chips: _chips,
                  activeChipId: _activeChip,
                  onChipSelected: (id) => setState(() => _activeChip = id),
                  searchPlaceholder: 'Pesquisar por ID ou partner...',
                ),
                const SizedBox(height: YaSpacing.lg),
                YaDataTable<_Tx>(
                  density: YaTableDensity.compact,
                  columns: [
                    YaColumn(
                      key: 'id',
                      label: 'ID',
                      width: 90,
                      cellBuilder: (r) => IdCell(r.id),
                    ),
                    YaColumn(
                      key: 'partner',
                      label: 'Partner',
                      cellBuilder: (r) => PersonCell(
                        name: r.partner,
                        subtitle: '',
                      ),
                    ),
                    YaColumn(
                      key: 'type',
                      label: 'Tipo',
                      width: 110,
                      cellBuilder: (r) => TextCell(_typeLabel(r.type)),
                    ),
                    YaColumn(
                      key: 'amount',
                      label: 'Valor',
                      width: 120,
                      align: Alignment.centerRight,
                      cellBuilder: (r) => MoneyCell(
                        amount: r.amount == 0 ? '-' : r.amount.toString(),
                      ),
                    ),
                    YaColumn(
                      key: 'status',
                      label: 'Estado',
                      width: 130,
                      cellBuilder: (r) => StatusBadge.fromMapping(
                        YaStatus.fromTransactionStatus(r.status),
                      ),
                    ),
                    YaColumn(
                      key: 'when',
                      label: 'Quando',
                      width: 80,
                      cellBuilder: (r) => WhenCell(r.when),
                    ),
                  ],
                  rows: filtered,
                  keyExtractor: (r) => r.id,
                  emptyIcon: LucideIcons.receipt,
                  emptyTitle: 'Sem transações',
                  emptyDescription: 'Nenhuma transação corresponde ao filtro.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _typeLabel(String type) => switch (type) {
        'payment' => 'Pagamento',
        'payout' => 'Payout',
        'refund' => 'Reembolso',
        _ => type,
      };
}

class _Tx {
  const _Tx(
    this.id,
    this.partner,
    this.type,
    this.amount,
    this.status,
    this.when,
    this.createdAt,
  );

  final String id;
  final String partner;
  final String type;
  final int amount;
  final String status;
  final String when;
  final DateTime createdAt;
}

class _PayoutDialog extends ConsumerStatefulWidget {
  const _PayoutDialog();

  @override
  ConsumerState<_PayoutDialog> createState() => _PayoutDialogState();
}

class _PayoutDialogState extends ConsumerState<_PayoutDialog> {
  String? _partnerId;
  String _method = 'mpesa';
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _reference = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final String? partnerId = _partnerId;
    final int? amount =
        int.tryParse(_amount.text.trim().replaceAll(RegExp('[^0-9]'), ''));
    if (partnerId == null || amount == null || amount <= 0) {
      yaSnack(
        context,
        'Seleciona um partner e um valor válido.',
        variant: StatusVariant.danger,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final String reference = _reference.text.trim();
      await ref.read(cloudFunctionsServiceProvider).processPayout(
            partnerId: partnerId,
            amountMtn: amount,
            method: _method,
            reference: reference.isEmpty ? null : reference,
          );
      if (!mounted) return;
      ref.invalidate(adminPayoutsProvider);
      Navigator.of(context).pop();
      yaSnack(context, 'Payout registado');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      yaSnack(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<AdminPartner> partners =
        ref.watch(adminPartnersProvider).asData?.value ?? <AdminPartner>[];

    return FormDialog(
      title: 'Novo payout',
      description: 'Regista um pagamento manual a um partner.',
      confirmLabel: 'Registar payout',
      submitting: _busy,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _submit,
      children: <Widget>[
        YaField(
          label: 'Partner',
          child: YaSelect<String>(
            width: 320,
            placeholder: 'Seleciona partner',
            items: <YaSelectItem<String>>[
              for (final AdminPartner p in partners)
                YaSelectItem<String>(value: p.id, label: p.name),
            ],
            value: _partnerId,
            onChanged: (String value) => setState(() => _partnerId = value),
          ),
        ),
        YaField(
          label: 'Valor (MTn)',
          child: YaInput(
            controller: _amount,
            placeholder: '0',
            keyboardType: TextInputType.number,
          ),
        ),
        YaField(
          label: 'Método',
          child: YaSelect<String>(
            width: 320,
            items: const <YaSelectItem<String>>[
              YaSelectItem<String>(value: 'mpesa', label: 'M-Pesa'),
              YaSelectItem<String>(
                value: 'bank',
                label: 'Transferência bancária',
              ),
            ],
            value: _method,
            onChanged: (String value) => setState(() => _method = value),
          ),
        ),
        YaField(
          label: 'Referência (opcional)',
          child: YaInput(
            controller: _reference,
            placeholder: 'Ex: nº de transferência',
          ),
        ),
      ],
    );
  }
}

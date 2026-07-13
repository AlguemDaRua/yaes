import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/dialogs/form_dialog.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/snack.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_field.dart';
import '../../shared/widgets/forms/ya_input.dart';
import '../../shared/widgets/kpi/kpi_card.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../shared/widgets/table/cells.dart';
import '../../shared/widgets/table/data_table.dart';
import '../../theme/tokens/dimensions.dart';
import '../data/types.dart';

/// Comissão por partner (`/commissions/{partnerId}` via `setCommission`).
/// As taxas por tipo de viagem (regular 12% · scheduled 10% · airport 15%)
/// estão definidas no pricing da plataforma (functions/src/pricing.ts).
class CommissionsPage extends ConsumerWidget {
  const CommissionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnersAsync = ref.watch(adminPartnersProvider);
    final commissions = ref.watch(adminCommissionsProvider).asData?.value ??
        const <AdminCommission>[];

    final config =
        ref.watch(adminConfigProvider('pricing')).asData?.value ??
            const <String, dynamic>{};
    final fares = config['fares'] is Map
        ? Map<String, dynamic>.from(config['fares'] as Map)
        : const <String, dynamic>{};
    int commissionPct(String tripType, int fallback) {
      final fare = fares[tripType];
      if (fare is Map && fare['commission'] is num) {
        return ((fare['commission'] as num) * 100).round();
      }
      return fallback;
    }

    final int regularPct = commissionPct('regular', 12);
    final int scheduledPct = commissionPct('scheduled', 10);
    final int airportPct = commissionPct('airport', 15);

    return AsyncView<List<AdminPartner>>(
      value: partnersAsync,
      onRetry: () {
        ref
          ..invalidate(adminPartnersProvider)
          ..invalidate(adminCommissionsProvider);
      },
      data: (partners) {
        final rows = partners
            .map(
              (p) => _CommissionRow(
                partnerId: p.id,
                partnerName: p.name,
                rate: commissions
                        .where((c) => c.partnerId == p.id)
                        .map((c) => (c.rate * 100).round())
                        .firstOrNull ??
                    regularPct,
                custom: commissions.any((c) => c.partnerId == p.id),
              ),
            )
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: S.of(context).adminNavCommissions,
              description:
                  'Taxa (%) cobrada por partner · padrão da plataforma: '
                  '$regularPct%',
              actions: [
                YaButton.secondary(
                  label: 'Histórico de alterações',
                  icon: LucideIcons.history,
                  onPressed: () => context.go('/admin/commissions/list'),
                ),
              ],
            ),
            const SizedBox(height: YaSpacing.xxl),
            KpiRow(
              children: [
                KpiCard(
                  label: 'Regular',
                  value: '$regularPct%',
                  icon: LucideIcons.car,
                ),
                KpiCard(
                  label: 'Agendada',
                  value: '$scheduledPct%',
                  icon: LucideIcons.calendar,
                ),
                KpiCard(
                  label: 'Aeroporto',
                  value: '$airportPct%',
                  icon: LucideIcons.plane,
                ),
              ],
            ),
            const SizedBox(height: YaSpacing.xxl),
            YaDataTable<_CommissionRow>(
              columns: [
                YaColumn(
                  key: 'partner',
                  label: 'Partner',
                  cellBuilder: (r) =>
                      PersonCell(name: r.partnerName, subtitle: r.partnerId),
                ),
                YaColumn(
                  key: 'rate',
                  label: 'Taxa',
                  width: 110,
                  align: Alignment.centerRight,
                  cellBuilder: (r) => TextCell('${r.rate}%', alignEnd: true),
                ),
                YaColumn(
                  key: 'origin',
                  label: 'Origem',
                  width: 150,
                  cellBuilder: (r) => TextCell(
                    r.custom ? 'Negociada' : 'Padrão',
                    muted: !r.custom,
                  ),
                ),
                YaColumn(
                  key: 'actions',
                  label: '',
                  width: 110,
                  cellBuilder: (r) => YaButton.ghost(
                    label: 'Editar',
                    size: YaButtonSize.sm,
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => _EditCommissionDialog(row: r),
                    ),
                  ),
                ),
              ],
              rows: rows,
              keyExtractor: (r) => r.partnerId,
              emptyIcon: LucideIcons.percent,
              emptyTitle: 'Sem partners',
              emptyDescription: 'Cria o primeiro partner para gerir comissões.',
            ),
          ],
        );
      },
    );
  }
}

class _CommissionRow {
  const _CommissionRow({
    required this.partnerId,
    required this.partnerName,
    required this.rate,
    required this.custom,
  });

  final String partnerId;
  final String partnerName;
  final int rate;
  final bool custom;
}

class _EditCommissionDialog extends ConsumerStatefulWidget {
  const _EditCommissionDialog({required this.row});

  final _CommissionRow row;

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
    final pct = double.tryParse(_rate.text.trim().replaceAll(',', '.'));
    if (pct == null || pct < 0 || pct > 100) {
      yaSnack(context, 'Taxa inválida (0–100%)', variant: StatusVariant.danger);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(cloudFunctionsServiceProvider).setCommission(
            partnerId: widget.row.partnerId,
            rate: pct / 100,
          );
      if (!mounted) return;
      ref.invalidate(adminCommissionsProvider);
      Navigator.of(context).pop();
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
      title: 'Comissão de ${widget.row.partnerName}',
      description:
          'Entra em vigor imediatamente e fica registada no histórico.',
      confirmLabel: 'Guardar',
      submitting: _busy,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _submit,
      children: [
        YaField(
          label: 'Nova taxa (%)',
          child: YaInput(
            controller: _rate,
            placeholder: widget.row.rate.toString(),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }
}

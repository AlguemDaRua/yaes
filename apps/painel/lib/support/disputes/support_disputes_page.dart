import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/dialogs/confirm_dialog.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/filters/filter_bar.dart';
import '../../shared/widgets/forms/ya_field.dart';
import '../../shared/widgets/forms/ya_textarea.dart';
import '../../shared/widgets/shell/page_header.dart';
import '../../shared/widgets/table/cells.dart';
import '../../shared/widgets/table/data_table.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/mock_types.dart';
import '../widgets/support_common.dart';

class SupportDisputesPage extends ConsumerStatefulWidget {
  const SupportDisputesPage({super.key});

  @override
  ConsumerState<SupportDisputesPage> createState() =>
      _SupportDisputesPageState();
}

class _SupportDisputesPageState extends ConsumerState<SupportDisputesPage> {
  String _activeFilter = 'all';

  List<SupportDispute> _filterRows(List<SupportDispute> source) {
    return source.where((SupportDispute dispute) {
      return switch (_activeFilter) {
        'one' => dispute.rating == 1,
        'two' => dispute.rating == 2,
        'suspicious' => dispute.comment.toLowerCase().contains('cancel'),
        'resolved' => dispute.status == SupportDisputeStatus.resolved,
        _ => true,
      };
    }).toList();
  }

  void _openResolve(SupportDispute row) {
    showDialog<void>(
      context: context,
      builder: (BuildContext _) => _ResolveDisputeDialog(tripId: row.tripId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);
    final AsyncValue<List<SupportDispute>> disputesAsync =
        ref.watch(supportDisputesProvider);

    return AsyncView<List<SupportDispute>>(
      value: disputesAsync,
      onRetry: () => ref.invalidate(supportDisputesProvider),
      data: (List<SupportDispute> source) {
        final List<SupportDispute> rows = _filterRows(source);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PageHeader(
              title: S.of(context).supportNavDisputes,
              description:
                  'Trips com avaliacao baixa ou motivos de cancelamento sensiveis',
            ),
            const SizedBox(height: YaSpacing.xxl),
            FilterBar(
              searchPlaceholder: 'Pesquisar disputa...',
              activeChipId: _activeFilter,
              onChipSelected: (String id) => setState(() => _activeFilter = id),
              chips: const <FilterChipSpec>[
                FilterChipSpec(id: 'all', label: 'Todas'),
                FilterChipSpec(
                  id: 'one',
                  label: 'Avaliacao 1*',
                  variant: StatusVariant.danger,
                ),
                FilterChipSpec(
                  id: 'two',
                  label: 'Avaliacao 2*',
                  variant: StatusVariant.warning,
                ),
                FilterChipSpec(
                  id: 'suspicious',
                  label: 'Canceladas suspeitas',
                  variant: StatusVariant.info,
                ),
                FilterChipSpec(
                  id: 'resolved',
                  label: 'Resolvidas',
                  variant: StatusVariant.success,
                ),
              ],
            ),
            const SizedBox(height: YaSpacing.xxl),
            YaDataTable<SupportDispute>(
              rows: rows,
              keyExtractor: (SupportDispute row) => row.tripId,
              onRowTap: (SupportDispute row) =>
                  context.go('/admin/trips/${row.tripId}'),
              onRowMore: _openResolve,
              columns: <YaColumn<SupportDispute>>[
                YaColumn<SupportDispute>(
                  key: 'trip',
                  label: 'Trip ID',
                  width: 110,
                  cellBuilder: (SupportDispute row) => IdCell(row.tripId),
                ),
                YaColumn<SupportDispute>(
                  key: 'route',
                  label: 'Origem -> destino',
                  width: 230,
                  cellBuilder: (SupportDispute row) =>
                      RouteCell(from: row.from, to: row.to),
                ),
                YaColumn<SupportDispute>(
                  key: 'passenger',
                  label: 'Passageiro',
                  width: 180,
                  cellBuilder: (SupportDispute row) => PersonCell(
                    name: row.passengerName,
                    subtitle: 'passageiro',
                  ),
                ),
                YaColumn<SupportDispute>(
                  key: 'driver',
                  label: 'Driver',
                  width: 180,
                  cellBuilder: (SupportDispute row) => PersonCell(
                    name: row.driverName,
                    subtitle: 'driver',
                  ),
                ),
                YaColumn<SupportDispute>(
                  key: 'stars',
                  label: 'Estrelas',
                  width: 100,
                  cellBuilder: (SupportDispute row) => Text(
                    List<String>.filled(row.rating, '*').join(),
                    style: YaText.smMedium.copyWith(
                      color:
                          row.rating <= 2 ? colors.danger : colors.textPrimary,
                    ),
                  ),
                ),
                YaColumn<SupportDispute>(
                  key: 'comment',
                  label: 'Comentario',
                  width: 250,
                  cellBuilder: (SupportDispute row) => Tooltip(
                    message: row.comment,
                    child: TextCell(row.comment),
                  ),
                ),
                YaColumn<SupportDispute>(
                  key: 'status',
                  label: 'Status disputa',
                  width: 140,
                  cellBuilder: (SupportDispute row) => StatusBadge.fromMapping(
                    supportDisputeStatusMapping(row.status),
                    size: StatusBadgeSize.sm,
                  ),
                ),
                YaColumn<SupportDispute>(
                  key: 'when',
                  label: 'Quando',
                  width: 110,
                  cellBuilder: (SupportDispute row) =>
                      WhenCell(supportRelativeWhen(row.createdAt)),
                ),
              ],
              footer: YaTablePagination(
                currentPage: 1,
                totalPages: 1,
                onPageChange: (_) {},
                summary: 'A mostrar ${rows.length} disputas',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResolveDisputeDialog extends ConsumerStatefulWidget {
  const _ResolveDisputeDialog({required this.tripId});
  final String tripId;

  @override
  ConsumerState<_ResolveDisputeDialog> createState() =>
      _ResolveDisputeDialogState();
}

class _ResolveDisputeDialogState extends ConsumerState<_ResolveDisputeDialog> {
  final TextEditingController _resolution = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _resolution.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final String resolution = _resolution.text.trim();
    if (resolution.isEmpty) {
      supportToast(
        context,
        'Descreve a resolução.',
        variant: StatusVariant.danger,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(cloudFunctionsServiceProvider).resolveDispute(
            tripId: widget.tripId,
            resolution: resolution,
          );
      if (!mounted) return;
      ref.invalidate(supportDisputesProvider);
      Navigator.of(context).pop();
      supportToast(context, 'Disputa resolvida');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      supportToast(context, 'Erro: $e', variant: StatusVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmDialog(
      title: 'Resolver disputa ${widget.tripId}',
      description:
          'A resolução fica registada e o estado da disputa passa a resolvido.',
      confirmLabel: _busy ? 'A resolver…' : 'Resolver',
      onCancel: _busy ? null : () => Navigator.of(context).pop(),
      onConfirm: _busy ? null : _submit,
      body: YaField(
        label: 'Resolução',
        hint: 'Ex: Reembolso parcial emitido ao passageiro',
        child: YaTextarea(
          controller: _resolution,
          placeholder: 'Descreve a decisão tomada',
        ),
      ),
    );
  }
}

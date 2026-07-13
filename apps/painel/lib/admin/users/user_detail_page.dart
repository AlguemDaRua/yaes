import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/status_mapping.dart';
import '../../data/providers.dart';
import '../../shared/widgets/feedback/async_view.dart';
import '../../shared/widgets/feedback/empty_state.dart';
import '../../shared/widgets/feedback/snack.dart';
import '../../shared/widgets/feedback/status_badge.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_tabs.dart';
import '../../shared/widgets/kpi/kpi_card.dart';
import '../../shared/widgets/shell/detail_header.dart';
import '../../shared/widgets/table/cells.dart';
import '../../shared/widgets/table/data_table.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/types.dart';

class UserDetailPage extends ConsumerStatefulWidget {
  const UserDetailPage({required this.id, super.key});

  final String id;

  @override
  ConsumerState<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends ConsumerState<UserDetailPage> {
  int _tab = 0;
  bool _busy = false;

  static const _tabs = [
    YaTabItem(label: 'Corridas'),
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
      ref.invalidate(adminUserByIdProvider(widget.id));
      ref.invalidate(adminUsersProvider);
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
    final userAsync = ref.watch(adminUserByIdProvider(widget.id));
    final trips =
        ref.watch(adminTripsProvider).asData?.value ?? const <AdminTrip>[];

    return AsyncView<AdminUser?>(
      value: userAsync,
      onRetry: () => ref.invalidate(adminUserByIdProvider(widget.id)),
      data: (user) {
        if (user == null) {
          return const EmptyState(
            icon: LucideIcons.user,
            title: 'Utilizador não encontrado',
            description: 'Este utilizador pode ter sido removido.',
          );
        }
        return _buildDetail(context, user, trips);
      },
    );
  }

  Widget _buildDetail(
    BuildContext context,
    AdminUser user,
    List<AdminTrip> trips,
  ) {
    final userTrips =
        trips.where((t) => t.passengerId == widget.id).toList();
    final name = user.name ?? user.phone ?? user.email ?? user.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailHeader(
          name: name,
          subtitle: '${user.phone ?? '-'} · ${user.email ?? '-'}',
          meta: 'Tipo: ${user.type}',
          breadcrumb: _Breadcrumb(
            onBack: () => context.go('/admin/users'),
            name: name,
          ),
          actions: [
            YaButton.destructive(
              label: 'Bloquear',
              icon: LucideIcons.ban,
              onPressed: _busy
                  ? null
                  : () => _setStatus('suspended', 'Utilizador bloqueado'),
            ),
          ],
          tabs: YaTabs(
            items: _tabs,
            activeIndex: _tab,
            onChanged: (index) => setState(() => _tab = index),
          ),
        ),
        const SizedBox(height: YaSpacing.xxl),
        KpiRow(
          children: [
            KpiCard(
              label: 'Total corridas',
              value: userTrips.length.toString(),
              icon: LucideIcons.route,
            ),
            KpiCard(
              label: 'Completadas',
              value: userTrips
                  .where((t) => t.status == 'completed')
                  .length
                  .toString(),
              icon: LucideIcons.circleCheck,
            ),
            KpiCard(
              label: 'Canceladas',
              value: userTrips
                  .where((t) => t.status == 'cancelled')
                  .length
                  .toString(),
              icon: LucideIcons.ban,
            ),
          ],
        ),
        const SizedBox(height: YaSpacing.xxl),
        _TabTrips(trips: userTrips),
      ],
    );
  }
}

class _TabTrips extends StatelessWidget {
  const _TabTrips({required this.trips});

  final List<AdminTrip> trips;

  @override
  Widget build(BuildContext context) {
    return YaDataTable<AdminTrip>(
      density: YaTableDensity.compact,
      columns: [
        YaColumn(
          key: 'id',
          label: 'ID',
          width: 100,
          cellBuilder: (row) => IdCell(row.id),
        ),
        YaColumn(
          key: 'route',
          label: 'Rota',
          cellBuilder: (row) => RouteCell(
            from: row.origin ?? '-',
            to: row.destination ?? '-',
          ),
        ),
        YaColumn(
          key: 'amount',
          label: 'Valor',
          width: 100,
          align: Alignment.centerRight,
          cellBuilder: (row) => MoneyCell(amount: row.amountMtn.toString()),
        ),
        YaColumn(
          key: 'status',
          label: 'Estado',
          width: 180,
          cellBuilder: (row) => StatusBadge.fromMapping(
            YaStatus.fromTripStatus(row.status),
          ),
        ),
        YaColumn(
          key: 'when',
          label: 'Quando',
          width: 110,
          cellBuilder: (row) =>
              WhenCell(DateFormat('dd/MM HH:mm').format(row.createdAt)),
        ),
      ],
      rows: trips,
      keyExtractor: (row) => row.id,
      onRowTap: (row) => context.go('/admin/trips/${row.id}'),
      emptyIcon: LucideIcons.route,
      emptyTitle: 'Sem corridas',
      emptyDescription: 'Este utilizador ainda não pediu corridas.',
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
            'Utilizadores',
            style: YaText.sm.copyWith(color: colors.textMuted),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('>', style: YaText.sm.copyWith(color: colors.textMuted)),
        ),
        Text(
          name,
          style: YaText.sm.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/providers.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../data/types.dart';

/// FocusNode partilhado da pesquisa do topo, para o atalho Cmd/Ctrl+K poder
/// focá-la a partir do shell.
final Provider<FocusNode> searchFocusProvider = Provider<FocusNode>((ref) {
  final node = FocusNode(debugLabel: 'global-search');
  ref.onDispose(node.dispose);
  return node;
});

class _Result {
  const _Result({
    required this.category,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.route,
  });

  final String category;
  final String label;
  final String sublabel;
  final IconData icon;
  final String route;
}

/// Pesquisa global inline na topbar: escreve e os resultados (partners,
/// drivers, passageiros, corridas — dados live) aparecem num dropdown ancorado.
class AdminSearchField extends ConsumerStatefulWidget {
  const AdminSearchField({super.key});

  @override
  ConsumerState<AdminSearchField> createState() => _AdminSearchFieldState();
}

class _AdminSearchFieldState extends ConsumerState<AdminSearchField> {
  final TextEditingController _controller = TextEditingController();
  final LayerLink _link = LayerLink();
  final OverlayPortalController _portal = OverlayPortalController();
  final Object _tapGroup = Object();
  late final FocusNode _focus = ref.read(searchFocusProvider);
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    _focus.addListener(_sync);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _focus.removeListener(_sync);
    _controller.dispose();
    super.dispose();
  }

  void _onChange() {
    setState(() => _query = _controller.text);
    _sync();
  }

  void _sync() {
    final show = _focus.hasFocus && _query.trim().isNotEmpty;
    if (show) {
      _portal.show();
    } else {
      _portal.hide();
    }
  }

  void _close() {
    _controller.clear();
    _focus.unfocus();
    _portal.hide();
  }

  void _go(String route) {
    _close();
    context.go(route);
  }

  List<_Result> _results() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const <_Result>[];

    final partners = ref.watch(adminPartnersProvider).asData?.value ??
        const <AdminPartner>[];
    final drivers =
        ref.watch(adminDriversProvider).asData?.value ?? const <AdminDriver>[];
    final trips =
        ref.watch(adminTripsProvider).asData?.value ?? const <AdminTrip>[];
    final users =
        ref.watch(adminUsersProvider).asData?.value ?? const <AdminUser>[];

    bool match(List<String?> fields) =>
        fields.any((f) => f != null && f.toLowerCase().contains(q));

    final results = <_Result>[];
    for (final p in partners) {
      if (match([p.name, p.id, p.city, p.nuit])) {
        results.add(
          _Result(
            category: 'Partners',
            label: p.name,
            sublabel: p.city,
            icon: LucideIcons.building2,
            route: '/admin/partners/${p.id}',
          ),
        );
      }
    }
    for (final d in drivers) {
      if (match([d.name, d.id, d.phone, d.email])) {
        results.add(
          _Result(
            category: 'Drivers',
            label: d.name,
            sublabel: d.phone ?? d.id,
            icon: LucideIcons.car,
            route: '/admin/drivers/${d.id}',
          ),
        );
      }
    }
    for (final u in users.where((u) => u.type == 'passenger')) {
      if (match([u.name, u.id, u.phone, u.email])) {
        results.add(
          _Result(
            category: 'Passageiros',
            label: u.name ?? u.phone ?? u.id,
            sublabel: u.phone ?? u.id,
            icon: LucideIcons.user,
            route: '/admin/users/${u.id}',
          ),
        );
      }
    }
    for (final t in trips) {
      if (match([t.id, t.origin, t.destination])) {
        results.add(
          _Result(
            category: 'Corridas',
            label: t.id,
            sublabel: '${t.origin ?? '-'} → ${t.destination ?? '-'}',
            icon: LucideIcons.route,
            route: '/admin/trips/${t.id}',
          ),
        );
      }
    }
    return results.take(12).toList();
  }

  // Resultados calculados no build (onde ref.watch é válido) e partilhados
  // com o dropdown do OverlayPortal.
  List<_Result> _visible = const <_Result>[];

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    _visible = _results();

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _buildDropdown,
        child: _buildField(colors),
      ),
    );
  }

  Widget _buildField(YaColors colors) {
    final focused = _focus.hasFocus;
    return TapRegion(
      groupId: _tapGroup,
      onTapOutside: (_) {
        if (_portal.isShowing) _close();
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colors.bgBase,
          borderRadius: YaRadius.brMd,
          border: Border.all(
            color: focused ? colors.borderDefault : colors.borderSubtle,
          ),
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: colors.brand.withValues(alpha: 0.12),
                    spreadRadius: 3,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(LucideIcons.search, size: 14, color: colors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Shortcuts(
                shortcuts: const <ShortcutActivator, Intent>{
                  SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
                },
                child: Actions(
                  actions: <Type, Action<Intent>>{
                    DismissIntent: CallbackAction<DismissIntent>(
                      onInvoke: (_) {
                        _close();
                        return null;
                      },
                    ),
                  },
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    cursorColor: colors.brand,
                    textAlign: TextAlign.center,
                    style: YaText.sm.copyWith(color: colors.textPrimary),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: 'Pesquisar...',
                      hintStyle: YaText.sm.copyWith(color: colors.textMuted),
                    ),
                    onSubmitted: (_) {
                      if (_visible.isNotEmpty) _go(_visible.first.route);
                    },
                  ),
                ),
              ),
            ),
            // Equilibra a lupa à esquerda para o texto ficar centrado.
            const SizedBox(width: 22),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedItems(List<_Result> results, YaColors colors) {
    final items = <Widget>[];
    String? lastCategory;
    for (final r in results) {
      if (r.category != lastCategory) {
        lastCategory = r.category;
        items.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(
              YaSpacing.md,
              YaSpacing.sm,
              YaSpacing.md,
              4,
            ),
            child: Text(
              r.category.toUpperCase(),
              style: YaText.sans(
                size: 10,
                height: 14,
                weight: FontWeight.w500,
                letterSpacing: 0.4,
              ).copyWith(color: colors.textMuted),
            ),
          ),
        );
      }
      items.add(
        _ResultTile(
          result: r,
          colors: colors,
          onTap: () => _go(r.route),
        ),
      );
    }
    return items;
  }

  Widget _buildDropdown(BuildContext context) {
    final colors = YaColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final results = _visible;

    // Overlay é uma Stack: devolvemos um Positioned ancorado ao campo. Sem
    // barreira de ecrã inteiro — o fecho ao clicar fora é tratado pelo
    // TapRegion partilhado entre o campo e o dropdown.
    return Positioned(
      width: 360,
      child: CompositedTransformFollower(
        link: _link,
        targetAnchor: Alignment.bottomLeft,
        offset: const Offset(0, 6),
        child: TapRegion(
          groupId: _tapGroup,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: YaRadius.brMd,
                border: Border.all(color: colors.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isLight ? 0.12 : 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: YaSpacing.md,
                        vertical: YaSpacing.lg,
                      ),
                      child: Text(
                        'Sem resultados para "${_query.trim()}"',
                        style: YaText.sm.copyWith(color: colors.textMuted),
                      ),
                    )
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: YaSpacing.xs),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildGroupedItems(results, colors),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultTile extends StatefulWidget {
  const _ResultTile({
    required this.result,
    required this.colors,
    required this.onTap,
  });

  final _Result result;
  final YaColors colors;
  final VoidCallback onTap;

  @override
  State<_ResultTile> createState() => _ResultTileState();
}

class _ResultTileState extends State<_ResultTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final r = widget.result;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: YaSpacing.xs,
            vertical: 1,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: YaSpacing.sm,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: _hovering ? colors.bgSubtle : Colors.transparent,
            borderRadius: YaRadius.brSm,
          ),
          child: Row(
            children: [
              Icon(r.icon, size: 15, color: colors.textSecondary),
              const SizedBox(width: YaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.label,
                      style:
                          YaText.smMedium.copyWith(color: colors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      r.sublabel,
                      style: YaText.sans(size: 11, height: 15)
                          .copyWith(color: colors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tradução fiel de _design/showcases/sidebar.jsx (componentes SidebarFrame,
// NavItem, Group). Spec: _design/components.md §2.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';
import '../forms/ya_avatar.dart';

/// Item de navegação na sidebar.
@immutable
class SidebarNavItem {
  const SidebarNavItem({
    required this.icon,
    required this.label,
    required this.route,
    this.badge,
    this.disabled = false,
    this.tag,
  });

  final IconData icon;
  final String label;
  final String route;

  /// Contagem opcional (ex: tickets abertos).
  final int? badge;

  /// Item desactivado (50% opacity, sem hover, cursor not-allowed).
  final bool disabled;

  /// Tag pequena no canto superior direito (ex: "BETA").
  final String? tag;
}

/// Grupo de items na sidebar com título uppercase.
@immutable
class SidebarNavGroup {
  const SidebarNavGroup({required this.label, required this.items});
  final String label;
  final List<SidebarNavItem> items;
}

/// Sidebar do shell: wordmark + role tag + grupos + footer com user.
class Sidebar extends StatelessWidget {
  const Sidebar({
    required this.role,
    required this.groups,
    required this.currentRoute,
    required this.onItemTap,
    required this.userName,
    required this.userEmail,
    this.collapsed = false,
    this.onThemeToggle,
    super.key,
  });

  /// 'admin' | 'partner' | 'support' — usado no tag uppercase.
  final String role;
  final List<SidebarNavGroup> groups;
  final String currentRoute;
  final void Function(String route) onItemTap;
  final String userName;
  final String userEmail;
  final bool collapsed;
  final VoidCallback? onThemeToggle;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);

    return AnimatedContainer(
      duration: YaDurations.instant,
      curve: YaDurations.easeOut,
      width: collapsed
          ? YaDimensions.sidebarWidthCollapsed
          : YaDimensions.sidebarWidth,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(
          right: BorderSide(color: colors.borderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors),
          Expanded(child: _buildNav(colors)),
          _buildFooter(colors),
        ],
      ),
    );
  }

  Widget _buildHeader(YaColors colors) {
    return Padding(
      padding: collapsed
          ? const EdgeInsets.fromLTRB(8, 18, 8, 16)
          : const EdgeInsets.fromLTRB(10, 18, 10, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: collapsed
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'YA',
              textAlign: collapsed ? TextAlign.center : TextAlign.left,
              style: YaText.serif(
                size: 24,
                height: 24, // lineHeight 1
                letterSpacing: -0.48, // -0.02em * 24
                weight: FontWeight.w500,
              ).copyWith(color: colors.textPrimary),
            ),
          ),
          if (!collapsed) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'PAINEL · ${role.toUpperCase()}',
                style: YaText.eyebrowRole.copyWith(color: colors.textMuted),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildNav(YaColors colors) {
    final activeRoute = _activeItemRoute();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final group in groups) ...[
            if (!collapsed)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 14, 8, 5),
                child: Text(
                  group.label.toUpperCase(),
                  style:
                      YaText.eyebrowSidebar.copyWith(color: colors.textMuted),
                ),
              )
            else
              const SizedBox(height: 12),
            for (final item in group.items)
              _NavItem(
                item: item,
                isActive: item.route == activeRoute,
                collapsed: collapsed,
                onTap: item.disabled ? null : () => onItemTap(item.route),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(YaColors colors) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.borderSubtle),
        ),
      ),
      child: Padding(
        padding: collapsed
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 12)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: collapsed
            ? Center(child: YaAvatar.fromName(userName, size: 28))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  children: [
                    YaAvatar.fromName(userName, size: 28),
                    const SizedBox(width: YaSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            userName,
                            style: YaText.sans(
                              size: 12,
                              height: 16,
                              weight: FontWeight.w500,
                            ).copyWith(color: colors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            userEmail,
                            style: YaText.sans(size: 10.5, height: 14)
                                .copyWith(color: colors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _ThemeToggleButton(onTap: onThemeToggle),
                  ],
                ),
              ),
      ),
    );
  }

  /// Active = rota actual começa com a rota do item.
  /// Ex: `/admin/partners/abc123` activa o item `/admin/partners`.
  String? _activeItemRoute() {
    String? activeRoute;

    for (final group in groups) {
      for (final item in group.items) {
        if (!_matchesRoute(item.route)) continue;

        if (activeRoute == null || item.route.length > activeRoute.length) {
          activeRoute = item.route;
        }
      }
    }

    return activeRoute;
  }

  bool _matchesRoute(String itemRoute) {
    return currentRoute == itemRoute || currentRoute.startsWith('$itemRoute/');
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.item,
    required this.isActive,
    required this.collapsed,
    required this.onTap,
  });

  final SidebarNavItem item;
  final bool isActive;
  final bool collapsed;
  final VoidCallback? onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovering = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final disabled = widget.item.disabled;
    final active = widget.isActive;

    final palette = _resolve(colors, active: active, disabled: disabled);

    final body = AnimatedContainer(
      duration: YaDurations.micro,
      margin: const EdgeInsets.only(bottom: 1),
      padding: widget.collapsed
          ? const EdgeInsets.all(6)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: YaRadius.brSm,
        boxShadow: _focused ? YaShadows.focusBrand : YaShadows.none,
      ),
      child: Row(
        mainAxisAlignment: widget.collapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Opacity(
            opacity: active || _hovering || _focused ? 1.0 : 0.85,
            child: Icon(widget.item.icon, size: 14, color: palette.fg),
          ),
          if (!widget.collapsed) ...[
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                widget.item.label,
                style: YaText.sans(
                  size: 12.5,
                  // JSX: lineHeight 1.2 → 12.5 * 1.2 = 15
                  height: 15,
                  weight: active ? FontWeight.w500 : FontWeight.w400,
                ).copyWith(color: palette.fg),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.item.badge != null && widget.item.badge! > 0)
              _NavBadge(count: widget.item.badge!, active: active),
          ],
        ],
      ),
    );

    Widget wrapped = Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Focus(
        canRequestFocus: !disabled,
        onFocusChange: (f) => setState(() => _focused = f),
        child: MouseRegion(
          cursor: disabled
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
          onEnter: (_) {
            if (!disabled) setState(() => _hovering = true);
          },
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(onTap: widget.onTap, child: body),
        ),
      ),
    );

    if (widget.item.tag != null) {
      wrapped = Stack(
        clipBehavior: Clip.none,
        children: [
          wrapped,
          Positioned(
            top: -4,
            right: -4,
            child: _CornerTag(label: widget.item.tag!),
          ),
        ],
      );
    }

    if (widget.collapsed) {
      return Tooltip(message: widget.item.label, child: wrapped);
    }
    return wrapped;
  }

  _NavPalette _resolve(YaColors c,
      {required bool active, required bool disabled,}) {
    if (disabled) {
      return _NavPalette(
        bg: Colors.transparent,
        fg: c.textDisabled,
      );
    }
    if (active) {
      return _NavPalette(
        bg: _hovering ? c.brandSubtleHover : c.brandSubtle,
        fg: c.brand,
      );
    }
    if (_hovering || _focused) {
      return _NavPalette(bg: c.bgSubtle, fg: c.textPrimary);
    }
    return _NavPalette(bg: Colors.transparent, fg: c.textSecondary);
  }
}

class _NavPalette {
  const _NavPalette({required this.bg, required this.fg});
  final Color bg;
  final Color fg;
}

class _NavBadge extends StatelessWidget {
  const _NavBadge({required this.count, required this.active});
  final int count;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: active ? colors.brand : colors.brandSubtle,
        borderRadius: YaRadius.brFull,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: YaText.sans(size: 10, height: 14, weight: FontWeight.w500)
            .copyWith(color: active ? colors.textInverse : colors.brand),
      ),
    );
  }
}

class _CornerTag extends StatelessWidget {
  const _CornerTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: colors.infoSubtle,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label.toUpperCase(),
        style: YaText.sans(
          size: 9,
          height: 12,
          weight: FontWeight.w500,
          letterSpacing: 0.36, // 0.04em * 9
        ).copyWith(color: colors.info),
      ),
    );
  }
}

class _ThemeToggleButton extends StatefulWidget {
  const _ThemeToggleButton({this.onTap});
  final VoidCallback? onTap;

  @override
  State<_ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<_ThemeToggleButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovering ? colors.bgSubtle : Colors.transparent,
            borderRadius: YaRadius.brXs,
          ),
          child: Icon(
            LucideIcons.sun,
            size: 14,
            color: _hovering ? colors.textPrimary : colors.textMuted,
          ),
        ),
      ),
    );
  }
}

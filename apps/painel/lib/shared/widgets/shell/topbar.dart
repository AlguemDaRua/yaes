// Tradução fiel de _design/showcases/dashboard-shell.jsx (header da composição).
// Spec: _design/components.md §3.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme_mode_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';
import '../forms/ya_avatar.dart';

/// Topbar do shell: 56px sticky.
///
/// Esquerda: search global (Cmd+K). Direita: DEV pill, theme toggle,
/// notificações, user menu (separado por border-left).
class Topbar extends ConsumerWidget {
  const Topbar({
    required this.userName,
    this.userEmail,
    this.isDev = false,
    this.onSearch,
    this.searchField,
    this.notificationsCount = 0,
    this.onNotifications,
    this.onLogout,
    super.key,
  });

  final String userName;
  final String? userEmail;
  final bool isDev;
  final VoidCallback? onSearch;

  /// Campo de pesquisa customizado (ex.: pesquisa inline com dropdown). Quando
  /// fornecido, substitui a caixa estática que dispara [onSearch].
  final Widget? searchField;
  final int notificationsCount;
  final VoidCallback? onNotifications;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = YaColors.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final S s = S.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth.isFinite && constraints.maxWidth < 540;

        return Container(
          height: YaDimensions.topbarHeight,
          decoration: BoxDecoration(
            color: colors.bgSurface,
            border: Border(bottom: BorderSide(color: colors.borderSubtle)),
          ),
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 24),
          child: Row(
            children: [
              if (compact)
                _IconButton(
                  icon: LucideIcons.search,
                  tooltip: s.commonSearch,
                  onTap: onSearch ?? () {},
                  colors: colors,
                )
              else
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: SizedBox(
                        height: 36,
                        child: searchField ??
                            _SearchField(onTap: onSearch, colors: colors),
                      ),
                    ),
                  ),
                ),
              if (compact) const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDev && !compact) ...[
                    _DevPill(colors: colors),
                    const SizedBox(width: 12),
                  ],
                  _IconButton(
                    icon: themeMode == ThemeMode.dark
                        ? LucideIcons.sun
                        : LucideIcons.moon,
                    tooltip: s.commonChangeTheme,
                    onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                    colors: colors,
                  ),
                  const SizedBox(width: 8),
                  _NotificationsBell(
                    count: notificationsCount,
                    onTap: onNotifications,
                    colors: colors,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 24,
                    width: 1,
                    color: colors.borderSubtle,
                  ),
                  const SizedBox(width: 8),
                  _UserMenu(
                    name: userName,
                    email: userEmail,
                    onLogout: onLogout,
                    colors: colors,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap, required this.colors});
  final VoidCallback? onTap;
  final YaColors colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colors.bgBase,
          borderRadius: YaRadius.brMd,
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.search, size: 14, color: colors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                S.of(context).commonSearch,
                style: YaText.sm.copyWith(color: colors.textMuted),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.bgSubtle,
                borderRadius: YaRadius.brXs,
              ),
              child: Text(
                '⌘K',
                style: YaText.mono(size: 10, height: 14)
                    .copyWith(color: colors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DevPill extends StatelessWidget {
  const _DevPill({required this.colors});
  final YaColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.warningSubtle,
        borderRadius: YaRadius.brFull,
      ),
      child: Text(
        'DEV',
        style: YaText.sans(
          size: 10,
          height: 14,
          weight: FontWeight.w500,
          letterSpacing: 0.4, // 0.04em * 10
        ).copyWith(color: colors.warning),
      ),
    );
  }
}

class _IconButton extends StatefulWidget {
  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.colors,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final YaColors colors;

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: YaDurations.micro,
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovering ? widget.colors.bgSubtle : Colors.transparent,
              borderRadius: YaRadius.brMd,
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: widget.colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsBell extends StatefulWidget {
  const _NotificationsBell({
    required this.count,
    required this.colors,
    this.onTap,
  });
  final int count;
  final YaColors colors;
  final VoidCallback? onTap;

  @override
  State<_NotificationsBell> createState() => _NotificationsBellState();
}

class _NotificationsBellState extends State<_NotificationsBell> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: S.of(context).commonNotifications,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap ?? () {},
          child: AnimatedContainer(
            duration: YaDurations.micro,
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _hovering ? widget.colors.bgSubtle : Colors.transparent,
              borderRadius: YaRadius.brMd,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  LucideIcons.bell,
                  size: 16,
                  color: widget.colors.textSecondary,
                ),
                if (widget.count > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: widget.colors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.colors.bgSurface,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserMenu extends StatelessWidget {
  const _UserMenu({
    required this.name,
    required this.email,
    required this.onLogout,
    required this.colors,
  });

  final String name;
  final String? email;
  final VoidCallback? onLogout;
  final YaColors colors;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: name,
      offset: const Offset(0, 40),
      color: colors.bgElevated,
      shape: RoundedRectangleBorder(
        borderRadius: YaRadius.brMd,
        side: BorderSide(color: colors.borderSubtle),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: YaText.smMedium.copyWith(color: colors.textPrimary),
                ),
                if (email != null)
                  Text(
                    email!,
                    style: YaText.xs.copyWith(color: colors.textMuted),
                  ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'profile',
          child: Text(S.of(context).commonProfile, style: YaText.sm),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Text(S.of(context).commonSettings, style: YaText.sm),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Text(
            S.of(context).commonExit,
            style: YaText.sm.copyWith(color: colors.danger),
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'logout') onLogout?.call();
      },
      child: YaAvatar.fromName(name, size: 28),
    );
  }
}

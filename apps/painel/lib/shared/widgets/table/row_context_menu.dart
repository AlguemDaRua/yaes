import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';

/// Item de [RowContextMenu].
class YaMenuItem {
  const YaMenuItem({
    required this.label,
    this.icon,
    this.onTap,
    this.destructive = false,
    this.disabled = false,
    this.shortcut,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool destructive;
  final bool disabled;
  final String? shortcut;
}

/// Separador entre grupos de items.
class YaMenuDivider {
  const YaMenuDivider();
}

/// Botao de mais opcoes que abre um menu contextual da linha.
class RowContextMenu extends StatelessWidget {
  const RowContextMenu({required this.items, super.key});

  final List<Object> items;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return PopupMenuButton<VoidCallback>(
      icon: Icon(
        LucideIcons.ellipsis,
        size: 16,
        color: colors.textSecondary,
      ),
      padding: EdgeInsets.zero,
      offset: const Offset(0, 28),
      color: colors.bgElevated,
      shape: RoundedRectangleBorder(
        borderRadius: YaRadius.brMd,
        side: BorderSide(color: colors.borderSubtle),
      ),
      elevation: 0,
      itemBuilder: (context) {
        final entries = <PopupMenuEntry<VoidCallback>>[];
        for (final item in items) {
          if (item is YaMenuDivider) {
            entries.add(const PopupMenuDivider(height: 1));
          } else if (item is YaMenuItem) {
            entries.add(_buildItem(context, item));
          }
        }
        return entries;
      },
      onSelected: (callback) => callback(),
    );
  }

  PopupMenuItem<VoidCallback> _buildItem(
    BuildContext context,
    YaMenuItem item,
  ) {
    final colors = YaColors.of(context);
    final fg = item.destructive
        ? colors.danger
        : item.disabled
            ? colors.textDisabled
            : colors.textPrimary;

    return PopupMenuItem<VoidCallback>(
      enabled: !item.disabled,
      value: item.onTap ?? () {},
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Opacity(
        opacity: item.disabled ? 0.4 : 1.0,
        child: Row(
          children: [
            if (item.icon != null) ...[
              Icon(item.icon, size: 14, color: fg),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(item.label, style: YaText.sm.copyWith(color: fg)),
            ),
            if (item.shortcut != null)
              Text(
                item.shortcut!,
                style: YaText.monoSm.copyWith(color: colors.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}

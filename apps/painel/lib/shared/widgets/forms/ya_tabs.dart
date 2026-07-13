// Tradução fiel de _design/showcases/auxiliaries.jsx (componente Tabs).

import 'package:flutter/material.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';

/// Item de uma [YaTabs].
class YaTabItem {
  const YaTabItem({required this.label, this.count});
  final String label;
  final int? count;
}

/// Tabs estilo underline: borda 2px brand sob o tab activo, label brand,
/// border-bottom 1px subtle no container. Count opcional (cinzento, mono).
class YaTabs extends StatelessWidget {
  const YaTabs({
    required this.items,
    required this.activeIndex,
    this.onChanged,
    super.key,
  });

  final List<YaTabItem> items;
  final int activeIndex;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabs = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < items.length; i++)
                _Tab(
                  item: items[i],
                  active: i == activeIndex,
                  onTap: onChanged == null ? null : () => onChanged!(i),
                ),
            ],
          ),
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colors.borderSubtle),
            ),
          ),
          child: constraints.maxWidth.isFinite
              ? SizedBox(width: constraints.maxWidth, child: tabs)
              : tabs,
        );
      },
    );
  }
}

class _Tab extends StatefulWidget {
  const _Tab({required this.item, required this.active, this.onTap});
  final YaTabItem item;
  final bool active;
  final VoidCallback? onTap;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  bool _hovering = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final fg = widget.active
        ? colors.brand
        : (_hovering ? colors.textPrimary : colors.textSecondary);
    final indicator = widget.active ? colors.brand : Colors.transparent;
    final bgColor = widget.active
        ? Colors.transparent
        : (_hovering ? colors.bgSubtle : Colors.transparent);

    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: MouseRegion(
        cursor: widget.onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: YaDurations.micro,
            // marginBottom: -1 no JSX → sobrepor a borda inferior do container
            transform: Matrix4.translationValues(0, 1, 0),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: _focused ? YaRadius.brXs : null,
              boxShadow: _focused ? YaShadows.focusBrand : YaShadows.none,
              border: Border(
                bottom: BorderSide(color: indicator, width: 2),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: YaSpacing.lg,
              vertical: YaSpacing.sm,
            ),
            constraints: const BoxConstraints(minHeight: 36),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.item.label,
                  style: YaText.smMedium.copyWith(color: fg),
                ),
                if (widget.item.count != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '(${widget.item.count})',
                    style: YaText.mono(size: 12, height: 16)
                        .copyWith(color: colors.textMuted),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

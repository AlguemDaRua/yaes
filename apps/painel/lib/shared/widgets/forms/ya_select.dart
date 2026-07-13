// Tradução fiel de _design/showcases/auxiliaries.jsx (componente DropdownPreview).

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';

/// Item de uma [YaSelect].
class YaSelectItem<T> {
  const YaSelectItem({required this.value, required this.label});
  final T value;
  final String label;
}

/// Select customizado YA: trigger 32px com chevron, popup `bg-elevated` com
/// items `padding 8/10 radius 4`. Item selecionado tem `brand-subtle`/`brand`
/// e tick à direita.
class YaSelect<T> extends StatefulWidget {
  const YaSelect({
    required this.items,
    required this.value,
    required this.onChanged,
    this.width = 240,
    this.placeholder = 'Selecionar',
    super.key,
  });

  final List<YaSelectItem<T>> items;
  final T? value;
  final ValueChanged<T> onChanged;
  final double width;
  final String placeholder;

  @override
  State<YaSelect<T>> createState() => _YaSelectState<T>();
}

class _YaSelectState<T> extends State<YaSelect<T>> {
  final MenuController _controller = MenuController();
  final TextEditingController _searchController = TextEditingController();
  bool _open = false;
  String _search = '';

  bool get _searchable => widget.items.length >= 10;

  List<YaSelectItem<T>> get _filteredItems {
    if (!_searchable || _search.isEmpty) return widget.items;
    final q = _search.toLowerCase();
    return widget.items
        .where((i) => i.label.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final selected = widget.value == null
        ? null
        : widget.items.firstWhere(
            (i) => i.value == widget.value,
            orElse: () => YaSelectItem(
              value: widget.value as T,
              label: widget.placeholder,
            ),
          );

    return MenuAnchor(
      controller: _controller,
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(colors.bgElevated),
        elevation: const WidgetStatePropertyAll(0),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(YaSpacing.xs)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: YaRadius.brMd,
            side: BorderSide(color: colors.borderSubtle),
          ),
        ),
      ),
      menuChildren: [
        if (_searchable)
          _SelectSearch(
            controller: _searchController,
            width: widget.width - 8,
            onChanged: (v) => setState(() => _search = v),
          ),
        for (final item in _filteredItems)
          _SelectItem<T>(
            item: item,
            selected: item.value == widget.value,
            width: widget.width - 8,
            onTap: () {
              widget.onChanged(item.value);
              _controller.close();
            },
          ),
        if (_searchable && _filteredItems.isEmpty)
          _SelectEmpty(width: widget.width - 8),
      ],
      onOpen: () => setState(() => _open = true),
      onClose: () => setState(() {
        _open = false;
        _search = '';
        _searchController.clear();
      }),
      builder: (context, controller, _) {
        return SizedBox(
          width: widget.width,
          child: _Trigger(
            label: selected?.label ?? widget.placeholder,
            isPlaceholder: widget.value == null,
            open: _open,
            onTap: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
          ),
        );
      },
    );
  }
}

class _Trigger extends StatefulWidget {
  const _Trigger({
    required this.label,
    required this.isPlaceholder,
    required this.open,
    required this.onTap,
  });
  final String label;
  final bool isPlaceholder;
  final bool open;
  final VoidCallback onTap;

  @override
  State<_Trigger> createState() => _TriggerState();
}

class _TriggerState extends State<_Trigger> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final borderColor = widget.open
        ? colors.brandBorder
        : (_hovering ? colors.borderDefault : colors.borderSubtle);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: YaDurations.micro,
          height: YaDimensions.inputHeight,
          padding: const EdgeInsets.symmetric(horizontal: YaSpacing.md),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: YaRadius.brMd,
            border: Border.all(color: borderColor),
            boxShadow: YaShadows.none,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: YaText.sm.copyWith(
                    color: widget.isPlaceholder
                        ? colors.textMuted
                        : colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectItem<T> extends StatefulWidget {
  const _SelectItem({
    required this.item,
    required this.selected,
    required this.width,
    required this.onTap,
  });
  final YaSelectItem<T> item;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  @override
  State<_SelectItem<T>> createState() => _SelectItemState<T>();
}

class _SelectItemState<T> extends State<_SelectItem<T>> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final selected = widget.selected;

    final Color bg;
    final Color fg;
    if (selected) {
      bg = _hovering ? colors.brandSubtleHover : colors.brandSubtle;
      fg = colors.brand;
    } else {
      bg = _hovering ? colors.bgSubtle : Colors.transparent;
      fg = colors.textPrimary;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: YaRadius.brXs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.item.label,
                  style: YaText.sm.copyWith(color: fg),
                ),
              ),
              if (selected) Icon(LucideIcons.check, size: 12, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campo de pesquisa no topo do popup do select (aparece quando >= 10 itens).
class _SelectSearch extends StatelessWidget {
  const _SelectSearch({
    required this.controller,
    required this.width,
    required this.onChanged,
  });

  final TextEditingController controller;
  final double width;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
        child: SizedBox(
          height: YaDimensions.inputHeight,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: YaText.sm.copyWith(color: colors.textPrimary),
            cursorColor: colors.brand,
            decoration: InputDecoration(
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              hintText: 'Pesquisar...',
              hintStyle: YaText.sm.copyWith(color: colors.textMuted),
              filled: true,
              fillColor: colors.bgSurface,
              border: OutlineInputBorder(
                borderRadius: YaRadius.brMd,
                borderSide: BorderSide(color: colors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: YaRadius.brMd,
                borderSide: BorderSide(color: colors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: YaRadius.brMd,
                borderSide: BorderSide(color: colors.brandBorder),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mensagem "sem resultados" quando a pesquisa nao encontra nenhum item.
class _SelectEmpty extends StatelessWidget {
  const _SelectEmpty({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Text(
          'Sem resultados',
          style: YaText.sm.copyWith(color: colors.textMuted),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// Tradução fiel de _design/showcases/data-table.jsx (componente DataTable).
// Spec: _design/components.md §6.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';
import '../feedback/empty_state.dart';
import '../feedback/skeleton.dart';

enum YaTableDensity { comfortable, compact }

enum YaSortDirection { asc, desc }

/// Spec de uma coluna da [YaDataTable].
@immutable
class YaColumn<T> {
  const YaColumn({
    required this.key,
    required this.label,
    required this.cellBuilder,
    this.width,
    this.align = Alignment.centerLeft,
    this.sortable = false,
    this.skeletonWidth = 90,
  });

  /// Identificador estável para sort/seleção.
  final String key;

  /// Label do header (case-sensitive — uppercase é aplicado em render).
  final String label;

  /// Builder da célula a partir do row.
  final Widget Function(T row) cellBuilder;

  /// Largura fixa em pixels. Se null, coluna é flexível (ocupa espaço sobrante).
  final double? width;

  /// Alinhamento do conteúdo da célula.
  final Alignment align;

  final bool sortable;

  /// Largura da skeleton bar quando loading.
  final double skeletonWidth;
}

/// Estado de sort actual (qual coluna + direcção).
@immutable
class YaSortState {
  const YaSortState({required this.columnKey, required this.direction});
  final String columnKey;
  final YaSortDirection direction;
}

/// Tabela densa YA.
///
/// `T` é o tipo de cada row. Colunas são definidas via [YaColumn] e cada uma
/// tem o seu próprio `cellBuilder`. Suporta sort, hover, selecção, loading
/// (skeleton) e empty state.
class YaDataTable<T> extends StatefulWidget {
  const YaDataTable({
    required this.columns,
    required this.rows,
    required this.keyExtractor,
    this.density = YaTableDensity.comfortable,
    this.loading = false,
    this.selectable = false,
    this.selectedKeys = const {},
    this.onSelectChanged,
    this.sort,
    this.onSortChanged,
    this.onRowTap,
    this.onRowMore,
    this.emptyIcon = LucideIcons.inbox,
    this.emptyTitle,
    this.emptyDescription,
    this.footer,
    super.key,
  });

  final List<YaColumn<T>> columns;
  final List<T> rows;
  final String Function(T row) keyExtractor;
  final YaTableDensity density;
  final bool loading;
  final bool selectable;
  final Set<String> selectedKeys;
  final ValueChanged<Set<String>>? onSelectChanged;
  final YaSortState? sort;
  final ValueChanged<YaSortState>? onSortChanged;
  final void Function(T row)? onRowTap;
  final void Function(T row)? onRowMore;
  final IconData emptyIcon;
  final String? emptyTitle;
  final String? emptyDescription;

  /// Footer customizado (ex: paginação). Se null, não é renderizado.
  final Widget? footer;

  @override
  State<YaDataTable<T>> createState() => _YaDataTableState<T>();
}

class _YaDataTableState<T> extends State<YaDataTable<T>> {
  String? _hoveredKey;

  double get _rowHeight => widget.density == YaTableDensity.compact
      ? YaDimensions.tableRowHeightCompact
      : YaDimensions.tableRowHeight;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isEmpty = !widget.loading && widget.rows.isEmpty;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: YaRadius.brLg,
        border: Border.all(color: colors.borderSubtle),
        boxShadow: isLight ? YaShadows.sm : YaShadows.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = _preferredTableWidth(constraints.maxWidth);

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(colors),
                  if (widget.loading)
                    ...List.generate(
                      5,
                      (i) => _buildSkeletonRow(colors, isLast: i == 4),
                    )
                  else if (isEmpty)
                    _buildEmpty()
                  else
                    ...List.generate(widget.rows.length, (i) {
                      final row = widget.rows[i];
                      return _buildRow(
                        colors,
                        row,
                        isLast: i == widget.rows.length - 1,
                      );
                    }),
                  if (widget.footer != null) ...[
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: colors.borderSubtle,
                    ),
                    widget.footer!,
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double _preferredTableWidth(double availableWidth) {
    var width = 0.0;
    if (widget.selectable) width += 36;
    if (widget.onRowMore != null) width += 36;

    for (final col in widget.columns) {
      width += col.width ?? 180;
    }

    if (!availableWidth.isFinite || availableWidth <= 0) {
      return width;
    }

    return width < availableWidth ? availableWidth : width;
  }

  Widget _buildHeader(YaColors colors) {
    return Container(
      height: YaDimensions.tableHeaderHeight,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        children: [
          if (widget.selectable) _selectAllCell(colors),
          for (final col in widget.columns) _headerCell(col, colors),
          if (widget.onRowMore != null)
            const SizedBox(width: 36), // espaço para a coluna de "mais"
        ],
      ),
    );
  }

  Widget _selectAllCell(YaColors colors) {
    final allSelected = widget.rows.isNotEmpty &&
        widget.rows.every(
          (r) => widget.selectedKeys.contains(widget.keyExtractor(r)),
        );
    final someSelected = !allSelected &&
        widget.rows.any(
          (r) => widget.selectedKeys.contains(widget.keyExtractor(r)),
        );

    return SizedBox(
      width: 36,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Checkbox(
          value: allSelected ? true : (someSelected ? null : false),
          tristate: true,
          activeColor: colors.brand,
          onChanged: (_) {
            final next = <String>{};
            if (!allSelected) {
              next.addAll(widget.rows.map(widget.keyExtractor));
            }
            widget.onSelectChanged?.call(next);
          },
        ),
      ),
    );
  }

  Widget _headerCell(YaColumn<T> col, YaColors colors) {
    final isSorted = widget.sort?.columnKey == col.key;
    final dir = isSorted ? widget.sort!.direction : null;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: col.align == Alignment.centerRight
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              col.label.toUpperCase(),
              style: YaText.sans(
                size: 11,
                height: 14,
                weight: FontWeight.w500,
                letterSpacing: 0.22, // 0.02em * 11
              ).copyWith(color: colors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (col.sortable) ...[
            const SizedBox(width: 4),
            Opacity(
              opacity: isSorted ? 1.0 : 0.5,
              child: Icon(
                dir == YaSortDirection.asc
                    ? LucideIcons.chevronUp
                    : LucideIcons.chevronDown,
                size: 12,
                color: isSorted ? colors.textPrimary : colors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );

    final cell = col.sortable
        ? MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                final newDir = (isSorted && dir == YaSortDirection.asc)
                    ? YaSortDirection.desc
                    : YaSortDirection.asc;
                widget.onSortChanged?.call(
                  YaSortState(columnKey: col.key, direction: newDir),
                );
              },
              child: content,
            ),
          )
        : content;

    return _wrapColumn(col, cell);
  }

  Widget _buildRow(YaColors colors, T row, {required bool isLast}) {
    final key = widget.keyExtractor(row);
    final isSelected = widget.selectedKeys.contains(key);
    final isHover = _hoveredKey == key;

    final Color bg;
    if (isSelected) {
      bg = colors.brandSubtle;
    } else if (isHover) {
      bg = colors.bgSubtle;
    } else {
      bg = Colors.transparent;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredKey = key),
      onExit: (_) => setState(() => _hoveredKey = null),
      child: GestureDetector(
        onTap: widget.onRowTap == null ? null : () => widget.onRowTap!(row),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: _rowHeight,
          decoration: BoxDecoration(
            color: bg,
            border: isLast
                ? null
                : Border(bottom: BorderSide(color: colors.borderSubtle)),
          ),
          child: Row(
            children: [
              if (widget.selectable) _selectRowCell(colors, key, isSelected),
              for (final col in widget.columns)
                _wrapColumn(col, _bodyCell(col, row)),
              if (widget.onRowMore != null) _moreCell(colors, row, isHover),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectRowCell(YaColors colors, String key, bool isSelected) {
    return SizedBox(
      width: 36,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Checkbox(
          value: isSelected,
          activeColor: colors.brand,
          onChanged: (v) {
            final next = {...widget.selectedKeys};
            if (v ?? false) {
              next.add(key);
            } else {
              next.remove(key);
            }
            widget.onSelectChanged?.call(next);
          },
        ),
      ),
    );
  }

  Widget _bodyCell(YaColumn<T> col, T row) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Align(alignment: col.align, child: col.cellBuilder(row)),
    );
  }

  Widget _moreCell(YaColors colors, T row, bool isHover) {
    return SizedBox(
      width: 36,
      child: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: isHover ? 1.0 : 0.5,
          child: GestureDetector(
            onTap: () => widget.onRowMore?.call(row),
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isHover ? colors.bgElevated : Colors.transparent,
                borderRadius: YaRadius.brMd,
              ),
              child: Icon(
                LucideIcons.ellipsis,
                size: 16,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonRow(YaColors colors, {required bool isLast}) {
    return Container(
      height: _rowHeight,
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        children: [
          if (widget.selectable)
            const SizedBox(
              width: 36,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Skeleton(width: 14, height: 14, radius: 3),
              ),
            ),
          for (final col in widget.columns)
            _wrapColumn(
              col,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: col.align,
                  child: _skeletonForColumn(col),
                ),
              ),
            ),
          if (widget.onRowMore != null) const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _skeletonForColumn(YaColumn<T> col) {
    if (col.key == 'driver' || col.key == 'person') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Skeleton.circle(size: 28),
          const SizedBox(width: 10),
          const Skeleton(width: 110, height: 12),
        ],
      );
    }
    if (col.key == 'status') {
      return const Skeleton(width: 78, height: 22, radius: 9999);
    }
    return Skeleton(width: col.skeletonWidth, height: 12);
  }

  Widget _buildEmpty() {
    final strings = S.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: EmptyState(
        icon: widget.emptyIcon,
        title: widget.emptyTitle ?? strings.commonNoData,
        description: widget.emptyDescription ?? strings.commonNoData,
      ),
    );
  }

  Widget _wrapColumn(YaColumn<T> col, Widget child) {
    if (col.width != null) {
      return SizedBox(width: col.width, child: child);
    }
    return Expanded(child: child);
  }
}

/// Footer de paginação para [YaDataTable]. JSX usa botões `‹‹ ‹ 1 2 3 › ››`.
class YaTablePagination extends StatelessWidget {
  const YaTablePagination({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChange,
    this.summary,
    super.key,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChange;

  /// Texto à esquerda (ex: "A mostrar 1–5 de 247").
  final String? summary;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: YaSpacing.lg,
        vertical: YaSpacing.md,
      ),
      color: colors.bgSurface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth.isFinite && constraints.maxWidth < 520;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summary(colors),
                const SizedBox(height: YaSpacing.sm),
                _controls(colors),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _summary(colors)),
              _controls(colors),
            ],
          );
        },
      ),
    );
  }

  Widget _summary(YaColors colors) {
    return Text(
      summary ?? '',
      style: YaText.sans(size: 12, height: 16)
          .copyWith(color: colors.textSecondary),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _controls(YaColors colors) {
    return Wrap(
      spacing: YaSpacing.xs,
      runSpacing: YaSpacing.xs,
      children: [
        _pageBtn(colors, '‹‹', currentPage > 1, () => onPageChange(1)),
        _pageBtn(
          colors,
          '‹',
          currentPage > 1,
          () => onPageChange(currentPage - 1),
        ),
        for (final p in _visiblePages())
          _pageBtn(
            colors,
            p.toString(),
            true,
            () => onPageChange(p),
            active: p == currentPage,
          ),
        _pageBtn(
          colors,
          '›',
          currentPage < totalPages,
          () => onPageChange(currentPage + 1),
        ),
        _pageBtn(
          colors,
          '››',
          currentPage < totalPages,
          () => onPageChange(totalPages),
        ),
      ],
    );
  }

  /// Páginas a mostrar (max 3 à volta da actual).
  List<int> _visiblePages() {
    if (totalPages <= 5) {
      return [for (var i = 1; i <= totalPages; i++) i];
    }
    final start = (currentPage - 1).clamp(1, totalPages - 2);
    return [start, start + 1, start + 2];
  }

  Widget _pageBtn(
    YaColors colors,
    String label,
    bool enabled,
    VoidCallback onTap, {
    bool active = false,
  }) {
    return _PageButton(
      label: label,
      enabled: enabled,
      onTap: onTap,
      active: active,
    );
  }
}

class _PageButton extends StatefulWidget {
  const _PageButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.active,
  });
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool active;

  @override
  State<_PageButton> createState() => _PageButtonState();
}

class _PageButtonState extends State<_PageButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final active = widget.active;
    final enabled = widget.enabled;

    final Color bg;
    final Color fg;
    if (active) {
      bg = colors.brandSubtle;
      fg = colors.brand;
    } else if (!enabled) {
      bg = Colors.transparent;
      fg = colors.textDisabled;
    } else if (_hovering) {
      bg = colors.bgSubtle;
      fg = colors.textPrimary;
    } else {
      bg = Colors.transparent;
      fg = colors.textSecondary;
    }

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) {
        if (enabled) setState(() => _hovering = true);
      },
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: enabled ? widget.onTap : null,
        child: Container(
          height: 28,
          constraints: const BoxConstraints(minWidth: 28),
          padding: const EdgeInsets.symmetric(horizontal: YaSpacing.sm),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: YaRadius.brMd,
          ),
          child: Text(
            widget.label,
            style: YaText.sans(
              size: 12,
              height: 16,
              weight: active ? FontWeight.w500 : FontWeight.w400,
            ).copyWith(color: fg),
          ),
        ),
      ),
    );
  }
}

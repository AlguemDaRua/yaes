import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/typography.dart';

/// Item de breadcrumb. Se [route] for null, item não é clicável (página actual).
@immutable
class BreadcrumbItem {
  const BreadcrumbItem({required this.label, this.route});
  final String label;
  final String? route;
}

/// Header padrão de cada página — ya-components §4.
///
/// Layout flex space-between: título+descrição à esquerda, actions à direita.
/// Tabs opcionais aparecem por baixo (sticky em scroll quando colocado dentro
/// de um SliverPersistentHeader).
class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    this.description,
    this.breadcrumb,
    this.actions = const [],
    this.tabs,
    super.key,
  });

  final String title;
  final String? description;
  final List<BreadcrumbItem>? breadcrumb;
  final List<Widget> actions;
  final Widget? tabs;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (breadcrumb != null && breadcrumb!.isNotEmpty)
          _Breadcrumb(items: breadcrumb!, colors: colors),
        Text(
          title,
          style: YaText.xxl.copyWith(color: colors.textPrimary),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: YaText.sm.copyWith(color: colors.textSecondary),
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linha superior — flex space-between
        LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth.isFinite && constraints.maxWidth < 640;

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleBlock,
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: actions,
                    ),
                  ],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: titleBlock),
                if (actions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: actions,
                    ),
                  ),
              ],
            );
          },
        ),
        if (tabs != null) ...[
          const SizedBox(height: 16),
          tabs!,
        ],
      ],
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.items, required this.colors});
  final List<BreadcrumbItem> items;
  final YaColors colors;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final isLast = i == items.length - 1;
      final item = items[i];

      children.add(
        item.route == null
            ? Text(
                item.label,
                style: YaText.sm.copyWith(
                  color: isLast ? colors.textSecondary : colors.textMuted,
                ),
              )
            : MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    // Navegação delegada — usar GoRouter no caller
                    Navigator.of(context).pushNamed(item.route!);
                  },
                  child: Text(
                    item.label,
                    style: YaText.sm.copyWith(color: colors.textMuted),
                  ),
                ),
              ),
      );

      if (!isLast) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            LucideIcons.chevronRight,
            size: 12,
            color: colors.textMuted,
          ),
        ),);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';

class DetailHeader extends StatelessWidget {
  const DetailHeader({
    required this.name,
    required this.actions,
    this.statusBadge,
    this.subtitle,
    this.meta,
    this.banner,
    this.breadcrumb,
    this.tabs,
    super.key,
  });

  final String name;
  final Widget? statusBadge;
  final String? subtitle;
  final String? meta;
  final Widget? banner;
  final Widget? breadcrumb;
  final Widget? tabs;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (banner != null) ...[banner!, const SizedBox(height: YaSpacing.md)],
        if (breadcrumb != null) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: breadcrumb!,
          ),
          const SizedBox(height: YaSpacing.sm),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth.isFinite && constraints.maxWidth < 640;
            final titleBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: YaSpacing.sm,
                  runSpacing: YaSpacing.sm,
                  children: [
                    Text(
                      name,
                      style: YaText.xxl.copyWith(color: colors.textPrimary),
                    ),
                    if (statusBadge != null) statusBadge!,
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: YaText.sm.copyWith(color: colors.textSecondary),
                  ),
                ],
                if (meta != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    meta!,
                    style: YaText.sans(size: 12, height: 16)
                        .copyWith(color: colors.textMuted),
                  ),
                ],
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleBlock,
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: YaSpacing.md),
                    Wrap(
                      spacing: YaSpacing.sm,
                      runSpacing: YaSpacing.sm,
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
                  Wrap(
                    spacing: YaSpacing.sm,
                    runSpacing: YaSpacing.sm,
                    children: actions,
                  ),
              ],
            );
          },
        ),
        if (tabs != null) ...[const SizedBox(height: YaSpacing.lg), tabs!],
        const SizedBox(height: YaSpacing.xxl),
        Divider(height: 1, color: colors.borderSubtle),
      ],
    );
  }
}

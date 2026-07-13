// Tradução fiel de _design/showcases/kpi-card.jsx (componente KpiCard).

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';
import '../feedback/skeleton.dart';

/// Direcção da seta do trend.
enum TrendDirection { up, down, flat }

/// Significado semântico do trend (pode divergir da direcção:
/// "cancelamentos descem" = down + positive).
enum TrendSemantic { positive, negative, neutral }

/// Trend visual num [KpiCard].
@immutable
class KpiTrend {
  const KpiTrend({
    required this.value,
    required this.direction,
    required this.semantic,
    required this.label,
  });

  /// Texto do trend (ex: "+18,4%", "−3,2%", "0,0%")
  final String value;
  final TrendDirection direction;
  final TrendSemantic semantic;

  /// Contexto (ex: "vs Abril", "este mês")
  final String label;
}

enum KpiCardVariant { standard, highlighted }

/// Card de KPI: label uppercase, valor grande em Newsreader, trend opcional.
///
/// Spec: _design/components.md §5.
class KpiCard extends StatefulWidget {
  const KpiCard({
    required this.label,
    required this.value,
    this.valueSuffix,
    this.trend,
    this.icon,
    this.onTap,
    this.variant = KpiCardVariant.standard,
    this.loading = false,
    this.empty = false,
    super.key,
  });

  final String label;

  /// Valor já formatado. Ex: "2 847 320", "4,1"
  final String value;

  /// Sufixo inline ao lado do valor. Ex: "MTn", "%", "/ 1 380"
  final String? valueSuffix;

  final KpiTrend? trend;
  final IconData? icon;
  final VoidCallback? onTap;
  final KpiCardVariant variant;
  final bool loading;

  /// Se true, mostra "—" em text-muted no lugar do valor.
  final bool empty;

  @override
  State<KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<KpiCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    if (widget.loading) {
      return _LoadingCard(isLight: isLight);
    }

    final isHighlighted = widget.variant == KpiCardVariant.highlighted;
    final canTap = widget.onTap != null;

    final card = AnimatedContainer(
      duration: YaDurations.micro,
      curve: YaDurations.easeOut,
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
      decoration: BoxDecoration(
        color: _hovering && canTap ? colors.bgElevated : colors.bgSurface,
        borderRadius: YaRadius.brLg,
        border: Border.all(
          color: isHighlighted ? colors.brandBorder : colors.borderSubtle,
          width: isHighlighted ? 1.5 : 1,
        ),
        boxShadow: isLight ? YaShadows.sm : YaShadows.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLabelRow(colors),
          const SizedBox(height: YaSpacing.sm),
          _buildValueRow(colors),
          const SizedBox(height: 6),
          _buildTrendRow(colors),
        ],
      ),
    );

    if (!canTap) return card;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: card,
      ),
    );
  }

  Widget _buildLabelRow(YaColors colors) {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.label.toUpperCase(),
            style: YaText.eyebrowKpi.copyWith(color: colors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.icon != null)
          Icon(widget.icon, size: 14, color: colors.textMuted),
      ],
    );
  }

  Widget _buildValueRow(YaColors colors) {
    final empty = widget.empty;
    final valueColor = empty ? colors.textMuted : colors.textPrimary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            empty ? '—' : widget.value,
            style: YaText.serif(
              size: 26,
              // JSX: lineHeight 1.1 → 26 * 1.1 ≈ 28.6
              height: 28.6,
              letterSpacing: -0.39, // -0.015em * 26
              weight: FontWeight.w500,
            ).copyWith(
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!empty && widget.valueSuffix != null) ...[
          const SizedBox(width: YaSpacing.xs),
          Text(
            widget.valueSuffix!,
            style: YaText.serif(size: 14, height: 22)
                .copyWith(color: colors.textMuted),
          ),
        ],
      ],
    );
  }

  Widget _buildTrendRow(YaColors colors) {
    if (widget.trend == null || widget.empty) {
      // JSX renderiza `<div style={{ height: 11 }} />` para reservar espaço
      return const SizedBox(height: 11);
    }
    final trend = widget.trend!;
    final color = _trendColor(trend, colors);

    final icon = switch (trend.direction) {
      TrendDirection.up => LucideIcons.arrowUp,
      TrendDirection.down => LucideIcons.arrowDown,
      TrendDirection.flat => LucideIcons.arrowRight,
    };

    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          trend.value,
          style: YaText.sans(size: 11, height: 14, weight: FontWeight.w500)
              .copyWith(color: color),
        ),
        const SizedBox(width: YaSpacing.xs),
        Flexible(
          child: Text(
            trend.label,
            style: YaText.sans(size: 11, height: 14)
                .copyWith(color: colors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// JSX: cor depende apenas de `semantic` (não de direction).
  Color _trendColor(KpiTrend trend, YaColors colors) {
    return switch (trend.semantic) {
      TrendSemantic.positive => colors.success,
      TrendSemantic.negative => colors.danger,
      TrendSemantic.neutral => colors.neutral,
    };
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.isLight});
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: YaRadius.brLg,
        border: Border.all(color: colors.borderSubtle),
        boxShadow: isLight ? YaShadows.sm : YaShadows.none,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // JSX: 60x11 marginBottom 12
          Skeleton(width: 60, height: 11),
          SizedBox(height: 12),
          // JSX: 110x26 marginBottom 10
          Skeleton(width: 110, height: 26),
          SizedBox(height: 10),
          // JSX: 80x11
          Skeleton(width: 80, height: 11),
        ],
      ),
    );
  }
}

/// Linha (row) de KpiCards. Por defeito 4 colunas em grid responsivo.
class KpiRow extends StatelessWidget {
  const KpiRow({
    required this.children,
    this.columns = 4,
    this.gap = YaSpacing.md,
    super.key,
  });

  final List<Widget> children;
  final int columns;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (!maxWidth.isFinite || maxWidth <= 0) {
          return const SizedBox.shrink();
        }

        // Reduz columns em viewports estreitos (< 720 = 2 cols).
        final effectiveColumns =
            maxWidth < 360 ? 1 : (maxWidth < 720 ? 2 : columns.clamp(1, 4));
        final rawColumnWidth =
            (maxWidth - (effectiveColumns - 1) * gap) / effectiveColumns;
        final columnWidth = rawColumnWidth.clamp(0.0, maxWidth).toDouble();

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map((c) => SizedBox(width: columnWidth, child: c))
              .toList(),
        );
      },
    );
  }
}

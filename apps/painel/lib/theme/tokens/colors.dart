import 'package:flutter/material.dart';

/// Paleta semântica YA — corresponde a foundations §3.
///
/// Sempre referenciada via [YaColors.of(context)], que devolve o conjunto
/// correcto consoante o tema activo. Nunca usar hex codes directamente em
/// widgets.
@immutable
class YaColors extends ThemeExtension<YaColors> {
  const YaColors({
    required this.bgBase,
    required this.bgSurface,
    required this.bgElevated,
    required this.bgSubtle,
    required this.bgOverlay,
    required this.borderSubtle,
    required this.borderDefault,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.textInverse,
    required this.brand,
    required this.brandHover,
    required this.brandActive,
    required this.brandSubtle,
    required this.brandSubtleHover,
    required this.brandBorder,
    required this.success,
    required this.successSubtle,
    required this.successBorder,
    required this.warning,
    required this.warningSubtle,
    required this.warningBorder,
    required this.danger,
    required this.dangerSubtle,
    required this.dangerBorder,
    required this.info,
    required this.infoSubtle,
    required this.infoBorder,
    required this.neutral,
    required this.neutralSubtle,
    required this.neutralBorder,
    required this.chartSeries,
  });

  // Backgrounds & superfícies
  final Color bgBase;
  final Color bgSurface;
  final Color bgElevated;
  final Color bgSubtle;
  final Color bgOverlay;

  // Borders
  final Color borderSubtle;
  final Color borderDefault;
  final Color borderStrong;

  // Texto
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color textInverse;

  // Brand (âmbar dourado)
  final Color brand;
  final Color brandHover;
  final Color brandActive;
  final Color brandSubtle;
  final Color brandSubtleHover;
  final Color brandBorder;

  // Semânticas
  final Color success;
  final Color successSubtle;
  final Color successBorder;

  final Color warning;
  final Color warningSubtle;
  final Color warningBorder;

  final Color danger;
  final Color dangerSubtle;
  final Color dangerBorder;

  final Color info;
  final Color infoSubtle;
  final Color infoBorder;

  final Color neutral;
  final Color neutralSubtle;
  final Color neutralBorder;

  // Sequência de cores para séries de gráficos categóricos (foundations §3.6)
  // [0] é a primária (brand), seguida por blue/success/purple/danger/cyan
  final List<Color> chartSeries;

  /// Light theme — foundations §3 colunas Light
  static const light = YaColors(
    bgBase: Color(0xFFFAFAF7),
    bgSurface: Color(0xFFFFFFFF),
    bgElevated: Color(0xFFF5F5F2),
    bgSubtle: Color(0xFFF0EFEA),
    bgOverlay: Color(0x66000000), // 40% black

    borderSubtle: Color(0xFFEAE7DF),
    borderDefault: Color(0xFFD4D0C5),
    borderStrong: Color(0xFFA8A39A),

    textPrimary: Color(0xFF1A1611),
    textSecondary: Color(0xFF5C574F),
    textMuted: Color(0xFF8B857B),
    textDisabled: Color(0xFFC5C0B5),
    textInverse: Color(0xFFFFFFFF),

    brand: Color(0xFFE5A400),
    brandHover: Color(0xFFC98E00),
    brandActive: Color(0xFFB27D00),
    brandSubtle: Color(0xFFFDF6E3),
    brandSubtleHover: Color(0xFFFAEED0),
    brandBorder: Color(0xFFF5B820),

    success: Color(0xFF0E8A5F),
    successSubtle: Color(0xFFE8F5EF),
    successBorder: Color(0xFF34D399),

    warning: Color(0xFFD97706),
    warningSubtle: Color(0xFFFEF3E2),
    warningBorder: Color(0xFFFB923C),

    danger: Color(0xFFDC2626),
    dangerSubtle: Color(0xFFFCE8E8),
    dangerBorder: Color(0xFFF87171),

    info: Color(0xFF2563EB),
    infoSubtle: Color(0xFFE5EDFD),
    infoBorder: Color(0xFF60A5FA),

    neutral: Color(0xFF737373),
    neutralSubtle: Color(0xFFF0EFEA),
    neutralBorder: Color(0xFFA3A3A3),

    chartSeries: [
      Color(0xFFE5A400), // brand
      Color(0xFF2563EB), // info
      Color(0xFF0E8A5F), // success
      Color(0xFF9333EA), // purple
      Color(0xFFDC2626), // danger
      Color(0xFF0891B2), // cyan
    ],
  );

  /// Dark theme — foundations §3 colunas Dark
  static const dark = YaColors(
    bgBase: Color(0xFF0E0D0B),
    bgSurface: Color(0xFF16140F),
    bgElevated: Color(0xFF1F1C16),
    bgSubtle: Color(0xFF221F19),
    bgOverlay: Color(0xB3000000), // 70% black

    borderSubtle: Color(0xFF2A2620),
    borderDefault: Color(0xFF3A352D),
    borderStrong: Color(0xFF5C574F),

    textPrimary: Color(0xFFF5F2EC),
    textSecondary: Color(0xFFA8A39A),
    textMuted: Color(0xFF6B665E),
    textDisabled: Color(0xFF3A352D),
    textInverse: Color(0xFF0E0D0B),

    brand: Color(0xFFF5B820),
    brandHover: Color(0xFFFFC940),
    brandActive: Color(0xFFE5A400),
    brandSubtle: Color(0xFF2A220E),
    brandSubtleHover: Color(0xFF3A2D0E),
    brandBorder: Color(0xFFF5B820),

    success: Color(0xFF34D399),
    successSubtle: Color(0xFF0F2A22),
    successBorder: Color(0xFF0E8A5F),

    warning: Color(0xFFFB923C),
    warningSubtle: Color(0xFF2A1A0C),
    warningBorder: Color(0xFFD97706),

    danger: Color(0xFFF87171),
    dangerSubtle: Color(0xFF2A1414),
    dangerBorder: Color(0xFFDC2626),

    info: Color(0xFF60A5FA),
    infoSubtle: Color(0xFF0C1A36),
    infoBorder: Color(0xFF2563EB),

    neutral: Color(0xFFA3A3A3),
    neutralSubtle: Color(0xFF221F19),
    neutralBorder: Color(0xFF5C574F),

    chartSeries: [
      Color(0xFFF5B820), // brand
      Color(0xFF60A5FA), // info
      Color(0xFF34D399), // success
      Color(0xFFC084FC), // purple
      Color(0xFFF87171), // danger
      Color(0xFF22D3EE), // cyan
    ],
  );

  /// Helper para obter as cores correctas via context.
  /// Uso: `final colors = YaColors.of(context);`
  static YaColors of(BuildContext context) {
    return Theme.of(context).extension<YaColors>()!;
  }

  @override
  YaColors copyWith({
    Color? bgBase,
    Color? bgSurface,
    Color? bgElevated,
    Color? bgSubtle,
    Color? bgOverlay,
    Color? borderSubtle,
    Color? borderDefault,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDisabled,
    Color? textInverse,
    Color? brand,
    Color? brandHover,
    Color? brandActive,
    Color? brandSubtle,
    Color? brandSubtleHover,
    Color? brandBorder,
    Color? success,
    Color? successSubtle,
    Color? successBorder,
    Color? warning,
    Color? warningSubtle,
    Color? warningBorder,
    Color? danger,
    Color? dangerSubtle,
    Color? dangerBorder,
    Color? info,
    Color? infoSubtle,
    Color? infoBorder,
    Color? neutral,
    Color? neutralSubtle,
    Color? neutralBorder,
    List<Color>? chartSeries,
  }) {
    return YaColors(
      bgBase: bgBase ?? this.bgBase,
      bgSurface: bgSurface ?? this.bgSurface,
      bgElevated: bgElevated ?? this.bgElevated,
      bgSubtle: bgSubtle ?? this.bgSubtle,
      bgOverlay: bgOverlay ?? this.bgOverlay,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderDefault: borderDefault ?? this.borderDefault,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDisabled: textDisabled ?? this.textDisabled,
      textInverse: textInverse ?? this.textInverse,
      brand: brand ?? this.brand,
      brandHover: brandHover ?? this.brandHover,
      brandActive: brandActive ?? this.brandActive,
      brandSubtle: brandSubtle ?? this.brandSubtle,
      brandSubtleHover: brandSubtleHover ?? this.brandSubtleHover,
      brandBorder: brandBorder ?? this.brandBorder,
      success: success ?? this.success,
      successSubtle: successSubtle ?? this.successSubtle,
      successBorder: successBorder ?? this.successBorder,
      warning: warning ?? this.warning,
      warningSubtle: warningSubtle ?? this.warningSubtle,
      warningBorder: warningBorder ?? this.warningBorder,
      danger: danger ?? this.danger,
      dangerSubtle: dangerSubtle ?? this.dangerSubtle,
      dangerBorder: dangerBorder ?? this.dangerBorder,
      info: info ?? this.info,
      infoSubtle: infoSubtle ?? this.infoSubtle,
      infoBorder: infoBorder ?? this.infoBorder,
      neutral: neutral ?? this.neutral,
      neutralSubtle: neutralSubtle ?? this.neutralSubtle,
      neutralBorder: neutralBorder ?? this.neutralBorder,
      chartSeries: chartSeries ?? this.chartSeries,
    );
  }

  @override
  YaColors lerp(ThemeExtension<YaColors>? other, double t) {
    if (other is! YaColors) return this;
    return YaColors(
      bgBase: Color.lerp(bgBase, other.bgBase, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      bgSubtle: Color.lerp(bgSubtle, other.bgSubtle, t)!,
      bgOverlay: Color.lerp(bgOverlay, other.bgOverlay, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandHover: Color.lerp(brandHover, other.brandHover, t)!,
      brandActive: Color.lerp(brandActive, other.brandActive, t)!,
      brandSubtle: Color.lerp(brandSubtle, other.brandSubtle, t)!,
      brandSubtleHover:
          Color.lerp(brandSubtleHover, other.brandSubtleHover, t)!,
      brandBorder: Color.lerp(brandBorder, other.brandBorder, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSubtle: Color.lerp(successSubtle, other.successSubtle, t)!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSubtle: Color.lerp(warningSubtle, other.warningSubtle, t)!,
      warningBorder: Color.lerp(warningBorder, other.warningBorder, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSubtle: Color.lerp(dangerSubtle, other.dangerSubtle, t)!,
      dangerBorder: Color.lerp(dangerBorder, other.dangerBorder, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSubtle: Color.lerp(infoSubtle, other.infoSubtle, t)!,
      infoBorder: Color.lerp(infoBorder, other.infoBorder, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      neutralSubtle: Color.lerp(neutralSubtle, other.neutralSubtle, t)!,
      neutralBorder: Color.lerp(neutralBorder, other.neutralBorder, t)!,
      chartSeries: chartSeries, // listas não se interpolam
    );
  }
}

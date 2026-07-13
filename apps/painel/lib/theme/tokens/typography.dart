import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografia YA — foundations §4.
///
/// Três famílias:
/// - **Newsreader** (serif): page headings, KPI values, valores grandes
/// - **Inter** (sans): UI body, tabelas, formulários, navegação
/// - **JetBrains Mono**: IDs, NUITs, matrículas, timestamps técnicos
///
/// Uso: `YaText.h1.copyWith(color: colors.textPrimary)` ou
/// `YaText.body` directamente em `Text(text, style: YaText.body)`.
abstract class YaText {
  // === Famílias base (sem cor — aplicar via copyWith ou DefaultTextStyle) ===

  /// Newsreader (serif). Pesos: 400, 500.
  static TextStyle serif({
    required double size,
    required double height,
    double letterSpacing = 0,
    FontWeight weight = FontWeight.w400,
  }) {
    return GoogleFonts.newsreader(
      fontSize: size,
      height: height / size,
      letterSpacing: letterSpacing,
      fontWeight: weight,
    );
  }

  /// Inter (sans). Pesos: 400, 500, 600.
  static TextStyle sans({
    required double size,
    required double height,
    double letterSpacing = 0,
    FontWeight weight = FontWeight.w400,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      height: height / size,
      letterSpacing: letterSpacing,
      fontWeight: weight,
      // Tabular numerals por defeito em todos os números
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// JetBrains Mono. Pesos: 400, 500.
  static TextStyle mono({
    required double size,
    required double height,
    double letterSpacing = 0,
    FontWeight weight = FontWeight.w400,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      height: height / size,
      letterSpacing: letterSpacing,
      fontWeight: weight,
    );
  }

  // === Escala tipográfica — foundations §4.2 ===

  /// xs · 11/16 · LS 0.02em · 500 · Inter
  /// Captions, timestamps em meta-info, labels muito pequenos
  static TextStyle get xs => sans(
        size: 11,
        height: 16,
        letterSpacing: 0.22, // 0.02em * 11
        weight: FontWeight.w500,
      );

  /// sm · 13/18 · 400 · Inter
  /// Texto secundário, labels de input, badges
  static TextStyle get sm => sans(size: 13, height: 18);

  /// sm medium · 13/18 · 500 · Inter
  static TextStyle get smMedium =>
      sans(size: 13, height: 18, weight: FontWeight.w500);

  /// base · 14/20 · 400 · Inter (default UI)
  /// Body, células de tabela, navegação
  static TextStyle get base => sans(size: 14, height: 20);

  /// base medium · 14/20 · 500 · Inter
  static TextStyle get baseMedium =>
      sans(size: 14, height: 20, weight: FontWeight.w500);

  /// md · 15/22 · 400 · Inter
  static TextStyle get md => sans(size: 15, height: 22);

  /// md medium · 15/22 · 500 · Inter
  /// Texto importante, headings de cards pequenos
  static TextStyle get mdMedium =>
      sans(size: 15, height: 22, weight: FontWeight.w500);

  /// lg · 17/24 · LS -0.005em · 500 · Inter
  /// Headings de secção dentro de páginas
  static TextStyle get lg => sans(
        size: 17,
        height: 24,
        letterSpacing: -0.085, // -0.005em * 17
        weight: FontWeight.w500,
      );

  /// xl · 20/28 · LS -0.01em · 500 · Newsreader
  /// Headings de cards grandes, sub-títulos de página
  static TextStyle get xl => serif(
        size: 20,
        height: 28,
        letterSpacing: -0.20,
        weight: FontWeight.w500,
      );

  /// 2xl · 24/32 · LS -0.015em · 500 · Newsreader
  /// **Page heading principal**
  static TextStyle get xxl => serif(
        size: 24,
        height: 32,
        letterSpacing: -0.36,
        weight: FontWeight.w500,
      );

  /// 3xl · 30/38 · LS -0.02em · 500 · Newsreader
  /// KPI values em cards
  static TextStyle get xxxl => serif(
        size: 30,
        height: 38,
        letterSpacing: -0.60,
        weight: FontWeight.w500,
      );

  /// 4xl · 38/46 · LS -0.025em · 500 · Newsreader
  /// Hero numbers (raro)
  static TextStyle get huge => serif(
        size: 38,
        height: 46,
        letterSpacing: -0.95,
        weight: FontWeight.w500,
      );

  // === Variantes mono comuns ===

  /// Mono sm · 12/18 · 500 — para IDs, NUITs em tabelas
  static TextStyle get monoSm =>
      mono(size: 12, height: 18, weight: FontWeight.w500);

  /// Mono base · 13/20 · 400 — para valores monetários inline
  static TextStyle get monoBase => mono(size: 13, height: 20);

  /// Mono md · 14/22 · 500 — para matrículas destacadas
  static TextStyle get monoMd =>
      mono(size: 14, height: 22, weight: FontWeight.w500);

  // === Eyebrow (usado em sidebar groups, KPI labels) — uppercase letter-spaced ===

  /// Sidebar group eyebrow · 10.5/14 · LS 0.1em · 500 · Inter uppercase
  static TextStyle get eyebrowSidebar => sans(
        size: 10.5,
        height: 14,
        letterSpacing: 1.05, // 0.1em * 10.5
        weight: FontWeight.w500,
      );

  /// KPI label eyebrow · 10.5/14 · LS 0.06em · 500 · Inter uppercase
  static TextStyle get eyebrowKpi => sans(
        size: 10.5,
        height: 14,
        letterSpacing: 0.63, // 0.06em * 10.5
        weight: FontWeight.w500,
      );

  /// Painel role tag · 10/14 · LS 0.14em · 500 · Inter uppercase
  static TextStyle get eyebrowRole => sans(
        size: 10,
        height: 14,
        letterSpacing: 1.4, // 0.14em * 10
        weight: FontWeight.w500,
      );
}

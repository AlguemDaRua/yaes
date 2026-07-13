import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens/colors.dart';
import 'tokens/dimensions.dart';
import 'tokens/typography.dart';

/// ThemeData para light e dark mode.
///
/// As cores semânticas customizadas estão em [YaColors] como ThemeExtension.
/// O Material ColorScheme é configurado de forma compatível mas o trabalho
/// real de cores acontece via `YaColors.of(context)`.
abstract class YaTheme {
  static ThemeData light() => _build(YaColors.light, Brightness.light);

  static ThemeData dark() => _build(YaColors.dark, Brightness.dark);

  static ThemeData _build(YaColors colors, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.brand,
      onPrimary: colors.textInverse,
      secondary: colors.brand,
      onSecondary: colors.textInverse,
      error: colors.danger,
      onError: colors.textInverse,
      surface: colors.bgSurface,
      onSurface: colors.textPrimary,
      surfaceContainerHighest: colors.bgElevated,
      surfaceContainer: colors.bgElevated,
      surfaceContainerHigh: colors.bgElevated,
      outline: colors.borderDefault,
      outlineVariant: colors.borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.bgBase,
      canvasColor: colors.bgBase,
      dividerColor: colors.borderSubtle,

      // Tipografia base — applies a Inter como default sans
      textTheme: TextTheme(
        displayLarge: YaText.huge.copyWith(color: colors.textPrimary),
        displayMedium: YaText.xxxl.copyWith(color: colors.textPrimary),
        displaySmall: YaText.xxl.copyWith(color: colors.textPrimary),
        headlineLarge: YaText.xxl.copyWith(color: colors.textPrimary),
        headlineMedium: YaText.xl.copyWith(color: colors.textPrimary),
        headlineSmall: YaText.lg.copyWith(color: colors.textPrimary),
        titleLarge: YaText.lg.copyWith(color: colors.textPrimary),
        titleMedium: YaText.mdMedium.copyWith(color: colors.textPrimary),
        titleSmall: YaText.smMedium.copyWith(color: colors.textPrimary),
        bodyLarge: YaText.md.copyWith(color: colors.textPrimary),
        bodyMedium: YaText.base.copyWith(color: colors.textPrimary),
        bodySmall: YaText.sm.copyWith(color: colors.textSecondary),
        labelLarge: YaText.smMedium.copyWith(color: colors.textPrimary),
        labelMedium: YaText.sm.copyWith(color: colors.textSecondary),
        labelSmall: YaText.xs.copyWith(color: colors.textMuted),
      ),

      iconTheme: IconThemeData(
        color: colors.textSecondary,
        size: YaDimensions.iconMd,
      ),

      dividerTheme: DividerThemeData(
        color: colors.borderSubtle,
        thickness: 1,
        space: 0,
      ),

      // Botões — base; variantes fazem-se nos widgets custom
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.brand,
          foregroundColor:
              brightness == Brightness.dark ? colors.textInverse : Colors.white,
          textStyle: YaText.smMedium,
          minimumSize: const Size(0, YaDimensions.buttonHeightMd),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: const RoundedRectangleBorder(borderRadius: YaRadius.brMd),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          textStyle: YaText.smMedium,
          minimumSize: const Size(0, YaDimensions.buttonHeightMd),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: const RoundedRectangleBorder(borderRadius: YaRadius.brMd),
          side: BorderSide(color: colors.borderDefault),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.textSecondary,
          textStyle: YaText.smMedium,
          minimumSize: const Size(0, YaDimensions.buttonHeightMd),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: const RoundedRectangleBorder(borderRadius: YaRadius.brMd),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.bgSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        constraints: const BoxConstraints(
          minHeight: YaDimensions.inputHeight,
        ),
        hintStyle: YaText.sm.copyWith(color: colors.textMuted),
        labelStyle: YaText.sm.copyWith(color: colors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: YaRadius.brMd,
          borderSide: BorderSide(color: colors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: YaRadius.brMd,
          borderSide: BorderSide(color: colors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: YaRadius.brMd,
          borderSide: BorderSide(color: colors.brandBorder, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: YaRadius.brMd,
          borderSide: BorderSide(color: colors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: YaRadius.brMd,
          borderSide: BorderSide(color: colors.danger, width: 1.5),
        ),
        errorStyle: YaText.sm.copyWith(color: colors.danger),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: colors.bgSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: YaRadius.brLg,
          side: BorderSide(color: colors.borderSubtle),
        ),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: YaRadius.brXl),
        titleTextStyle: YaText.lg.copyWith(color: colors.textPrimary),
        contentTextStyle: YaText.sm.copyWith(color: colors.textSecondary),
      ),

      // Tooltips
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.textPrimary,
          borderRadius: YaRadius.brSm,
        ),
        textStyle: YaText.xs.copyWith(color: colors.textInverse),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        waitDuration: const Duration(milliseconds: 600),
      ),

      // Chip / FilterChip
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: colors.brandSubtle,
        side: BorderSide(color: colors.borderSubtle),
        labelStyle: YaText.sm.copyWith(color: colors.textSecondary),
        secondaryLabelStyle: YaText.sm.copyWith(color: colors.brand),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: const StadiumBorder(),
      ),

      // Scrollbar
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(colors.borderStrong),
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(3),
      ),

      // Splash effects: subtilíssimos
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: colors.bgSubtle,
      hoverColor: colors.bgSubtle,

      // Page transitions: fade subtil em vez de slide pesado
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      // ThemeExtensions — aqui vai a paleta semântica
      extensions: <ThemeExtension<dynamic>>[
        colors,
      ],
    );
  }

  /// Configurar SystemUiOverlayStyle (status bar etc) consoante o tema
  /// — útil para mobile/web mas não custa em desktop.
  static void applySystemOverlay(Brightness brightness) {
    SystemChrome.setSystemUIOverlayStyle(
      brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    );
  }
}

import 'package:flutter/widgets.dart';

/// Tokens de espaçamento — foundations §5.1
abstract class YaSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double huge2 = 48;
  static const double huge3 = 64;
  static const double huge4 = 80;
  static const double huge5 = 96;

  // EdgeInsets pré-fabricados comuns
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: 32);
  static const EdgeInsets pageAll = EdgeInsets.all(32);
  static const EdgeInsets cardSm = EdgeInsets.all(16);
  static const EdgeInsets cardMd = EdgeInsets.all(20);
  static const EdgeInsets cardLg = EdgeInsets.all(24);
}

/// Border radius — foundations §5.2
abstract class YaRadius {
  static const double xs = 4;
  static const double sm = 5;
  static const double md = 6;
  static const double lg = 8;
  static const double xl = 12;
  static const double full = 9999;

  static const BorderRadius brXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brFull = BorderRadius.all(Radius.circular(full));
}

/// Alturas e dimensões fixas — foundations §5.3
abstract class YaDimensions {
  // Inputs / botões
  static const double inputHeight = 34;
  static const double inputHeightLarge = 38;
  static const double buttonHeightSm = 28;
  static const double buttonHeightMd = 36;
  static const double buttonHeightLg = 40;

  // Tabela
  static const double tableRowHeight = 40;
  static const double tableRowHeightCompact = 32;
  static const double tableHeaderHeight = 40;

  // Layout
  static const double topbarHeight = 56;
  static const double sidebarWidth = 240;
  static const double sidebarWidthCollapsed = 56;

  // Avatares
  static const double avatarSm = 24;
  static const double avatarMd = 32;
  static const double avatarLg = 44;
  static const double avatarXl = 64;

  // Page
  static const double pageMaxWidth = 1280;
  static const double pageHorizontalPadding = 32;

  // Ícones
  static const double iconXs = 12;
  static const double iconSm = 14;
  static const double iconMd = 16;
  static const double iconLg = 20;
  static const double iconXl = 24;

  // Border widths
  static const double borderThin = 1;
  static const double borderMedium = 1.5;
  static const double borderThick = 2;
  static const double borderAccent = 3;
}

/// Z-index hierarchy — foundations §5.5 (interpretado para Flutter via Stack/Overlay)
abstract class YaZ {
  static const int base = 0;
  static const int sidebar = 10;
  static const int stickyHeader = 20;
  static const int dropdown = 30;
  static const int tooltip = 40;
  static const int modalBackdrop = 50;
  static const int modalContent = 60;
  static const int toast = 70;
  static const int commandPalette = 80;
}

/// Durações de animação — foundations §7.8
abstract class YaDurations {
  static const Duration instant = Duration();
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration shimmer = Duration(milliseconds: 1500);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeIn = Curves.easeInCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
}

/// Sombras (light mode only — dark mode usa diferenças tonais) — foundations §5.4
abstract class YaShadows {
  static const List<BoxShadow> none = [];

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A14100A), // rgba(20,16,8,0.04)
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x0F14100A), // rgba(20,16,8,0.06)
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A14100A),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x1414100A), // rgba(20,16,8,0.08)
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x0A14100A),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  /// Focus ring — não é BoxShadow puro mas usado como tal.
  /// 3px de largura, opacity 20% da brand
  static const List<BoxShadow> focusBrand = [
    BoxShadow(
      color: Color(0x33E5A400), // rgba(229,164,0,0.20)
      spreadRadius: 3,
    ),
  ];

  static const List<BoxShadow> focusDanger = [
    BoxShadow(
      color: Color(0x33DC2626),
      spreadRadius: 3,
    ),
  ];
}

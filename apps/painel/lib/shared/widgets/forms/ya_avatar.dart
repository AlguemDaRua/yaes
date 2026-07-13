// Tradução fiel de _design/showcases/auxiliaries.jsx (componente Avatar).

import 'package:flutter/material.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/typography.dart';

/// Avatar circular com iniciais, ou foto (gradient placeholder).
///
/// Cor de fundo é gerada por hash do nome via `hueFromName`. Se preferes cor
/// fixa, passa `hue: 30`. Tamanhos comuns: 24, 32, 44, 64.
class YaAvatar extends StatelessWidget {
  const YaAvatar({
    required this.initial,
    this.size = 32,
    this.hue = 30,
    this.hasPhoto = false,
    this.border = false,
    super.key,
  });

  /// Conveniência: cria avatar com hue derivado do nome.
  factory YaAvatar.fromName(
    String name, {
    double size = 32,
    bool hasPhoto = false,
    bool border = false,
    Key? key,
  }) {
    return YaAvatar(
      initial: _initialsFromName(name),
      size: size,
      hue: hueFromName(name),
      hasPhoto: hasPhoto,
      border: border,
      key: key,
    );
  }

  final String initial;
  final double size;
  final double hue;
  final bool hasPhoto;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final fontSize = size <= 24
        ? 10.0
        : size <= 32
            ? 12.0
            : size <= 44
                ? 15.0
                : 20.0;

    final decoration = BoxDecoration(
      shape: BoxShape.circle,
      color: hasPhoto ? null : _avatarBgFromHue(hue),
      gradient: hasPhoto
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _avatarBgFromHue(hue, lightness: 0.55, chroma: 0.10),
                _avatarBgFromHue(hue + 30, lightness: 0.35, chroma: 0.06),
              ],
            )
          : null,
      border: border ? Border.all(color: colors.borderSubtle, width: 1.5) : null,
    );

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: decoration,
      child: hasPhoto
          ? null
          : Text(
              initial,
              style: YaText.sans(
                size: fontSize,
                height: fontSize * 1.2,
                weight: FontWeight.w500,
                letterSpacing: 0.01 * fontSize,
              ).copyWith(color: colors.textPrimary),
            ),
    );
  }
}

/// `oklch(L C H)` aproximado por HSL — JSX usa `oklch(0.32 0.05 H)`.
/// Conversão pragmática: lightness 0.32 → HSL.lightness ≈ 0.30.
Color _avatarBgFromHue(double hue, {double lightness = 0.30, double chroma = 0.05}) {
  // Saturation aproxima `chroma` num espaço HSL convencional.
  final saturation = (chroma * 3).clamp(0.0, 1.0); // 0.05 → 0.15
  return HSLColor.fromAHSL(1, hue % 360, saturation, lightness).toColor();
}

/// Hash simples → hue 0..360. Mesma string produz mesma cor.
double hueFromName(String name) {
  var h = 0;
  for (var i = 0; i < name.length; i++) {
    h = (h * 31 + name.codeUnitAt(i)) & 0x7fffffff;
  }
  return (h % 360).toDouble();
}

String _initialsFromName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

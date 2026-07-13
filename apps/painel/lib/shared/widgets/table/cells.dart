// Tradução fiel de _design/showcases/data-table.jsx (componentes Avatar
// inline, PersonCell + células comuns inferidas do showcase).

import 'package:flutter/material.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/typography.dart';
import '../forms/ya_avatar.dart';

/// Célula avatar + nome + sub-info (email/NUIT/etc.).
class PersonCell extends StatelessWidget {
  const PersonCell({
    required this.name,
    required this.subtitle,
    this.avatarSize = 28,
    super.key,
  });

  final String name;
  final String subtitle;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        YaAvatar.fromName(name, size: avatarSize, border: true),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: YaText.smMedium.copyWith(color: colors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: YaText.mono(size: 11, height: 14)
                      .copyWith(color: colors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ID em mono 12px text-secondary (usado para TRP-XXXX, USR-XXXX, etc.).
class IdCell extends StatelessWidget {
  const IdCell(this.id, {super.key});
  final String id;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Text(
      id,
      style: YaText.monoSm.copyWith(color: colors.textSecondary),
    );
  }
}

/// Matrícula em mono 12px text-primary.
class PlateCell extends StatelessWidget {
  const PlateCell(this.plate, {super.key});
  final String plate;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Text(
      plate,
      style: YaText.monoSm.copyWith(color: colors.textPrimary),
    );
  }
}

/// Valor monetário em mono 13 weight 500 + sufixo (MTn, USD).
class MoneyCell extends StatelessWidget {
  const MoneyCell({
    required this.amount,
    this.currency = 'MTn',
    this.alignEnd = true,
    super.key,
  });

  final String amount;
  final String currency;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            amount,
            style: YaText.mono(size: 13, height: 18, weight: FontWeight.w500)
                .copyWith(color: colors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          currency,
          style: YaText.sans(size: 11, height: 14)
              .copyWith(color: colors.textMuted),
        ),
      ],
    );
  }
}

/// Rota: "origem → destino" inline com truncate.
class RouteCell extends StatelessWidget {
  const RouteCell({required this.from, required this.to, super.key});
  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Text(
      '$from → $to',
      style: YaText.sm.copyWith(color: colors.textPrimary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Texto secundário tabular (distância, duração).
class NumericCell extends StatelessWidget {
  const NumericCell(this.value, {this.alignEnd = true, super.key});
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        value,
        style: YaText.sm.copyWith(color: colors.textSecondary),
      ),
    );
  }
}

/// Timestamp relativo ("há 12 min") em xs text-muted.
class WhenCell extends StatelessWidget {
  const WhenCell(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Text(
      text,
      style:
          YaText.sans(size: 12, height: 16).copyWith(color: colors.textMuted),
    );
  }
}

/// Texto simples numa celula, para valores sem semantica especial.
class TextCell extends StatelessWidget {
  const TextCell(
    this.value, {
    this.alignEnd = false,
    this.muted = false,
    super.key,
  });

  final String value;
  final bool alignEnd;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        value,
        style: YaText.sm.copyWith(
          color: muted ? colors.textMuted : colors.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Data relativa com tooltip de data absoluta.
class DateCell extends StatelessWidget {
  const DateCell(this.date, {super.key});

  /// Passar null para mostrar "-".
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    if (date == null) {
      return Text('-', style: YaText.sm.copyWith(color: colors.textMuted));
    }

    final now = DateTime.now();
    final diff = date!.difference(now).inDays;
    final color = diff < 0
        ? colors.danger
        : diff < 30
            ? colors.warning
            : colors.textSecondary;

    final relative = diff < 0
        ? 'ha ${-diff} dias'
        : diff == 0
            ? 'hoje'
            : 'em $diff dias';
    final absolute =
        '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}';

    return Tooltip(
      message: absolute,
      child: Text(
        '$absolute · $relative',
        style: YaText.sans(size: 12, height: 16).copyWith(color: color),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

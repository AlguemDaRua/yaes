import 'package:flutter/material.dart';

import '../../../core/constants/status_mapping.dart';
import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';

class TimelineEvent {
  const TimelineEvent({
    required this.label,
    required this.timestamp,
    this.variant = StatusVariant.neutral,
  });
  final String label;
  final String timestamp;
  final StatusVariant variant;
}

class Timeline extends StatelessWidget {
  const Timeline({required this.events, super.key});
  final List<TimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Column(
      children: [
        for (var i = 0; i < events.length; i++)
          _TimelineRow(
            event: events[i],
            isLast: i == events.length - 1,
            colors: colors,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.event,
    required this.isLast,
    required this.colors,
  });
  final TimelineEvent event;
  final bool isLast;
  final YaColors colors;

  @override
  Widget build(BuildContext context) {
    final accent = event.variant.resolve(colors).text;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: colors.borderSubtle,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: YaSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : YaSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      event.label,
                      style: YaText.sm.copyWith(color: colors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: YaSpacing.md),
                  Text(
                    event.timestamp,
                    style: YaText.sans(size: 12, height: 16)
                        .copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:review_calendar/ui/core/theme/rc_event_colors.dart';
import 'package:review_calendar/ui/core/theme/rc_layout.dart';
import 'package:review_calendar/ui/core/theme/rc_theme.dart';

enum RcEventType { visit, deadline, posted, unscheduled }

enum RcChipSize { compact, regular }

class RcEventChip extends StatelessWidget {
  const RcEventChip({
    required this.type,
    required this.label,
    super.key,
    this.inverted = false,
    this.size = RcChipSize.compact,
  });

  final RcEventType type;
  final String label;
  final bool inverted;
  final RcChipSize size;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    final palette = switch (type) {
      RcEventType.visit => colors.visit,
      RcEventType.deadline => colors.deadline,
      RcEventType.posted => colors.posted,
      RcEventType.unscheduled => colors.unscheduled,
    };
    final foreground = inverted ? colors.card : palette.ink;
    final background = inverted ? palette.ink : palette.soft;
    final verticalPadding = size == RcChipSize.compact
        ? RcSpacing.xxs
        : RcSpacing.xs;
    final horizontalPadding = size == RcChipSize.compact
        ? RcSpacing.md
        : RcSpacing.lg;
    final textStyle = size == RcChipSize.compact
        ? Theme.of(context).textTheme.labelMedium
        : Theme.of(context).textTheme.labelLarge;

    return Semantics(
      label: '${_semanticType(type)}: $label',
      container: true,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(RcRadius.pill),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: foreground,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(dimension: 5),
              ),
              const SizedBox(width: RcSpacing.xs),
              Text(label, style: textStyle?.copyWith(color: foreground)),
            ],
          ),
        ),
      ),
    );
  }

  String _semanticType(RcEventType type) {
    return switch (type) {
      RcEventType.visit => '방문 일정',
      RcEventType.deadline => '마감 일정',
      RcEventType.posted => '발행 완료',
      RcEventType.unscheduled => '방문일 미정',
    };
  }
}

extension RcEventPalette on RcEventType {
  RcEventColors colorsOf(BuildContext context) {
    final colors = context.rcColors;
    return switch (this) {
      RcEventType.visit => colors.visit,
      RcEventType.deadline => colors.deadline,
      RcEventType.posted => colors.posted,
      RcEventType.unscheduled => colors.unscheduled,
    };
  }
}

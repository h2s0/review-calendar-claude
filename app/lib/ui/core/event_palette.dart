import 'package:flutter/material.dart';
import 'package:review_calendar/data/review_calendar_models.dart';
import 'package:review_calendar/ui/core/components/rc_event_chip.dart';
import 'package:review_calendar/ui/core/theme/rc_event_colors.dart';
import 'package:review_calendar/ui/core/theme/rc_theme.dart';

/// Bridges the dummy-data `CalendarEventType` to the ported `RcEventChip`'s
/// `RcEventType` / color palette (design-system.jsx's RC.visit/deadline/
/// posted/idea).
extension CalendarEventTypeX on CalendarEventType {
  RcEventType get chipType => switch (this) {
    CalendarEventType.visit => RcEventType.visit,
    CalendarEventType.deadline => RcEventType.deadline,
    CalendarEventType.posted => RcEventType.posted,
    CalendarEventType.idea => RcEventType.unscheduled,
  };

  RcEventColors paletteOf(BuildContext context) => chipType.colorsOf(context);

  String get label => switch (this) {
    CalendarEventType.visit => '방문',
    CalendarEventType.deadline => '마감',
    CalendarEventType.posted => '포스팅',
    CalendarEventType.idea => '아이디어',
  };
}

extension RewardTypeColorX on RewardType {
  RcEventColors paletteOf(BuildContext context) {
    final colors = context.rcColors;
    return switch (this) {
      RewardType.sponsor => colors.posted,
      RewardType.fee => colors.unscheduled,
    };
  }
}

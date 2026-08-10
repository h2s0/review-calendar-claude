final class NotificationSchedule {
  factory NotificationSchedule(Iterable<int> daysBefore) {
    final normalized = daysBefore.toSet().toList()
      ..sort((left, right) => right.compareTo(left));
    if (normalized.any((days) => days < 0 || days > 365)) {
      throw ArgumentError.value(
        daysBefore,
        'daysBefore',
        'must be between 0 and 365',
      );
    }
    return NotificationSchedule._(List.unmodifiable(normalized));
  }

  NotificationSchedule.disabled() : daysBefore = const [];

  const NotificationSchedule._(this.daysBefore);

  final List<int> daysBefore;

  bool get enabled => daysBefore.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSchedule &&
          _listEquals(daysBefore, other.daysBefore);

  @override
  int get hashCode => Object.hashAll(daysBefore);
}

final class GlobalNotificationSettings {
  GlobalNotificationSettings({
    required this.visit,
    required this.deadline,
    this.schemaVersion = currentSchemaVersion,
  });

  factory GlobalNotificationSettings.defaults() {
    return GlobalNotificationSettings(
      visit: NotificationSchedule([1]),
      deadline: NotificationSchedule([3, 1]),
    );
  }

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final NotificationSchedule visit;
  final NotificationSchedule deadline;
}

sealed class NotificationOverride {
  const NotificationOverride();
}

final class InheritNotification extends NotificationOverride {
  const InheritNotification();
}

final class DisableNotification extends NotificationOverride {
  const DisableNotification();
}

final class CustomNotification extends NotificationOverride {
  CustomNotification(Iterable<int> daysBefore)
    : schedule = NotificationSchedule(daysBefore) {
    if (!schedule.enabled) {
      throw ArgumentError(
        'Use DisableNotification for an empty custom schedule.',
      );
    }
  }

  final NotificationSchedule schedule;
}

final class CampaignNotificationSettings {
  const CampaignNotificationSettings({
    this.visit = const InheritNotification(),
    this.deadline = const InheritNotification(),
    this.schemaVersion = currentSchemaVersion,
  });

  const CampaignNotificationSettings.disabled()
    : visit = const DisableNotification(),
      deadline = const DisableNotification(),
      schemaVersion = currentSchemaVersion;

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final NotificationOverride visit;
  final NotificationOverride deadline;
}

final class ResolvedNotificationSettings {
  const ResolvedNotificationSettings({
    required this.visit,
    required this.deadline,
  });

  final NotificationSchedule visit;
  final NotificationSchedule deadline;
}

ResolvedNotificationSettings resolveNotificationSettings({
  required GlobalNotificationSettings global,
  required CampaignNotificationSettings campaign,
}) {
  return ResolvedNotificationSettings(
    visit: _resolveSchedule(global.visit, campaign.visit),
    deadline: _resolveSchedule(global.deadline, campaign.deadline),
  );
}

NotificationSchedule _resolveSchedule(
  NotificationSchedule global,
  NotificationOverride override,
) {
  return switch (override) {
    InheritNotification() => global,
    DisableNotification() => NotificationSchedule.disabled(),
    CustomNotification(:final schedule) => schedule,
  };
}

bool _listEquals(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

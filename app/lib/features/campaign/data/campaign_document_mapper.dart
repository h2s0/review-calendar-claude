import 'package:review_calendar/features/campaign/domain/campaign.dart';
import 'package:review_calendar/features/campaign/domain/campaign_id.dart';
import 'package:review_calendar/features/campaign/domain/campaign_status.dart';
import 'package:review_calendar/features/campaign/domain/local_date.dart';
import 'package:review_calendar/features/campaign/domain/local_time.dart';
import 'package:review_calendar/features/campaign/domain/money.dart';
import 'package:review_calendar/features/campaign/domain/visit_schedule.dart';
import 'package:review_calendar/features/settings/domain/notification_settings.dart';

final class CampaignDocumentMapper {
  const CampaignDocumentMapper();

  static const int schemaVersion = 3;

  Map<String, Object?> toDocument(Campaign campaign) {
    return {
      'schemaVersion': schemaVersion,
      'id': campaign.id.value,
      'ownerId': campaign.ownerId.value,
      'brand': campaign.brand,
      'platform': campaign.platform,
      'category': campaign.category,
      'visitStatus': campaign.status.visit.name,
      'postingStatus': campaign.status.posting.name,
      'visitAvailability': _availabilityToDocument(campaign.visitAvailability),
      'availableTimes': campaign.availableTimes
          .map(_requiredTimeRangeToDocument)
          .toList(growable: false),
      'availableTime': _timeRangeToDocument(campaign.availableTime),
      'visit': {
        'date': campaign.visit.date?.toString(),
        'time': campaign.visit.time?.toString(),
      },
      'deadline': campaign.deadline.toString(),
      'originalDeadline': campaign.originalDeadline?.toString(),
      'contact': _contactToDocument(campaign.contact),
      'notes': campaign.notes,
      'sponsoredValue': _moneyToDocument(campaign.sponsoredValue),
      'cashFee': _moneyToDocument(campaign.cashFee),
      'publishedDate': campaign.publishedDate?.toString(),
      'postUrl': campaign.postUrl?.toString(),
      'notificationSettings': _notificationSettingsToDocument(
        campaign.notificationSettings,
      ),
      'createdAt': campaign.createdAt.toIso8601String(),
      'updatedAt': campaign.updatedAt.toIso8601String(),
    };
  }

  Campaign fromDocument(Map<String, Object?> document) {
    final version = _requiredInt(document, 'schemaVersion');
    if (version != 2 && version != schemaVersion) {
      throw FormatException('Unsupported campaign schema version: $version');
    }

    final visit = _requiredMap(document, 'visit');
    return Campaign(
      id: CampaignId(_requiredString(document, 'id')),
      ownerId: UserId(_requiredString(document, 'ownerId')),
      brand: _requiredString(document, 'brand'),
      platform: _optionalString(document, 'platform'),
      category: _optionalString(document, 'category'),
      status: CampaignStatus(
        visit: _visitStatusFromDocument(document),
        posting: _postingStatusFromDocument(document),
      ),
      visitAvailability: _availabilityFromDocument(
        _requiredMap(document, 'visitAvailability'),
      ),
      availableTimes: _timeRangesFromDocument(document),
      visit: VisitSchedule(
        date: _optionalDate(visit, 'date'),
        time: _optionalTime(visit, 'time'),
      ),
      deadline: LocalDate.parse(_requiredString(document, 'deadline')),
      originalDeadline: _optionalDate(document, 'originalDeadline'),
      contact: _contactFromDocument(_optionalMap(document, 'contact')),
      notes: _optionalString(document, 'notes'),
      sponsoredValue: _moneyFromDocument(
        _optionalMap(document, 'sponsoredValue'),
      ),
      cashFee: _moneyFromDocument(_optionalMap(document, 'cashFee')),
      publishedDate: _optionalDate(document, 'publishedDate'),
      postUrl: _optionalString(document, 'postUrl'),
      notificationSettings: version == 2
          ? const CampaignNotificationSettings()
          : _notificationSettingsFromDocument(
              _requiredMap(document, 'notificationSettings'),
            ),
      createdAt: _requiredInstant(document, 'createdAt'),
      updatedAt: _requiredInstant(document, 'updatedAt'),
    );
  }

  Map<String, Object?> _notificationSettingsToDocument(
    CampaignNotificationSettings settings,
  ) {
    return {
      'schemaVersion': settings.schemaVersion,
      'visit': _notificationOverrideToDocument(settings.visit),
      'deadline': _notificationOverrideToDocument(settings.deadline),
    };
  }

  Map<String, Object?> _notificationOverrideToDocument(
    NotificationOverride value,
  ) {
    return switch (value) {
      InheritNotification() => {'mode': 'inherit'},
      DisableNotification() => {'mode': 'disabled'},
      CustomNotification(:final schedule) => {
        'mode': 'custom',
        'daysBefore': schedule.daysBefore,
      },
    };
  }

  CampaignNotificationSettings _notificationSettingsFromDocument(
    Map<String, Object?> document,
  ) {
    if (_requiredInt(document, 'schemaVersion') !=
        CampaignNotificationSettings.currentSchemaVersion) {
      throw const FormatException(
        'Unsupported campaign notification settings schema.',
      );
    }
    return CampaignNotificationSettings(
      visit: _notificationOverrideFromDocument(_requiredMap(document, 'visit')),
      deadline: _notificationOverrideFromDocument(
        _requiredMap(document, 'deadline'),
      ),
    );
  }

  NotificationOverride _notificationOverrideFromDocument(
    Map<String, Object?> document,
  ) {
    return switch (_requiredString(document, 'mode')) {
      'inherit' => const InheritNotification(),
      'disabled' => const DisableNotification(),
      'custom' => CustomNotification(
        _requiredList(
          document,
          'daysBefore',
        ).map((value) => _asInt(value, 'daysBefore item')),
      ),
      final mode => throw FormatException(
        'Unsupported notification mode: $mode',
      ),
    };
  }

  Map<String, Object?> _availabilityToDocument(VisitAvailability availability) {
    return switch (availability) {
      VisitDateOptions(:final dates) => {
        'type': 'options',
        'dates': dates.map((date) => date.toString()).toList(growable: false),
      },
      VisitDateRange(:final start, :final end) => {
        'type': 'range',
        'start': start.toString(),
        'end': end.toString(),
      },
    };
  }

  VisitAvailability _availabilityFromDocument(Map<String, Object?> document) {
    return switch (_requiredString(document, 'type')) {
      'options' => VisitDateOptions(
        _requiredList(
          document,
          'dates',
        ).map((value) => LocalDate.parse(_asString(value, 'dates item'))),
      ),
      'range' => VisitDateRange(
        start: LocalDate.parse(_requiredString(document, 'start')),
        end: LocalDate.parse(_requiredString(document, 'end')),
      ),
      final type => throw FormatException(
        'Unsupported visit availability type: $type',
      ),
    };
  }

  Map<String, Object?>? _timeRangeToDocument(VisitTimeRange? range) {
    if (range == null) {
      return null;
    }
    return _requiredTimeRangeToDocument(range);
  }

  Map<String, Object?> _requiredTimeRangeToDocument(VisitTimeRange range) {
    return {'start': range.start.toString(), 'end': range.end.toString()};
  }

  List<VisitTimeRange> _timeRangesFromDocument(Map<String, Object?> document) {
    final values = _optionalList(document, 'availableTimes');
    if (values != null) {
      return List.unmodifiable(
        values.map(
          (value) =>
              _timeRangeFromDocument(_asMap(value, 'availableTimes item')),
        ),
      );
    }
    final legacy = _optionalMap(document, 'availableTime');
    return legacy == null ? const [] : [_timeRangeFromDocument(legacy)];
  }

  VisitTimeRange _timeRangeFromDocument(Map<String, Object?> document) {
    return VisitTimeRange(
      start: LocalTime.parse(_requiredString(document, 'start')),
      end: LocalTime.parse(_requiredString(document, 'end')),
    );
  }

  Map<String, Object?>? _contactToDocument(CampaignContact? contact) {
    if (contact == null) {
      return null;
    }
    return {'name': contact.name, 'phone': contact.phone};
  }

  CampaignContact? _contactFromDocument(Map<String, Object?>? document) {
    if (document == null) {
      return null;
    }
    return CampaignContact(
      name: _optionalString(document, 'name'),
      phone: _optionalString(document, 'phone'),
    );
  }

  Map<String, Object?>? _moneyToDocument(Money? money) {
    if (money == null) {
      return null;
    }
    return {'amount': money.amount, 'currency': money.currency.name};
  }

  Money? _moneyFromDocument(Map<String, Object?>? document) {
    if (document == null) {
      return null;
    }
    final currency = _requiredString(document, 'currency');
    if (currency != Currency.krw.name) {
      throw FormatException('Unsupported currency: $currency');
    }
    return Money.won(_requiredInt(document, 'amount'));
  }

  VisitStatus _visitStatusFromDocument(Map<String, Object?> document) {
    final value = _requiredString(document, 'visitStatus');
    return VisitStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => throw FormatException('Unsupported visit status: $value'),
    );
  }

  PostingStatus _postingStatusFromDocument(Map<String, Object?> document) {
    final value = _requiredString(document, 'postingStatus');
    final status = PostingStatus.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => throw FormatException('Unsupported posting status: $value'),
    );
    if (!status.canBeStored) {
      throw const FormatException('PostingStatus.overdue must not be stored.');
    }
    return status;
  }
}

String _requiredString(Map<String, Object?> document, String key) {
  return _asString(document[key], key);
}

String? _optionalString(Map<String, Object?> document, String key) {
  final value = document[key];
  return value == null ? null : _asString(value, key);
}

String _asString(Object? value, String key) {
  if (value case final String stringValue) {
    return stringValue;
  }
  throw FormatException('$key must be a string.');
}

int _requiredInt(Map<String, Object?> document, String key) {
  return _asInt(document[key], key);
}

int _asInt(Object? value, String key) {
  if (value case final int intValue) {
    return intValue;
  }
  throw FormatException('$key must be an integer.');
}

List<Object?> _requiredList(Map<String, Object?> document, String key) {
  final value = _optionalList(document, key);
  if (value != null) {
    return value;
  }
  throw FormatException('$key must be a list.');
}

List<Object?>? _optionalList(Map<String, Object?> document, String key) {
  final value = document[key];
  if (value == null) {
    return null;
  }
  if (value case final List<Object?> listValue) {
    return listValue;
  }
  throw FormatException('$key must be a list.');
}

Map<String, Object?> _requiredMap(Map<String, Object?> document, String key) {
  final value = _optionalMap(document, key);
  if (value == null) {
    throw FormatException('$key must be a map.');
  }
  return value;
}

Map<String, Object?>? _optionalMap(Map<String, Object?> document, String key) {
  final value = document[key];
  if (value == null) {
    return null;
  }
  return _asMap(value, key);
}

Map<String, Object?> _asMap(Object? value, String key) {
  if (value case final Map<String, Object?> mapValue) {
    return mapValue;
  }
  throw FormatException('$key must be a map.');
}

LocalDate? _optionalDate(Map<String, Object?> document, String key) {
  final value = _optionalString(document, key);
  return value == null ? null : LocalDate.parse(value);
}

LocalTime? _optionalTime(Map<String, Object?> document, String key) {
  final value = _optionalString(document, key);
  return value == null ? null : LocalTime.parse(value);
}

DateTime _requiredInstant(Map<String, Object?> document, String key) {
  final value = DateTime.parse(_requiredString(document, key));
  if (!value.isUtc) {
    throw FormatException('$key must use UTC.');
  }
  return value;
}

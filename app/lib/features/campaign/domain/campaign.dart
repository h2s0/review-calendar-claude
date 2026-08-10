import 'package:review_calendar/features/campaign/domain/campaign_id.dart';
import 'package:review_calendar/features/campaign/domain/campaign_status.dart';
import 'package:review_calendar/features/campaign/domain/local_date.dart';
import 'package:review_calendar/features/campaign/domain/money.dart';
import 'package:review_calendar/features/campaign/domain/visit_schedule.dart';
import 'package:review_calendar/features/settings/domain/notification_settings.dart';

final class CampaignContact {
  CampaignContact({String? name, String? phone})
    : name = _optionalText(name, 'contact name'),
      phone = _optionalText(phone, 'contact phone');

  final String? name;
  final String? phone;
}

final class Campaign {
  Campaign({
    required this.id,
    required this.ownerId,
    required String brand,
    required this.visitAvailability,
    required this.status,
    required this.deadline,
    required this.createdAt,
    required this.updatedAt,
    VisitTimeRange? availableTime,
    Iterable<VisitTimeRange> availableTimes = const [],
    this.visit = const VisitSchedule(),
    this.originalDeadline,
    this.contact,
    this.sponsoredValue,
    this.cashFee,
    this.publishedDate,
    this.notificationSettings = const CampaignNotificationSettings(),
    String? platform,
    String? category,
    String? notes,
    String? postUrl,
  }) : brand = _requiredText(brand, 'brand'),
       availableTimes = _resolveAvailableTimes(availableTime, availableTimes),
       platform = _optionalText(platform, 'platform'),
       category = _optionalText(category, 'category'),
       notes = notes?.trim() ?? '',
       postUrl = _optionalUrl(postUrl) {
    if (!createdAt.isUtc || !updatedAt.isUtc) {
      throw ArgumentError('Campaign timestamps must use UTC.');
    }
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError('updatedAt must not precede createdAt.');
    }
    if (status.posting != PostingStatus.published &&
        (publishedDate != null || this.postUrl != null)) {
      throw ArgumentError(
        'Publication metadata requires a published posting status.',
      );
    }
  }

  final CampaignId id;
  final UserId ownerId;
  final String brand;
  final String? platform;
  final String? category;
  final VisitAvailability visitAvailability;
  final CampaignStatus status;
  final List<VisitTimeRange> availableTimes;
  VisitTimeRange? get availableTime => availableTimes.firstOrNull;
  final VisitSchedule visit;
  final LocalDate deadline;
  final LocalDate? originalDeadline;
  final CampaignContact? contact;
  final String notes;
  final Money? sponsoredValue;
  final Money? cashFee;
  final LocalDate? publishedDate;
  final Uri? postUrl;
  final CampaignNotificationSettings notificationSettings;
  final DateTime createdAt;
  final DateTime updatedAt;

  Campaign withVisitSchedule({
    required VisitSchedule visit,
    required DateTime updatedAt,
    CampaignStatus? status,
  }) {
    return Campaign(
      id: id,
      ownerId: ownerId,
      brand: brand,
      platform: platform,
      category: category,
      visitAvailability: visitAvailability,
      availableTimes: availableTimes,
      visit: visit,
      status: status ?? this.status,
      deadline: deadline,
      originalDeadline: originalDeadline,
      contact: contact,
      notes: notes,
      sponsoredValue: sponsoredValue,
      cashFee: cashFee,
      publishedDate: publishedDate,
      postUrl: postUrl?.toString(),
      notificationSettings: notificationSettings,
      createdAt: createdAt,
      updatedAt: updatedAt.toUtc(),
    );
  }

  Campaign withLifecycle({
    required CampaignStatus status,
    required DateTime updatedAt,
    VisitSchedule? visit,
  }) {
    return Campaign(
      id: id,
      ownerId: ownerId,
      brand: brand,
      platform: platform,
      category: category,
      visitAvailability: visitAvailability,
      availableTimes: availableTimes,
      visit: visit ?? this.visit,
      status: status,
      deadline: deadline,
      originalDeadline: originalDeadline,
      contact: contact,
      notes: notes,
      sponsoredValue: sponsoredValue,
      cashFee: cashFee,
      publishedDate: publishedDate,
      postUrl: postUrl?.toString(),
      notificationSettings: notificationSettings,
      createdAt: createdAt,
      updatedAt: updatedAt.toUtc(),
    );
  }

  Campaign withPublication({
    required CampaignStatus status,
    required DateTime updatedAt,
    LocalDate? publishedDate,
    String? postUrl,
  }) {
    return Campaign(
      id: id,
      ownerId: ownerId,
      brand: brand,
      platform: platform,
      category: category,
      visitAvailability: visitAvailability,
      availableTimes: availableTimes,
      visit: visit,
      status: status,
      deadline: deadline,
      originalDeadline: originalDeadline,
      contact: contact,
      notes: notes,
      sponsoredValue: sponsoredValue,
      cashFee: cashFee,
      publishedDate: publishedDate,
      postUrl: postUrl,
      notificationSettings: notificationSettings,
      createdAt: createdAt,
      updatedAt: updatedAt.toUtc(),
    );
  }

  Campaign withNotificationSettings({
    required CampaignNotificationSettings notificationSettings,
    required DateTime updatedAt,
  }) {
    return Campaign(
      id: id,
      ownerId: ownerId,
      brand: brand,
      platform: platform,
      category: category,
      visitAvailability: visitAvailability,
      availableTimes: availableTimes,
      visit: visit,
      status: status,
      deadline: deadline,
      originalDeadline: originalDeadline,
      contact: contact,
      notes: notes,
      sponsoredValue: sponsoredValue,
      cashFee: cashFee,
      publishedDate: publishedDate,
      postUrl: postUrl?.toString(),
      notificationSettings: notificationSettings,
      createdAt: createdAt,
      updatedAt: updatedAt.toUtc(),
    );
  }
}

String _requiredText(String value, String fieldName) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must not be empty');
  }
  return normalized;
}

String? _optionalText(String? value, String fieldName) {
  if (value == null) {
    return null;
  }
  return _requiredText(value, fieldName);
}

Uri? _optionalUrl(String? value) {
  final normalized = _optionalText(value, 'post URL');
  if (normalized == null) {
    return null;
  }
  final uri = Uri.tryParse(normalized);
  if (uri == null ||
      !uri.hasAuthority ||
      (uri.scheme != 'https' && uri.scheme != 'http')) {
    throw ArgumentError.value(value, 'post URL', 'must be an HTTP(S) URL');
  }
  return uri;
}

List<VisitTimeRange> _resolveAvailableTimes(
  VisitTimeRange? legacyValue,
  Iterable<VisitTimeRange> values,
) {
  final ranges = values.toList(growable: false);
  if (legacyValue != null && ranges.isNotEmpty) {
    throw ArgumentError(
      'Use either availableTime or availableTimes, not both.',
    );
  }
  return List.unmodifiable(legacyValue == null ? ranges : [legacyValue]);
}

import 'package:review_calendar/features/campaign/domain/local_date.dart';
import 'package:review_calendar/features/campaign/domain/local_time.dart';
import 'package:review_calendar/features/campaign/domain/money.dart';
import 'package:review_calendar/features/campaign/domain/visit_schedule.dart';

/// Ported verbatim from
/// review-calendar/app/lib/features/registration/domain/campaign_registration_draft.dart
enum CampaignDraftField {
  brand,
  visitAvailability,
  deadline,
  availableTimes,
  sponsoredValue,
  cashFee,
}

sealed class VisitAvailabilityDraft {
  const VisitAvailabilityDraft();
}

final class VisitDateOptionsDraft extends VisitAvailabilityDraft {
  const VisitDateOptionsDraft(this.dates);

  final List<String> dates;
}

final class VisitDateRangeDraft extends VisitAvailabilityDraft {
  const VisitDateRangeDraft({required this.start, required this.end});

  final String start;
  final String end;
}

final class VisitTimeRangeDraft {
  const VisitTimeRangeDraft({required this.start, required this.end});

  final String start;
  final String end;
}

final class CampaignRegistrationDraft {
  const CampaignRegistrationDraft({
    this.brand = '',
    this.visitAvailability,
    this.deadline = '',
    this.platform = '',
    this.category = '',
    this.contactName = '',
    this.contactPhone = '',
    this.notes = '',
    this.sponsoredValue = '',
    this.cashFee = '',
    this.availableTimes = const [],
    this.deadlineAlertDaysBefore,
  });

  final String brand;
  final VisitAvailabilityDraft? visitAvailability;
  final String deadline;
  final String platform;
  final String category;
  final String contactName;
  final String contactPhone;
  final String notes;
  final String sponsoredValue;
  final String cashFee;
  final List<VisitTimeRangeDraft> availableTimes;
  // Non-null: notify this many days before `deadline`. Null: deadline
  // notifications disabled — not the sibling's `InheritNotification` third
  // state, since a brand-new campaign has no global settings to inherit
  // from yet. Extends the ported draft to carry this project's upload
  // form's alert-days picker, which the sibling's own registration screen
  // doesn't expose the same way.
  final int? deadlineAlertDaysBefore;

  CampaignRegistrationDraft copyWith({
    String? brand,
    VisitAvailabilityDraft? visitAvailability,
    String? deadline,
    String? platform,
    String? category,
    String? contactName,
    String? contactPhone,
    String? notes,
    String? sponsoredValue,
    String? cashFee,
    List<VisitTimeRangeDraft>? availableTimes,
    int? deadlineAlertDaysBefore,
  }) {
    return CampaignRegistrationDraft(
      brand: brand ?? this.brand,
      visitAvailability: visitAvailability ?? this.visitAvailability,
      deadline: deadline ?? this.deadline,
      platform: platform ?? this.platform,
      category: category ?? this.category,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      notes: notes ?? this.notes,
      sponsoredValue: sponsoredValue ?? this.sponsoredValue,
      cashFee: cashFee ?? this.cashFee,
      availableTimes: availableTimes ?? this.availableTimes,
      deadlineAlertDaysBefore:
          deadlineAlertDaysBefore ?? this.deadlineAlertDaysBefore,
    );
  }

  CampaignDraftValidation validate() {
    final errors = <CampaignDraftField, String>{};

    final normalizedBrand = brand.trim();
    if (normalizedBrand.isEmpty) {
      errors[CampaignDraftField.brand] = '업체명을 입력해 주세요.';
    }

    final availability = _validateAvailability(errors);
    final parsedDeadline = _parseRequiredDate(
      deadline,
      CampaignDraftField.deadline,
      '포스팅 마감일',
      errors,
    );
    final parsedTimes = _validateTimes(errors);
    final parsedSponsoredValue = _parseOptionalMoney(
      sponsoredValue,
      CampaignDraftField.sponsoredValue,
      errors,
    );
    final parsedCashFee = _parseOptionalMoney(
      cashFee,
      CampaignDraftField.cashFee,
      errors,
    );

    if (errors.isNotEmpty || availability == null || parsedDeadline == null) {
      return CampaignDraftInvalid(Map.unmodifiable(errors));
    }

    return CampaignDraftValid(
      ValidatedCampaignRegistrationDraft(
        brand: normalizedBrand,
        visitAvailability: availability,
        deadline: parsedDeadline,
        platform: _optionalText(platform),
        category: _optionalText(category),
        contactName: _optionalText(contactName),
        contactPhone: _optionalText(contactPhone),
        notes: notes.trim(),
        sponsoredValue: parsedSponsoredValue,
        cashFee: parsedCashFee,
        availableTimes: List.unmodifiable(parsedTimes),
        deadlineAlertDaysBefore: deadlineAlertDaysBefore,
      ),
    );
  }

  VisitAvailability? _validateAvailability(
    Map<CampaignDraftField, String> errors,
  ) {
    final draft = visitAvailability;
    if (draft == null) {
      errors[CampaignDraftField.visitAvailability] =
          '방문 가능한 날짜 또는 기간을 선택해 주세요.';
      return null;
    }
    try {
      return switch (draft) {
        VisitDateOptionsDraft(:final dates) => VisitDateOptions(
          dates.map(LocalDate.parse),
        ),
        VisitDateRangeDraft(:final start, :final end) => VisitDateRange(
          start: LocalDate.parse(start.trim()),
          end: LocalDate.parse(end.trim()),
        ),
      };
    } on FormatException {
      errors[CampaignDraftField.visitAvailability] =
          '방문 가능한 날짜 또는 기간을 확인해 주세요.';
      return null;
    } on ArgumentError {
      errors[CampaignDraftField.visitAvailability] =
          '방문 가능한 날짜 또는 기간을 확인해 주세요.';
      return null;
    }
  }

  List<VisitTimeRange> _validateTimes(Map<CampaignDraftField, String> errors) {
    try {
      return [
        for (final range in availableTimes)
          VisitTimeRange(
            start: LocalTime.parse(range.start.trim()),
            end: LocalTime.parse(range.end.trim()),
          ),
      ];
    } on FormatException {
      errors[CampaignDraftField.availableTimes] = '방문 가능한 시간 범위를 확인해 주세요.';
      return const [];
    } on ArgumentError {
      errors[CampaignDraftField.availableTimes] = '방문 가능한 시간 범위를 확인해 주세요.';
      return const [];
    }
  }
}

sealed class CampaignDraftValidation {
  const CampaignDraftValidation();
}

final class CampaignDraftValid extends CampaignDraftValidation {
  const CampaignDraftValid(this.value);

  final ValidatedCampaignRegistrationDraft value;
}

final class CampaignDraftInvalid extends CampaignDraftValidation {
  const CampaignDraftInvalid(this.errors);

  final Map<CampaignDraftField, String> errors;
}

final class ValidatedCampaignRegistrationDraft {
  const ValidatedCampaignRegistrationDraft({
    required this.brand,
    required this.visitAvailability,
    required this.deadline,
    required this.notes,
    required this.availableTimes,
    this.platform,
    this.category,
    this.contactName,
    this.contactPhone,
    this.sponsoredValue,
    this.cashFee,
    this.deadlineAlertDaysBefore,
  });

  final String brand;
  final VisitAvailability visitAvailability;
  final LocalDate deadline;
  final String? platform;
  final String? category;
  final String? contactName;
  final String? contactPhone;
  final String notes;
  final Money? sponsoredValue;
  final Money? cashFee;
  final List<VisitTimeRange> availableTimes;
  final int? deadlineAlertDaysBefore;
}

LocalDate? _parseRequiredDate(
  String value,
  CampaignDraftField field,
  String label,
  Map<CampaignDraftField, String> errors,
) {
  if (value.trim().isEmpty) {
    errors[field] = '$label을 선택해 주세요.';
    return null;
  }
  try {
    return LocalDate.parse(value.trim());
  } on FormatException {
    errors[field] = '$label 날짜를 확인해 주세요.';
    return null;
  } on ArgumentError {
    errors[field] = '$label 날짜를 확인해 주세요.';
    return null;
  }
}

Money? _parseOptionalMoney(
  String value,
  CampaignDraftField field,
  Map<CampaignDraftField, String> errors,
) {
  final normalized = value.trim().replaceAll(',', '');
  if (normalized.isEmpty) {
    return null;
  }
  final amount = int.tryParse(normalized);
  if (amount == null || amount < 0) {
    errors[field] = '0원 이상의 금액을 숫자로 입력해 주세요.';
    return null;
  }
  return Money.won(amount);
}

Uri? parseOptionalHttpUrl(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(normalized);
  if (uri == null ||
      !uri.hasAuthority ||
      (uri.scheme != 'https' && uri.scheme != 'http')) {
    throw const FormatException('URL은 http:// 또는 https://로 시작해야 합니다.');
  }
  return uri;
}

String? _optionalText(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

import 'package:review_calendar/features/registration/domain/campaign_registration_draft.dart';

/// Ported verbatim from
/// review-calendar/app/lib/features/registration/domain/campaign_analysis.dart
/// (the `temporary_analysis_image.dart`-dependent remote/Cloud-Function path
/// isn't ported — this project uses the local, on-device OCR path only, see
/// `local_campaign_ocr.dart`)
class CampaignAnalysisResult {
  const CampaignAnalysisResult({
    this.brand = const CampaignAnalysisField<String>(),
    this.platform = const CampaignAnalysisField<String>(),
    this.category = const CampaignAnalysisField<String>(),
    this.visitAvailability =
        const CampaignAnalysisField<CampaignAnalysisVisitAvailability>(),
    this.availableTimes =
        const CampaignAnalysisField<List<VisitTimeRangeDraft>>(),
    this.deadline = const CampaignAnalysisField<String>(),
    this.contactName = const CampaignAnalysisField<String>(),
    this.contactPhone = const CampaignAnalysisField<String>(),
    this.sponsoredValue = const CampaignAnalysisField<int>(),
    this.cashFee = const CampaignAnalysisField<int>(),
    this.notes = const CampaignAnalysisField<String>(),
    this.rawDeadlineText = const CampaignAnalysisField<String>(),
    this.mixedCampaignWarning = const CampaignAnalysisMixedCampaignWarning(),
  });

  final CampaignAnalysisField<String> brand;
  final CampaignAnalysisField<String> platform;
  final CampaignAnalysisField<String> category;
  final CampaignAnalysisField<CampaignAnalysisVisitAvailability>
  visitAvailability;
  final CampaignAnalysisField<List<VisitTimeRangeDraft>> availableTimes;
  final CampaignAnalysisField<String> deadline;
  final CampaignAnalysisField<String> contactName;
  final CampaignAnalysisField<String> contactPhone;
  final CampaignAnalysisField<int> sponsoredValue;
  final CampaignAnalysisField<int> cashFee;
  final CampaignAnalysisField<String> notes;
  final CampaignAnalysisField<String> rawDeadlineText;
  final CampaignAnalysisMixedCampaignWarning mixedCampaignWarning;

  Set<String> get reviewFields => {
    if (brand.value == null || brand.requiresReview) 'brand',
    if (platform.value != null && platform.requiresReview) 'platform',
    if (category.value != null && category.requiresReview) 'category',
    if (visitAvailability.value == null || visitAvailability.requiresReview)
      'visitAvailability',
    if (availableTimes.value != null && availableTimes.requiresReview)
      'availableTimes',
    if (deadline.value == null || deadline.requiresReview) 'deadline',
    if (contactName.value != null && contactName.requiresReview) 'contactName',
    if (contactPhone.value != null && contactPhone.requiresReview)
      'contactPhone',
    if (sponsoredValue.value != null && sponsoredValue.requiresReview)
      'sponsoredValue',
    if (cashFee.value != null && cashFee.requiresReview) 'cashFee',
    if (notes.value != null && notes.requiresReview) 'notes',
  };

  bool get mixedCampaignSuspected => mixedCampaignWarning.suspected;

  String? get mixedCampaignMessage => mixedCampaignWarning.message;

  CampaignRegistrationDraft toRegistrationDraft() {
    final visit = visitAvailability.value;

    return CampaignRegistrationDraft(
      brand: brand.value ?? '',
      platform: platform.value ?? '',
      category: category.value ?? '',
      visitAvailability: visit == null
          ? null
          : visit.endDate == null ||
                visit.endDate!.isEmpty ||
                visit.endDate == visit.startDate
          ? VisitDateOptionsDraft([visit.startDate])
          : VisitDateRangeDraft(start: visit.startDate, end: visit.endDate!),
      deadline: deadline.value ?? '',
      contactName: contactName.value ?? '',
      contactPhone: contactPhone.value ?? '',
      sponsoredValue: sponsoredValue.value?.toString() ?? '',
      cashFee: cashFee.value?.toString() ?? '',
      notes: notes.value ?? '',
      availableTimes: availableTimes.value ?? const [],
    );
  }
}

class CampaignAnalysisField<T> {
  const CampaignAnalysisField({
    this.value,
    this.confidence = 0,
    this.needsReview = true,
    this.evidence,
  });

  const CampaignAnalysisField.confirmed(
    T this.value, {
    this.confidence = 1,
    this.evidence,
  }) : needsReview = false;

  final T? value;
  final double confidence;
  final bool needsReview;
  final String? evidence;

  bool get requiresReview => needsReview || confidence < 0.75;
}

class CampaignAnalysisVisitAvailability {
  const CampaignAnalysisVisitAvailability({
    required this.startDate,
    this.endDate,
  });

  final String startDate;
  final String? endDate;
}

class CampaignAnalysisMixedCampaignWarning {
  const CampaignAnalysisMixedCampaignWarning({
    this.suspected = false,
    this.message,
  });

  final bool suspected;
  final String? message;
}

enum CampaignAnalysisFailure { timeout, offline, server, invalidResponse }

class CampaignAnalysisException implements Exception {
  const CampaignAnalysisException(this.failure, {this.partialResult});

  final CampaignAnalysisFailure failure;
  final CampaignAnalysisResult? partialResult;
}

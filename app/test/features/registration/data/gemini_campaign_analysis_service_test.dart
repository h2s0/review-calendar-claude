import 'package:flutter_test/flutter_test.dart';
import 'package:review_calendar/features/registration/data/gemini_campaign_analysis_service.dart';

/// Covers `resultFromJson` — the pure JSON-to-domain-model half of
/// `GeminiCampaignAnalysisService` — without touching Storage/Functions.
void main() {
  test('maps a complete, well-typed response into every field', () {
    final result = resultFromJson({
      'brand': {
        'value': '성수 브런치',
        'confidence': 0.99,
        'needsReview': false,
        'evidence': '성수 브런치',
      },
      'platform': {
        'value': '블로그',
        'confidence': 0.9,
        'needsReview': false,
        'evidence': null,
      },
      'category': {
        'value': '맛집',
        'confidence': 0.8,
        'needsReview': false,
        'evidence': null,
      },
      'visitAvailability': {
        'value': {'startDate': '2026-08-12', 'endDate': '2026-08-14'},
        'confidence': 0.97,
        'needsReview': false,
        'evidence': null,
      },
      'availableTimes': {
        'value': [
          {'start': '11:30', 'end': '20:00'},
        ],
        'confidence': 0.88,
        'needsReview': false,
        'evidence': null,
      },
      'deadline': {
        'value': '2026-08-20',
        'confidence': 0.98,
        'needsReview': false,
        'evidence': null,
      },
      'contactName': {
        'value': '김담당',
        'confidence': 0.9,
        'needsReview': false,
        'evidence': null,
      },
      'contactPhone': {
        'value': '010-1234-5678',
        'confidence': 0.95,
        'needsReview': false,
        'evidence': null,
      },
      'sponsoredValue': {
        'value': 68000,
        'confidence': 0.96,
        'needsReview': false,
        'evidence': null,
      },
      'cashFee': {
        'value': null,
        'confidence': 0,
        'needsReview': true,
        'evidence': null,
      },
      'notes': {
        'value': '방문 하루 전 예약',
        'confidence': 0.85,
        'needsReview': false,
        'evidence': null,
      },
      'rawDeadlineText': {
        'value': '8월 20일까지',
        'confidence': 0.98,
        'needsReview': false,
        'evidence': null,
      },
      'mixedCampaignWarning': {'suspected': false, 'message': null},
    });

    expect(result.brand.value, '성수 브런치');
    expect(result.platform.value, '블로그');
    expect(result.category.value, '맛집');
    expect(result.visitAvailability.value?.startDate, '2026-08-12');
    expect(result.visitAvailability.value?.endDate, '2026-08-14');
    expect(result.availableTimes.value?.single.start, '11:30');
    expect(result.availableTimes.value?.single.end, '20:00');
    expect(result.deadline.value, '2026-08-20');
    expect(result.contactName.value, '김담당');
    expect(result.contactPhone.value, '010-1234-5678');
    expect(result.sponsoredValue.value, 68000);
    expect(result.cashFee.value, isNull);
    expect(result.cashFee.needsReview, isTrue);
    expect(result.notes.value, '방문 하루 전 예약');
    expect(result.mixedCampaignWarning.suspected, isFalse);
  });

  test('parses correctly when nested maps arrive as Map<Object?, Object?> '
      '(how the Functions platform channel actually deserializes them)', () {
    final raw = <Object?, Object?>{
      'brand': <Object?, Object?>{
        'value': '르봉',
        'confidence': 0.9,
        'needsReview': false,
        'evidence': null,
      },
      'visitAvailability': <Object?, Object?>{
        'value': <Object?, Object?>{'startDate': '2026-08-01', 'endDate': null},
        'confidence': 0.9,
        'needsReview': false,
        'evidence': null,
      },
      'availableTimes': <Object?, Object?>{
        'value': <Object?>[
          <Object?, Object?>{'start': '09:00', 'end': '10:00'},
        ],
        'confidence': 0.9,
        'needsReview': false,
        'evidence': null,
      },
      'mixedCampaignWarning': <Object?, Object?>{
        'suspected': true,
        'message': '충돌',
      },
    };

    final result = resultFromJson(raw);

    expect(result.brand.value, '르봉');
    expect(result.visitAvailability.value?.startDate, '2026-08-01');
    expect(result.visitAvailability.value?.endDate, isNull);
    expect(result.availableTimes.value?.single.start, '09:00');
    expect(result.mixedCampaignWarning.suspected, isTrue);
    expect(result.mixedCampaignWarning.message, '충돌');
  });

  test('leaves every field unset for a missing/null/malformed response', () {
    expect(resultFromJson(null).brand.value, isNull);
    expect(resultFromJson(null).reviewFields, contains('brand'));
    expect(resultFromJson('not a map').brand.value, isNull);
    expect(resultFromJson(<String, dynamic>{}).sponsoredValue.value, isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:review_calendar/features/registration/domain/local_campaign_ocr.dart';

/// Ported verbatim from
/// review-calendar/app/test/features/registration/domain/local_campaign_ocr_test.dart
/// — `parseCampaignOcrText` itself was ported byte-for-byte, so its test
/// fixtures apply unchanged.
void main() {
  test('confirms fields extracted from explicit Korean labels', () {
    final result = parseCampaignOcrText('''
업체: 성수 브런치
카테고리 맛집
방문 가능 2026년 8월 12일, 8월 14일
포스팅 마감 2026-08-20까지
제공 금액 68,000원
담당자 010-1234-5678
방문 하루 전 예약 필수
''');

    expect(result.brand.value, '성수 브런치');
    expect(result.category.value, '맛집');
    expect(result.visitAvailability.value?.startDate, '2026-08-12');
    expect(result.visitAvailability.value?.endDate, '2026-08-14');
    expect(result.deadline.value, '2026-08-20');
    expect(result.contactPhone.value, '010-1234-5678');
    expect(result.sponsoredValue.value, 68000);
    expect(result.notes.value, contains('예약 필수'));
    expect(result.reviewFields, isEmpty);
  });

  test('converts Korean ten-thousand won notation to sponsored value', () {
    final result = parseCampaignOcrText('''
업체: 르봉
방문 가능 2026년 8월 12일
포스팅 마감 2026년 8월 13일
10만원 상당 식사권 제공
''');

    expect(result.sponsoredValue.value, 100000);
    expect(result.sponsoredValue.requiresReview, isFalse);
    expect(result.reviewFields, isEmpty);
  });

  test('leaves brand empty instead of guessing from an unlabeled line', () {
    final result = parseCampaignOcrText('''
성수 브런치
방문 가능 2026년 8월 12일
포스팅 마감 2026년 8월 13일
''');

    expect(result.brand.value, isNull);
    expect(result.reviewFields, {'brand'});
  });

  test('asks to review sponsored value when multiple amounts are present', () {
    final result = parseCampaignOcrText('''
업체: 르봉
방문 가능 2026년 8월 12일
포스팅 마감 2026년 8월 13일
5만원 식사권과 1만원 음료권 제공
''');

    expect(result.sponsoredValue.value, 50000);
    expect(result.reviewFields, {'sponsoredValue'});
  });

  test('extracts original price from actual Apple Vision output', () {
    final result = parseCampaignOcrText('''
어떤 체험단을 찾고 있나요?
스페셜 V라인 괄사관리/여자관리사/원가 10만원
방문 정보
방문 주소
서울 영등포구 대림로 153
''');

    expect(result.sponsoredValue.value, 100000);
    expect(result.sponsoredValue.requiresReview, isFalse);
  });

  test('extracts fields from multiline case1 Vision output', () {
    final result = parseCampaignOcrText('''
방문 주소
서울 양천구 신정동 128-113 헬로우워크 목동점
체험 가능 시간 : 오전 8시 ~ 오후 11시 30분
담당자 연락처
010-3334-2536
체험단 미션
블로그
체험기간
8/1 (토)~8/14 (금)
리뷰 마감
8/14 (금)
2026년 8월
목동 공유오피스
''');

    expect(result.brand.value, '헬로우워크 목동점');
    expect(result.platform.value, '블로그');
    expect(result.category.value, '생활');
    expect(result.visitAvailability.value?.startDate, '2026-08-01');
    expect(result.visitAvailability.value?.endDate, '2026-08-14');
    expect(result.deadline.value, '2026-08-14');
    expect(result.contactPhone.value, '010-3334-2536');
    expect(result.availableTimes.value?.single.start, '08:00');
    expect(result.availableTimes.value?.single.end, '23:30');
  });
}

import 'package:flutter/material.dart';

import 'review_calendar_models.dart';

/// Verbatim transliteration of the design prototype's `data.jsx` — same
/// brands, dates, and amounts — so every screen renders identically to the
/// source mockup. April 2026.
abstract final class MockReviewCalendarData {
  static DateTime d(int month, int day) => DateTime(2026, month, day);

  static final today = d(4, 20);

  static final List<Campaign> campaigns = [
    Campaign(
      id: 'c1',
      brand: '르봉 파스타바 성수점',
      category: '맛집',
      visitStart: d(4, 18),
      visitEnd: d(4, 28),
      deadline: d(5, 2),
      reward: const Reward(type: RewardType.sponsor, amount: 68000),
      alertDays: 3,
      platform: '레뷰',
      status: CampaignStatus.upcoming,
      notes: '2인 식사 / 파스타+스테이크 포함 / 영수증 리뷰 필수',
    ),
    Campaign(
      id: 'c2',
      brand: '포레스트 향수 디퓨저',
      category: '뷰티',
      visitStart: d(4, 15),
      visitEnd: d(4, 15),
      deadline: d(4, 22),
      reward: const Reward(type: RewardType.sponsor, amount: 45000),
      alertDays: 2,
      platform: '디너의여왕',
      status: CampaignStatus.urgent,
      notes: '제품 수령 완료 / 사진 5장 이상',
    ),
    Campaign(
      id: 'c3',
      brand: '카페 오로라 연남',
      category: '카페',
      visitStart: d(4, 22),
      visitEnd: d(4, 22),
      deadline: d(4, 29),
      reward: const Reward(type: RewardType.sponsor, amount: 32000),
      alertDays: 3,
      platform: '레뷰',
      status: CampaignStatus.upcoming,
      notes: '브런치 세트 1인',
    ),
    Campaign(
      id: 'c4',
      brand: '핏앤슬림 단백질 쉐이크',
      category: '건강식품',
      visitStart: d(4, 8),
      visitEnd: d(4, 8),
      deadline: d(4, 19),
      reward: const Reward(type: RewardType.fee, amount: 50000),
      alertDays: 5,
      platform: '체험뷰',
      status: CampaignStatus.posted,
      notes: '2주 섭취 후기',
      posted: d(4, 17),
    ),
    Campaign(
      id: 'c5',
      brand: '루나 수면 스프레이',
      category: '뷰티',
      visitStart: d(4, 5),
      visitEnd: d(4, 5),
      deadline: d(4, 14),
      reward: const Reward(type: RewardType.sponsor, amount: 28000),
      alertDays: 3,
      platform: '스토리앤미디어',
      status: CampaignStatus.posted,
      posted: d(4, 13),
    ),
  ];

  static Campaign? campaignById(String id) {
    for (final c in campaigns) {
      if (c.id == id) return c;
    }
    return null;
  }

  static final List<ReviewIdea> ideas = [
    ReviewIdea(
      id: 'i1',
      title: '봄철 피크닉 카페 5선',
      desc: '연남·성수 위주',
      plannedDate: d(4, 25),
    ),
    const ReviewIdea(id: 'i2', title: '홈카페 원두 비교', desc: '3종 블라인드 테이스팅'),
  ];

  static final List<UndecidedVisit> undecided = [
    UndecidedVisit(
      id: 'u1',
      campaignId: 'c1b',
      brand: '소풍 베이커리 합정',
      category: '카페',
      visit: const VisitSlotValue(),
      deadline: d(5, 10),
      visitWindow: VisitWindow(start: d(4, 21), end: d(4, 27)),
      note: '방문 날짜 미정',
    ),
    UndecidedVisit(
      id: 'u2',
      campaignId: 'c2b',
      brand: '와인바 라크루즈',
      category: '맛집',
      visit: VisitSlotValue(date: d(4, 24)),
      deadline: d(5, 1),
      visitWindow: VisitWindow(start: d(4, 23), end: d(4, 30)),
      note: '시간 미정',
    ),
  ];

  static final List<CalendarEvent> events = [
    CalendarEvent(
      date: d(4, 18),
      type: CalendarEventType.visit,
      label: '르봉 파스타바 방문 시작',
      campaignId: 'c1',
    ),
    CalendarEvent(
      date: d(4, 28),
      type: CalendarEventType.visit,
      label: '르봉 방문 종료',
      campaignId: 'c1',
    ),
    CalendarEvent(
      date: d(5, 2),
      type: CalendarEventType.deadline,
      label: '르봉 파스타바 마감',
      campaignId: 'c1',
    ),
    CalendarEvent(
      date: d(4, 15),
      type: CalendarEventType.visit,
      label: '포레스트 향수 수령',
      campaignId: 'c2',
    ),
    CalendarEvent(
      date: d(4, 22),
      type: CalendarEventType.deadline,
      label: '포레스트 향수 마감',
      campaignId: 'c2',
    ),
    CalendarEvent(
      date: d(4, 22),
      type: CalendarEventType.visit,
      label: '카페 오로라 방문',
      campaignId: 'c3',
    ),
    CalendarEvent(
      date: d(4, 29),
      type: CalendarEventType.deadline,
      label: '카페 오로라 마감',
      campaignId: 'c3',
    ),
    CalendarEvent(
      date: d(4, 19),
      type: CalendarEventType.deadline,
      label: '핏앤슬림 마감',
      campaignId: 'c4',
    ),
    CalendarEvent(
      date: d(4, 17),
      type: CalendarEventType.posted,
      label: '핏앤슬림 포스팅',
      campaignId: 'c4',
    ),
    CalendarEvent(
      date: d(4, 14),
      type: CalendarEventType.deadline,
      label: '루나 스프레이 마감',
      campaignId: 'c5',
    ),
    CalendarEvent(
      date: d(4, 13),
      type: CalendarEventType.posted,
      label: '루나 스프레이 포스팅',
      campaignId: 'c5',
    ),
    CalendarEvent(
      date: d(4, 5),
      type: CalendarEventType.posted,
      label: '벚꽃 명소 정리글',
      freeform: true,
    ),
    CalendarEvent(
      date: d(4, 10),
      type: CalendarEventType.posted,
      label: '4월 다꾸 기록',
      freeform: true,
    ),
  ];

  static List<CalendarEvent> eventsOn(DateTime date) => events
      .where(
        (e) =>
            e.date.year == date.year &&
            e.date.month == date.month &&
            e.date.day == date.day,
      )
      .toList();

  static final revenue = RevenueSummary(
    total: 223000,
    sponsor: 173000,
    fee: 50000,
    thisMonth: 223000,
    lastMonth: 186000,
    trend: const [
      MonthlyRevenue(month: '1월', total: 142000, sponsor: 112000, fee: 30000),
      MonthlyRevenue(month: '2월', total: 168000, sponsor: 128000, fee: 40000),
      MonthlyRevenue(month: '3월', total: 186000, sponsor: 146000, fee: 40000),
      MonthlyRevenue(month: '4월', total: 223000, sponsor: 173000, fee: 50000),
    ],
    byCategory: const [
      CategoryRevenue(
        name: '맛집',
        amount: 68000,
        pct: 30,
        color: Color(0xFFD97757),
      ),
      CategoryRevenue(
        name: '뷰티',
        amount: 73000,
        pct: 33,
        color: Color(0xFF8062B8),
      ),
      CategoryRevenue(
        name: '카페',
        amount: 32000,
        pct: 14,
        color: Color(0xFFC99436),
      ),
      CategoryRevenue(
        name: '건강식품',
        amount: 50000,
        pct: 23,
        color: Color(0xFF4A7A5C),
      ),
    ],
  );

  static const defaultCategories = ['맛집', '카페', '뷰티', '건강식품', '생활', '기타'];
}

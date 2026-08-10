import 'package:flutter_test/flutter_test.dart';
import 'package:review_calendar/features/campaign/data/campaign_repository.dart';
import 'package:review_calendar/features/campaign/data/fake_campaign_repository.dart';
import 'package:review_calendar/features/campaign/domain/campaign.dart';
import 'package:review_calendar/features/campaign/domain/campaign_id.dart';
import 'package:review_calendar/features/campaign/domain/campaign_status.dart';
import 'package:review_calendar/features/campaign/domain/local_date.dart';
import 'package:review_calendar/features/campaign/domain/money.dart';
import 'package:review_calendar/features/campaign/domain/visit_schedule.dart';

import '../../../support/review_calendar_test_app.dart';

Campaign _undecidedCampaign() {
  return Campaign(
    id: CampaignId('c1'),
    ownerId: UserId('user-001'),
    brand: '르봉 파스타바 성수점',
    platform: '레뷰',
    category: '맛집',
    visitAvailability: VisitDateRange(
      start: LocalDate(2026, 4, 18),
      end: LocalDate(2026, 4, 28),
    ),
    status: CampaignStatus(
      visit: VisitStatus.unscheduled,
      posting: PostingStatus.pending,
    ),
    deadline: LocalDate(2026, 5, 2),
    sponsoredValue: Money.won(68000),
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
  );
}

void main() {
  testWidgets('shows a real Firestore-backed campaign in the undecided strip', (
    tester,
  ) async {
    final repository = FakeCampaignRepository(
      seed: [
        StoredCampaign(
          campaign: _undecidedCampaign(),
          revision: 1,
          hasPendingWrites: false,
        ),
      ],
    );

    await tester.pumpReviewCalendarApp(campaignRepository: repository);
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('캘린더'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('르봉 파스타바 성수점'), findsOneWidget);
    expect(find.textContaining('미정 일정 · 1'), findsOneWidget);
  });
}

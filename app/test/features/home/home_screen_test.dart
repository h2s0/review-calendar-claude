import 'package:flutter_test/flutter_test.dart';
import 'package:review_calendar/features/campaign/data/campaign_repository.dart';
import 'package:review_calendar/features/campaign/data/fake_campaign_repository.dart';
import 'package:review_calendar/features/campaign/domain/campaign.dart';
import 'package:review_calendar/features/campaign/domain/campaign_id.dart';
import 'package:review_calendar/features/campaign/domain/campaign_status.dart';
import 'package:review_calendar/features/campaign/domain/local_date.dart';
import 'package:review_calendar/features/campaign/domain/money.dart';
import 'package:review_calendar/features/campaign/domain/visit_schedule.dart';

import '../../support/review_calendar_test_app.dart';

Campaign _campaign() {
  final today = DateTime.now();
  return Campaign(
    id: CampaignId('c1'),
    ownerId: UserId('user-001'),
    brand: '르봉 파스타바 성수점',
    platform: '레뷰',
    category: '맛집',
    visitAvailability: VisitDateRange(
      start: LocalDate(today.year, today.month, today.day),
      end: LocalDate(today.year, today.month, today.day),
    ),
    status: CampaignStatus(
      visit: VisitStatus.unscheduled,
      posting: PostingStatus.pending,
    ),
    // Deadline today so it's guaranteed to land inside this week's window.
    deadline: LocalDate(today.year, today.month, today.day),
    sponsoredValue: Money.won(68000),
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
  );
}

void main() {
  testWidgets(
    'shows a real Firestore-backed campaign in this week\'s events and '
    'the undecided summary count',
    (tester) async {
      final repository = FakeCampaignRepository(
        seed: [
          StoredCampaign(
            campaign: _campaign(),
            revision: 1,
            hasPendingWrites: false,
          ),
        ],
      );

      await tester.pumpReviewCalendarApp(campaignRepository: repository);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('르봉 파스타바 성수점'), findsOneWidget);
      expect(find.text('미정 일정'), findsOneWidget);
    },
  );
}

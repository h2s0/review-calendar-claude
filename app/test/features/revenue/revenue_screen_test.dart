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

Campaign _publishedCampaign() {
  final today = DateTime.now();
  final published = LocalDate(today.year, today.month, today.day);
  return Campaign(
    id: CampaignId('c1'),
    ownerId: UserId('user-001'),
    brand: '핏앤슬림 단백질 쉐이크',
    category: '건강식품',
    visitAvailability: VisitDateRange(start: published, end: published),
    status: CampaignStatus(
      visit: VisitStatus.visited,
      posting: PostingStatus.published,
    ),
    visit: VisitSchedule(date: published),
    deadline: published,
    publishedDate: published,
    sponsoredValue: Money.won(68000),
    cashFee: Money.won(10000),
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
  );
}

void main() {
  testWidgets(
    // Also guards against the initial-frame crash the empty-trend bug
    // would have caused (RevenueScreen renders before the first Firestore
    // snapshot arrives).
    'renders this month\'s revenue from a real Firestore-backed campaign',
    (tester) async {
      final repository = FakeCampaignRepository(
        seed: [
          StoredCampaign(
            campaign: _publishedCampaign(),
            revision: 1,
            hasPendingWrites: false,
          ),
        ],
      );

      await tester.pumpReviewCalendarApp(campaignRepository: repository);
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('수익'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('78,000'), findsWidgets);
      expect(find.text('건강식품'), findsOneWidget);
    },
  );
}

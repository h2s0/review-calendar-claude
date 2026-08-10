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
  final visited = LocalDate(today.year, today.month, today.day);
  return Campaign(
    id: CampaignId('c1'),
    ownerId: UserId('user-001'),
    brand: '핏앤슬림 단백질 쉐이크',
    platform: '레뷰',
    category: '건강식품',
    visitAvailability: VisitDateRange(start: visited, end: visited),
    status: CampaignStatus(
      visit: VisitStatus.visited,
      posting: PostingStatus.published,
    ),
    visit: VisitSchedule(date: visited),
    deadline: visited,
    publishedDate: visited,
    sponsoredValue: Money.won(50000),
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
  );
}

void main() {
  testWidgets(
    'shows a real Firestore-backed published campaign in this month\'s '
    'records',
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

      await tester.tap(find.text('기록'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('핏앤슬림 단백질 쉐이크'), findsOneWidget);
      expect(find.text('해당 달에 발행 기록이 없어요'), findsNothing);
    },
  );
}

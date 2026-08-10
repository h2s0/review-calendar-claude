import 'package:flutter_test/flutter_test.dart';
import 'package:review_calendar/features/campaign/data/campaign_repository.dart';
import 'package:review_calendar/features/campaign/data/fake_campaign_repository.dart';
import 'package:review_calendar/features/campaign/domain/campaign.dart';
import 'package:review_calendar/features/campaign/domain/campaign_id.dart';
import 'package:review_calendar/features/campaign/domain/campaign_status.dart';
import 'package:review_calendar/features/campaign/domain/local_date.dart';
import 'package:review_calendar/features/campaign/domain/money.dart';
import 'package:review_calendar/features/campaign/domain/visit_schedule.dart';
import 'package:review_calendar/features/revenue/presentation/revenue_view_model.dart';

Campaign _publishedCampaign({
  required String id,
  required String brand,
  required String category,
  required LocalDate publishedDate,
  int sponsoredValue = 0,
  int cashFee = 0,
}) {
  return Campaign(
    id: CampaignId(id),
    ownerId: UserId('user-001'),
    brand: brand,
    category: category,
    visitAvailability: VisitDateRange(start: publishedDate, end: publishedDate),
    status: CampaignStatus(
      visit: VisitStatus.visited,
      posting: PostingStatus.published,
    ),
    visit: VisitSchedule(date: publishedDate),
    deadline: publishedDate,
    publishedDate: publishedDate,
    sponsoredValue: sponsoredValue > 0 ? Money.won(sponsoredValue) : null,
    cashFee: cashFee > 0 ? Money.won(cashFee) : null,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  test(
    'has a correctly-sized zeroed trend before the first snapshot arrives',
    () {
      final viewModel = RevenueViewModel(
        FakeCampaignRepository(),
        monthCount: 6,
      );
      addTearDown(viewModel.dispose);

      expect(viewModel.hasLoaded, isFalse);
      expect(viewModel.summary.trend, hasLength(6));
      expect(viewModel.summary.total, 0);
    },
  );

  test('attributes revenue to the month a campaign was published in', () async {
    final now = DateTime.now();
    final thisMonth = LocalDate(now.year, now.month, 1);
    final repository = FakeCampaignRepository(
      seed: [
        StoredCampaign(
          campaign: _publishedCampaign(
            id: 'c1',
            brand: '르봉 파스타바 성수점',
            category: '맛집',
            publishedDate: thisMonth,
            sponsoredValue: 68000,
            cashFee: 10000,
          ),
          revision: 1,
          hasPendingWrites: false,
        ),
      ],
    );
    final viewModel = RevenueViewModel(repository, monthCount: 6);
    addTearDown(viewModel.dispose);

    await pumpEventQueue();

    expect(viewModel.hasLoaded, isTrue);
    expect(viewModel.summary.sponsor, 68000);
    expect(viewModel.summary.fee, 10000);
    expect(viewModel.summary.total, 78000);
    expect(viewModel.summary.byCategory, hasLength(1));
    expect(viewModel.summary.byCategory.single.name, '맛집');
    expect(viewModel.summary.byCategory.single.amount, 78000);
    expect(viewModel.summary.byCategory.single.pct, 100);
    expect(viewModel.summary.trend.last.total, 78000);
  });
}

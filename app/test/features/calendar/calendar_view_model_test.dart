import 'package:flutter_test/flutter_test.dart';
import 'package:review_calendar/features/calendar/presentation/calendar_view_model.dart';
import 'package:review_calendar/features/campaign/data/campaign_repository.dart';
import 'package:review_calendar/features/campaign/data/fake_campaign_repository.dart';
import 'package:review_calendar/features/campaign/domain/campaign.dart';
import 'package:review_calendar/features/campaign/domain/campaign_id.dart';
import 'package:review_calendar/features/campaign/domain/campaign_status.dart';
import 'package:review_calendar/features/campaign/domain/local_date.dart';
import 'package:review_calendar/features/campaign/domain/money.dart';
import 'package:review_calendar/features/campaign/domain/visit_schedule.dart';

Campaign _campaign({
  required String id,
  required String brand,
  VisitStatus visit = VisitStatus.unscheduled,
  LocalDate? publishedDate,
}) {
  return Campaign(
    id: CampaignId(id),
    ownerId: UserId('user-001'),
    brand: brand,
    platform: '레뷰',
    category: '맛집',
    visitAvailability: VisitDateRange(
      start: LocalDate(2026, 4, 18),
      end: LocalDate(2026, 4, 28),
    ),
    status: CampaignStatus(
      visit: visit,
      posting: publishedDate != null
          ? PostingStatus.published
          : PostingStatus.pending,
    ),
    visit: visit == VisitStatus.visited
        ? VisitSchedule(date: LocalDate(2026, 4, 20))
        : const VisitSchedule(),
    deadline: LocalDate(2026, 5, 2),
    sponsoredValue: Money.won(68000),
    publishedDate: publishedDate,
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
  );
}

void main() {
  test('projects an unscheduled campaign into an undecided visit', () async {
    final repository = FakeCampaignRepository(
      seed: [
        StoredCampaign(
          campaign: _campaign(id: 'c1', brand: '르봉 파스타바 성수점'),
          revision: 1,
          hasPendingWrites: false,
        ),
      ],
    );
    final viewModel = CalendarViewModel(repository);
    addTearDown(viewModel.dispose);

    await pumpEventQueue();

    expect(viewModel.hasLoaded, isTrue);
    expect(viewModel.campaigns, hasLength(1));
    expect(viewModel.campaigns.single.brand, '르봉 파스타바 성수점');
    expect(viewModel.undecided, hasLength(1));
    expect(viewModel.undecided.single.brand, '르봉 파스타바 성수점');
    // Every active campaign contributes at least a deadline event.
    expect(
      viewModel.events.any(
        (e) => e.campaignId == 'c1' && e.label == '르봉 파스타바 성수점 마감',
      ),
      isTrue,
    );
  });

  test(
    'a confirmed visit produces a visit event, not an undecided entry',
    () async {
      final repository = FakeCampaignRepository(
        seed: [
          StoredCampaign(
            campaign: _campaign(
              id: 'c2',
              brand: '포레스트 향수 디퓨저',
              visit: VisitStatus.scheduled,
            ),
            revision: 1,
            hasPendingWrites: false,
          ),
        ],
      );
      final viewModel = CalendarViewModel(repository);
      addTearDown(viewModel.dispose);

      await pumpEventQueue();

      expect(viewModel.undecided, isEmpty);
    },
  );

  test(
    'a published campaign is marked posted and excluded from undecided',
    () async {
      final repository = FakeCampaignRepository(
        seed: [
          StoredCampaign(
            campaign: _campaign(
              id: 'c3',
              brand: '핏앤슬림 단백질 쉐이크',
              visit: VisitStatus.visited,
              publishedDate: LocalDate(2026, 4, 17),
            ),
            revision: 1,
            hasPendingWrites: false,
          ),
        ],
      );
      final viewModel = CalendarViewModel(repository);
      addTearDown(viewModel.dispose);

      await pumpEventQueue();

      final campaign = viewModel.campaignById('c3');
      expect(campaign, isNotNull);
      expect(campaign!.posted, DateTime(2026, 4, 17));
      expect(viewModel.undecided, isEmpty);
    },
  );

  test('confirmVisitDate writes the chosen date back through the repository '
      'and clears the campaign from undecided', () async {
    final repository = FakeCampaignRepository(
      seed: [
        StoredCampaign(
          campaign: _campaign(id: 'c4', brand: '르봉 파스타바 성수점'),
          revision: 1,
          hasPendingWrites: false,
        ),
      ],
    );
    final viewModel = CalendarViewModel(repository);
    addTearDown(viewModel.dispose);

    await pumpEventQueue();
    expect(viewModel.undecided, hasLength(1));

    final success = await viewModel.confirmVisitDate(
      campaignId: 'c4',
      date: DateTime(2026, 4, 20),
    );
    expect(success, isTrue);

    await pumpEventQueue();
    expect(viewModel.undecided, isEmpty);

    final stored = await repository.getById(CampaignId('c4'));
    expect(stored, isNotNull);
    expect(stored!.campaign.visit.date, LocalDate(2026, 4, 20));
    expect(stored.campaign.status.visit, VisitStatus.scheduled);
  });

  test('confirmVisitDate returns false for an unknown campaign id', () async {
    final repository = FakeCampaignRepository();
    final viewModel = CalendarViewModel(repository);
    addTearDown(viewModel.dispose);

    await pumpEventQueue();

    final success = await viewModel.confirmVisitDate(
      campaignId: 'missing',
      date: DateTime(2026, 4, 20),
    );
    expect(success, isFalse);
  });
}

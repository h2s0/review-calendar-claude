import 'package:review_calendar/data/review_calendar_models.dart' as ui;
import 'package:review_calendar/features/campaign/domain/campaign.dart'
    as domain;
import 'package:review_calendar/features/campaign/domain/campaign_status.dart'
    as domain;
import 'package:review_calendar/features/campaign/domain/local_date.dart';
import 'package:review_calendar/features/campaign/domain/visit_schedule.dart';
import 'package:review_calendar/features/settings/domain/notification_settings.dart';

// Shared pure mapping from the real domain `Campaign` model to the UI-facing
// shapes the screens render (`ui.Campaign`/`ui.CalendarEvent`/
// `ui.UndecidedVisit`) — extracted out of `CalendarViewModel` so every
// feature view model that projects the same campaign stream (calendar,
// home, …) shares one mapping instead of re-deriving it.

bool isUndecided(domain.Campaign campaign) =>
    campaign.visit.date == null &&
    campaign.status.visit == domain.VisitStatus.unscheduled;

ui.Campaign toUiCampaign(domain.Campaign campaign) {
  final window = availabilityWindow(campaign.visitAvailability);
  final deadline = toDateTime(campaign.deadline);
  final posted = campaign.publishedDate == null
      ? null
      : toDateTime(campaign.publishedDate!);
  final daysUntilDeadline = deadline.difference(DateTime.now()).inDays;

  return ui.Campaign(
    id: campaign.id.value,
    brand: campaign.brand,
    category: campaign.category ?? '기타',
    visitStart: window.$1,
    visitEnd: window.$2,
    deadline: deadline,
    reward: toUiReward(campaign),
    alertDays: alertDays(campaign.notificationSettings),
    platform: campaign.platform ?? '',
    status: posted != null
        ? ui.CampaignStatus.posted
        : daysUntilDeadline <= 3
        ? ui.CampaignStatus.urgent
        : ui.CampaignStatus.upcoming,
    notes: campaign.notes,
    posted: posted,
  );
}

ui.Reward toUiReward(domain.Campaign campaign) {
  if (campaign.cashFee case final fee?) {
    return ui.Reward(type: ui.RewardType.fee, amount: fee.amount);
  }
  if (campaign.sponsoredValue case final sponsor?) {
    return ui.Reward(type: ui.RewardType.sponsor, amount: sponsor.amount);
  }
  return const ui.Reward(type: ui.RewardType.sponsor, amount: 0);
}

int alertDays(CampaignNotificationSettings settings) {
  return switch (settings.deadline) {
    CustomNotification(:final schedule) when schedule.daysBefore.isNotEmpty =>
      schedule.daysBefore.first,
    _ => 3,
  };
}

Iterable<ui.CalendarEvent> toUiEvents(domain.Campaign campaign) sync* {
  final id = campaign.id.value;
  if (campaign.visit.date case final visitDate?) {
    yield ui.CalendarEvent(
      date: toDateTime(visitDate),
      type: ui.CalendarEventType.visit,
      label: '${campaign.brand} 방문',
      campaignId: id,
    );
  }
  yield ui.CalendarEvent(
    date: toDateTime(campaign.deadline),
    type: ui.CalendarEventType.deadline,
    label: '${campaign.brand} 마감',
    campaignId: id,
  );
  if (campaign.publishedDate case final published?) {
    yield ui.CalendarEvent(
      date: toDateTime(published),
      type: ui.CalendarEventType.posted,
      label: '${campaign.brand} 포스팅',
      campaignId: id,
    );
  }
}

ui.UndecidedVisit? toUndecidedVisit(domain.Campaign campaign) {
  final window = availabilityWindow(campaign.visitAvailability);
  return ui.UndecidedVisit(
    id: 'u-${campaign.id.value}',
    campaignId: campaign.id.value,
    brand: campaign.brand,
    category: campaign.category ?? '기타',
    visit: ui.VisitSlotValue(time: campaign.visit.time?.toString()),
    deadline: toDateTime(campaign.deadline),
    visitWindow: ui.VisitWindow(start: window.$1, end: window.$2),
    note: '방문 날짜 미정',
  );
}

(DateTime, DateTime) availabilityWindow(VisitAvailability availability) {
  return switch (availability) {
    VisitDateRange(:final start, :final end) => (
      toDateTime(start),
      toDateTime(end),
    ),
    VisitDateOptions(:final dates) => (
      toDateTime(dates.first),
      toDateTime(dates.last),
    ),
  };
}

DateTime toDateTime(LocalDate date) =>
    DateTime(date.year, date.month, date.day);

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:review_calendar/data/review_calendar_models.dart' as ui;
import 'package:review_calendar/features/campaign/data/campaign_repository.dart';
import 'package:review_calendar/features/campaign/domain/campaign_status.dart';
import 'package:review_calendar/features/campaign/domain/local_date.dart';
import 'package:review_calendar/features/campaign/domain/visit_schedule.dart';
import 'package:review_calendar/features/campaign/presentation/campaign_ui_mapper.dart'
    as mapper;

/// Feeds the Calendar screen from a real `CampaignRepository` instead of
/// `MockReviewCalendarData` — but keeps producing the exact same UI-facing
/// shapes (`ui.Campaign`/`ui.CalendarEvent`/`ui.UndecidedVisit`) those
/// screens already render, so the widget tree/styling don't need to change,
/// only the data source. The domain→UI mapping itself lives in
/// `campaign_ui_mapper.dart`, shared with `HomeViewModel`.
class CalendarViewModel extends ChangeNotifier {
  CalendarViewModel(this._repository) {
    _subscription = _repository.watchAll().listen(_onSnapshot);
  }

  final CampaignRepository _repository;
  late final StreamSubscription<CampaignSnapshot> _subscription;

  List<ui.Campaign> _campaigns = const [];
  List<ui.CalendarEvent> _events = const [];
  List<ui.UndecidedVisit> _undecided = const [];
  Map<String, StoredCampaign> _storedById = const {};
  bool _hasLoaded = false;

  List<ui.Campaign> get campaigns => _campaigns;
  List<ui.CalendarEvent> get events => _events;
  List<ui.UndecidedVisit> get undecided => _undecided;
  bool get hasLoaded => _hasLoaded;

  ui.Campaign? campaignById(String id) {
    for (final campaign in _campaigns) {
      if (campaign.id == id) return campaign;
    }
    return null;
  }

  List<ui.CalendarEvent> eventsOn(DateTime date) => _events
      .where(
        (e) =>
            e.date.year == date.year &&
            e.date.month == date.month &&
            e.date.day == date.day,
      )
      .toList();

  /// Confirms a visit date for a currently-undecided campaign — writes the
  /// chosen date back through the repository (via the domain's
  /// `scheduleVisit` transition) rather than only updating local UI state.
  /// Returns `true` on success; the caller decides how to react to failure
  /// (e.g. keep showing the campaign as undecided).
  Future<bool> confirmVisitDate({
    required String campaignId,
    required DateTime date,
  }) async {
    final stored = _storedById[campaignId];
    if (stored == null) return false;

    final transition = applyCampaignTransition(
      current: stored.campaign.status,
      transition: CampaignTransition.scheduleVisit,
    );
    if (transition is! CampaignTransitionSuccess) return false;

    final updated = stored.campaign.withVisitSchedule(
      visit: VisitSchedule(date: LocalDate(date.year, date.month, date.day)),
      updatedAt: DateTime.now().toUtc(),
      status: transition.status,
    );
    final result = await _repository.update(
      updated,
      expectedRevision: stored.revision,
    );
    return result is CampaignSaveSuccess;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _onSnapshot(CampaignSnapshot snapshot) {
    final active = snapshot.campaigns
        .where((stored) => stored.campaign.status.isActive)
        .toList();

    _storedById = {
      for (final stored in active) stored.campaign.id.value: stored,
    };
    final campaigns = active.map((stored) => stored.campaign).toList();
    _campaigns = campaigns.map(mapper.toUiCampaign).toList();
    _events = campaigns.expand(mapper.toUiEvents).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    _undecided = campaigns
        .where(mapper.isUndecided)
        .map(mapper.toUndecidedVisit)
        .whereType<ui.UndecidedVisit>()
        .toList();
    _hasLoaded = true;
    notifyListeners();
  }
}

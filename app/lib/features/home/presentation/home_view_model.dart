import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:review_calendar/data/review_calendar_models.dart' as ui;
import 'package:review_calendar/features/campaign/data/campaign_repository.dart';
import 'package:review_calendar/features/campaign/presentation/campaign_ui_mapper.dart'
    as mapper;

/// Feeds the Home dashboard from a real `CampaignRepository`, independently
/// of `CalendarViewModel` (its own subscription, same shared pure mapping in
/// `campaign_ui_mapper.dart`) — mirrors how the sibling project gives each
/// screen its own read-side projection over the same campaign stream.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._repository) {
    _subscription = _repository.watchAll().listen(_onSnapshot);
  }

  final CampaignRepository _repository;
  late final StreamSubscription<CampaignSnapshot> _subscription;

  List<ui.Campaign> _campaigns = const [];
  List<ui.CalendarEvent> _events = const [];
  int _undecidedCount = 0;
  int _thisMonthRevenueTotal = 0;
  int _thisMonthRevenueFee = 0;
  bool _hasLoaded = false;

  List<ui.CalendarEvent> get events => _events;
  int get undecidedCount => _undecidedCount;
  int get thisMonthRevenueTotal => _thisMonthRevenueTotal;
  int get thisMonthRevenueFee => _thisMonthRevenueFee;
  bool get hasLoaded => _hasLoaded;

  ui.Campaign? campaignById(String id) {
    for (final campaign in _campaigns) {
      if (campaign.id == id) return campaign;
    }
    return null;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _onSnapshot(CampaignSnapshot snapshot) {
    final active = snapshot.campaigns
        .map((stored) => stored.campaign)
        .where((campaign) => campaign.status.isActive)
        .toList();

    _campaigns = active.map(mapper.toUiCampaign).toList();
    _events = active.expand(mapper.toUiEvents).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    _undecidedCount = active.where(mapper.isUndecided).length;

    final now = DateTime.now();
    var total = 0;
    var fee = 0;
    for (final campaign in active) {
      final published = campaign.publishedDate;
      if (published == null ||
          published.year != now.year ||
          published.month != now.month) {
        continue;
      }
      final sponsoredAmount = campaign.sponsoredValue?.amount ?? 0;
      final feeAmount = campaign.cashFee?.amount ?? 0;
      total += sponsoredAmount + feeAmount;
      fee += feeAmount;
    }
    _thisMonthRevenueTotal = total;
    _thisMonthRevenueFee = fee;

    _hasLoaded = true;
    notifyListeners();
  }
}

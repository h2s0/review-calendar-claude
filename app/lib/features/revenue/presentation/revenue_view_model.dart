import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:review_calendar/data/review_calendar_models.dart' as ui;
import 'package:review_calendar/features/campaign/data/campaign_repository.dart';
import 'package:review_calendar/features/campaign/domain/campaign.dart'
    as domain;

/// Fixed, deterministic palette cycled across categories in alphabetical
/// order — the UI-facing `CategoryRevenue` shape carries a resolved `Color`
/// rather than a category-agnostic token, and Firestore campaigns don't
/// carry a color themselves, so this view model is the one place that
/// assigns them (mirrors the same 4 colors `MockReviewCalendarData` used,
/// extended so a 5th+ category still gets a stable, distinct color).
const _categoryPalette = [
  Color(0xFFD97757),
  Color(0xFF8062B8),
  Color(0xFFC99436),
  Color(0xFF4A7A5C),
  Color(0xFF3D7EA6),
  Color(0xFFB25C7C),
  Color(0xFF6B8E4E),
  Color(0xFF9C6B30),
];

/// Feeds the Revenue screen from a real `CampaignRepository`. Revenue is
/// attributed to the month a campaign's `publishedDate` falls in (matching
/// the sibling project's `RevenueReport`/`MonthlyRevenue.fromRecords`
/// semantics), then flattened into the UI's already-simplified
/// `RevenueSummary` shape (plain ints + resolved colors) instead of the
/// sibling's `Money`-typed domain report.
class RevenueViewModel extends ChangeNotifier {
  // `monthCount` intentionally has a friendlier public name than the
  // private `_monthCount` field it seeds.
  RevenueViewModel(this._repository, {int monthCount = 6})
    // ignore: prefer_initializing_formals
    : _monthCount = monthCount {
    // Seed a correctly-sized (but zeroed) trend before the first Firestore
    // snapshot arrives — `_MonthlyTrendChart` indexes `trend.last`, so an
    // empty list here would crash the very first frame.
    _summary = _summarize(const []);
    _subscription = _repository.watchAll().listen(_onSnapshot);
  }

  final CampaignRepository _repository;
  final int _monthCount;
  late final StreamSubscription<CampaignSnapshot> _subscription;

  late ui.RevenueSummary _summary;
  bool _hasLoaded = false;

  ui.RevenueSummary get summary => _summary;
  bool get hasLoaded => _hasLoaded;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _onSnapshot(CampaignSnapshot snapshot) {
    final publishedCampaigns = snapshot.campaigns
        .map((stored) => stored.campaign)
        .where(
          (campaign) =>
              campaign.status.isActive && campaign.publishedDate != null,
        )
        .toList();

    _summary = _summarize(publishedCampaigns);
    _hasLoaded = true;
    notifyListeners();
  }

  ui.RevenueSummary _summarize(List<domain.Campaign> publishedCampaigns) {
    final now = DateTime.now();
    final months = [
      for (var offset = _monthCount - 1; offset >= 0; offset--)
        DateTime(now.year, now.month - offset, 1),
    ];

    final trend = months
        .map((month) {
          var sponsor = 0;
          var fee = 0;
          for (final campaign in publishedCampaigns) {
            final publishedDate = campaign.publishedDate!;
            if (publishedDate.year != month.year ||
                publishedDate.month != month.month) {
              continue;
            }
            sponsor += campaign.sponsoredValue?.amount ?? 0;
            fee += campaign.cashFee?.amount ?? 0;
          }
          return ui.MonthlyRevenue(
            month: '${month.month}월',
            total: sponsor + fee,
            sponsor: sponsor,
            fee: fee,
          );
        })
        .toList(growable: false);

    final thisMonth = trend.last;
    final lastMonth = trend.length > 1 ? trend[trend.length - 2].total : 0;

    final categoryAmounts = <String, int>{};
    for (final campaign in publishedCampaigns) {
      final publishedDate = campaign.publishedDate!;
      if (publishedDate.year != now.year || publishedDate.month != now.month) {
        continue;
      }
      final category = campaign.category ?? '기타';
      final amount =
          (campaign.sponsoredValue?.amount ?? 0) +
          (campaign.cashFee?.amount ?? 0);
      categoryAmounts[category] = (categoryAmounts[category] ?? 0) + amount;
    }
    final sortedCategories = categoryAmounts.keys.toList()..sort();
    final byCategory = [
      for (final category in sortedCategories)
        ui.CategoryRevenue(
          name: category,
          amount: categoryAmounts[category]!,
          pct: thisMonth.total == 0
              ? 0
              : (categoryAmounts[category]! * 100 / thisMonth.total).round(),
          color:
              _categoryPalette[sortedCategories.indexOf(category) %
                  _categoryPalette.length],
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));

    return ui.RevenueSummary(
      total: thisMonth.total,
      sponsor: thisMonth.sponsor,
      fee: thisMonth.fee,
      thisMonth: thisMonth.total,
      lastMonth: lastMonth,
      trend: trend,
      byCategory: byCategory,
    );
  }
}

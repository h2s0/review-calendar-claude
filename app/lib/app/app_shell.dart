import 'dart:async';

import 'package:flutter/material.dart';
import 'package:review_calendar/data/review_calendar_models.dart';
import 'package:review_calendar/features/account/presentation/account_view_model.dart';
import 'package:review_calendar/features/calendar/presentation/calendar_view_model.dart';
import 'package:review_calendar/features/campaign/data/campaign_repository.dart';
import 'package:review_calendar/features/home/presentation/home_view_model.dart';
import 'package:review_calendar/features/notification/domain/notification_device_registration.dart';
import 'package:review_calendar/features/records/data/record_categories_repository.dart';
import 'package:review_calendar/features/revenue/presentation/revenue_view_model.dart';
import 'package:review_calendar/screens/calendar/calendar_screen.dart';
import 'package:review_calendar/screens/detail/campaign_detail_sheet.dart';
import 'package:review_calendar/screens/home/home_screen.dart';
import 'package:review_calendar/screens/records/records_screen.dart';
import 'package:review_calendar/screens/revenue/revenue_screen.dart';
import 'package:review_calendar/screens/settings/settings_screen.dart';
import 'package:review_calendar/screens/upload/upload_flow.dart';
import 'package:review_calendar/ui/core/icons/rc_icons.dart';
import 'package:review_calendar/ui/core/theme/rc_theme.dart';

enum AppTab { home, calendar, records, revenue }

/// Root shell — mirrors `screen-rest.jsx`'s `App` + `TabBar`.
class AppShell extends StatefulWidget {
  const AppShell({
    required this.calendarViewModel,
    required this.homeViewModel,
    required this.revenueViewModel,
    required this.accountViewModel,
    required this.campaignRepository,
    required this.categoriesRepository,
    required this.ownerId,
    this.notificationRegistration,
    super.key,
  });

  final CalendarViewModel calendarViewModel;
  final HomeViewModel homeViewModel;
  final RevenueViewModel revenueViewModel;
  final AccountViewModel accountViewModel;
  final CampaignRepository campaignRepository;
  final RecordCategoriesRepository categoriesRepository;
  final String ownerId;
  final NotificationDeviceRegistrationController? notificationRegistration;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab _tab = AppTab.home;
  MonthlyRewardGoals _goals = const MonthlyRewardGoals(
    total: 300000,
    fee: 100000,
  );
  List<String> _categories = defaultRecordCategories;
  late final StreamSubscription<List<String>> _categoriesSubscription;

  @override
  void initState() {
    super.initState();
    _categoriesSubscription = widget.categoriesRepository.watch().listen(
      (categories) => setState(() => _categories = categories),
    );
  }

  @override
  void dispose() {
    _categoriesSubscription.cancel();
    super.dispose();
  }

  void _openCampaign(Campaign campaign) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CampaignDetailSheet(campaign: campaign),
    );
  }

  void _openUpload() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => UploadFlow(
          categories: _categories,
          campaignRepository: widget.campaignRepository,
          ownerId: widget.ownerId,
          notificationRegistration: widget.notificationRegistration,
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => SettingsScreen(
          categories: _categories,
          onCategoriesChanged: (next) => widget.categoriesRepository.save(next),
          accountViewModel: widget.accountViewModel,
          notificationRegistration: widget.notificationRegistration,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _tab.index,
              children: [
                HomeDashboard(
                  viewModel: widget.homeViewModel,
                  goals: _goals,
                  onOpenUpload: _openUpload,
                  onOpenCampaign: _openCampaign,
                  onOpenSettings: _openSettings,
                  onGoRevenue: () => setState(() => _tab = AppTab.revenue),
                ),
                CalendarScreen(
                  viewModel: widget.calendarViewModel,
                  onOpenCampaign: _openCampaign,
                ),
                RecordsScreen(
                  viewModel: widget.calendarViewModel,
                  onOpenCampaign: _openCampaign,
                ),
                RevenueScreen(
                  viewModel: widget.revenueViewModel,
                  goals: _goals,
                  onGoalsChanged: (next) => setState(() => _goals = next),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _AppTabBar(
              active: _tab,
              onChanged: (tab) => setState(() => _tab = tab),
              onCenterPressed: _openUpload,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppTabBar extends StatelessWidget {
  const _AppTabBar({
    required this.active,
    required this.onChanged,
    required this.onCenterPressed,
  });

  final AppTab active;
  final ValueChanged<AppTab> onChanged;
  final VoidCallback onCenterPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.background.withValues(alpha: 0), colors.background],
          stops: const [0, 0.4],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.ink.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _tabItem(context, AppTab.home, RcIconGlyph.home, '홈'),
            _tabItem(context, AppTab.calendar, RcIconGlyph.calendar, '캘린더'),
            _centerItem(context),
            _tabItem(context, AppTab.records, RcIconGlyph.list, '기록'),
            _tabItem(context, AppTab.revenue, RcIconGlyph.trend, '수익'),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(
    BuildContext context,
    AppTab tab,
    RcIconGlyph glyph,
    String label,
  ) {
    final colors = context.rcColors;
    final isActive = active == tab;
    final color = isActive ? colors.brand : colors.inkMuted;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(tab),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RcIcon(glyph, size: 22, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _centerItem(BuildContext context) {
    final colors = context.rcColors;
    return Expanded(
      child: Center(
        child: InkWell(
          key: const ValueKey('tab-bar:upload'),
          onTap: onCenterPressed,
          customBorder: const CircleBorder(),
          child: Transform.translate(
            offset: const Offset(0, -14),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.brand,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.brand.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: RcIcon(
                  RcIconGlyph.sparkle,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

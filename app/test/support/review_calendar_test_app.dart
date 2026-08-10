import 'package:flutter_test/flutter_test.dart';
import 'package:review_calendar/features/auth/data/auth_repository.dart';
import 'package:review_calendar/features/auth/domain/auth_user.dart';
import 'package:review_calendar/features/campaign/data/campaign_repository.dart';
import 'package:review_calendar/features/campaign/data/fake_campaign_repository.dart';
import 'package:review_calendar/features/notification/domain/notification_device_registration.dart';
import 'package:review_calendar/features/records/data/memory_record_categories_repository.dart';
import 'package:review_calendar/features/records/data/record_categories_repository.dart';
import 'package:review_calendar/main.dart';

import 'fake_auth_repository.dart';

/// Test-harness builder — mirrors review-calendar/app/test/support's
/// `buildReviewCalendarTestApp`/`pumpReviewCalendarApp` pattern, scaled down
/// to what's actually wired so far (auth + campaigns; grows as more
/// features are ported).
ReviewCalendarApp buildReviewCalendarTestApp({
  AuthRepository? authRepository,
  CampaignRepository? campaignRepository,
  RecordCategoriesRepository? categoriesRepository,
  NotificationDeviceRegistrationController? notificationRegistration,
}) {
  return ReviewCalendarApp(
    authRepository: authRepository ?? FakeAuthRepository(),
    campaignRepositoryFactory: (AuthUser _) =>
        campaignRepository ?? FakeCampaignRepository(),
    categoriesRepositoryFactory: (AuthUser _) =>
        categoriesRepository ?? MemoryRecordCategoriesRepository(),
    notificationRegistrationFactory: notificationRegistration == null
        ? null
        : (AuthUser _) => notificationRegistration,
  );
}

extension ReviewCalendarWidgetTester on WidgetTester {
  Future<void> pumpReviewCalendarApp({
    AuthRepository? authRepository,
    CampaignRepository? campaignRepository,
    RecordCategoriesRepository? categoriesRepository,
    NotificationDeviceRegistrationController? notificationRegistration,
  }) {
    return pumpWidget(
      buildReviewCalendarTestApp(
        authRepository: authRepository,
        campaignRepository: campaignRepository,
        categoriesRepository: categoriesRepository,
        notificationRegistration: notificationRegistration,
      ),
    );
  }
}

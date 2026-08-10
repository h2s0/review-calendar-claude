import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:review_calendar/features/campaign/data/fake_campaign_repository.dart';
import 'package:review_calendar/features/notification/domain/notification_device_registration.dart';

import '../../support/review_calendar_test_app.dart';

/// Minimal in-memory doubles — the underlying
/// `NotificationDeviceRegistrationController`/`offerCampaignNotifications`
/// are ported verbatim from the sibling (already covered there); this test
/// only exercises this project's own wiring: does a successful manual
/// campaign creation actually trigger the dialog end-to-end.
final class _FakePermissionGateway implements NotificationPermissionGateway {
  NotificationPermissionStatus status =
      NotificationPermissionStatus.notDetermined;

  @override
  Future<NotificationPermissionStatus> currentStatus() async => status;

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    status = NotificationPermissionStatus.authorized;
    return status;
  }
}

final class _FakeTokenSource implements NotificationTokenSource {
  @override
  Future<String?> getToken() async => 'fake-token';

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();
}

final class _FakeTokenRepository implements NotificationTokenRepository {
  final registered = <String>[];

  @override
  Future<void> register({required String userId, required String token}) async {
    registered.add(token);
  }

  @override
  Future<void> revoke({required String userId, required String token}) async {}
}

void main() {
  testWidgets(
    'offers the notification-permission dialog after a successful manual '
    'campaign creation',
    (tester) async {
      final campaignRepository = FakeCampaignRepository();
      final controller = NotificationDeviceRegistrationController(
        userId: 'user-001',
        permissionGateway: _FakePermissionGateway(),
        tokenSource: _FakeTokenSource(),
        tokenRepository: _FakeTokenRepository(),
      );
      addTearDown(controller.close);
      await controller.initialize();
      expect(controller.shouldOfferAfterCampaign, isTrue);

      await tester.pumpReviewCalendarApp(
        campaignRepository: campaignRepository,
        notificationRegistration: controller,
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byKey(const ValueKey('tab-bar:upload')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('직접 입력'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(find.byType(TextField).first, '테스트 카페 홍대점');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('캘린더에 등록하기'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(campaignRepository.createCallCount, 1);
      expect(
        find.byKey(const ValueKey('notification:benefit-dialog')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('notification:later')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      expect(controller.shouldOfferAfterCampaign, isFalse);
    },
  );
}

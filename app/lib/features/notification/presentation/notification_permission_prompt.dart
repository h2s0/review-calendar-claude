import 'package:flutter/material.dart';
import 'package:review_calendar/core/errors/user_recovery_policy.dart';
import 'package:review_calendar/features/notification/domain/notification_device_registration.dart';

/// Ported verbatim from
/// review-calendar/app/lib/features/notification/presentation/notification_permission_prompt.dart
/// — a plain Material `AlertDialog`, not a custom design-system component,
/// so it doesn't need to match the claude.ai screen mockups.
Future<void> offerCampaignNotifications({
  required BuildContext context,
  required NotificationDeviceRegistrationController controller,
}) async {
  if (!controller.shouldOfferAfterCampaign) {
    return;
  }
  final enable = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const ValueKey('notification:benefit-dialog'),
      title: const Text('중요한 일정을 놓치지 마세요'),
      content: const Text(
        '등록한 일정의 방문일과 포스팅 마감이 가까워지면 미리 알려드릴게요. '
        '알림은 설정에서 언제든 바꿀 수 있어요.',
      ),
      actions: [
        TextButton(
          key: const ValueKey('notification:later'),
          onPressed: () => Navigator.pop(context, false),
          child: const Text('나중에'),
        ),
        FilledButton(
          key: const ValueKey('notification:enable'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('알림 받기'),
        ),
      ],
    ),
  );
  if (enable != true) {
    controller.declineForNow();
    return;
  }
  try {
    final status = await controller.requestAfterExplanation();
    if (!context.mounted || status == NotificationPermissionStatus.authorized) {
      return;
    }
    final message = recoveryPresentationFor(
      UserRecoveryScenario.notificationPermissionDenied,
    ).message;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정은 등록됐어요. 알림 연결은 나중에 다시 시도할게요.')),
      );
    }
  }
}

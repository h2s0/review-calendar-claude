/// Ported verbatim from review-calendar/app/lib/core/errors/user_recovery_policy.dart
enum UserRecoveryScenario {
  offline,
  analysisFailed,
  partialExtraction,
  extractionConflict,
  missingRequired,
  notificationPermissionDenied,
  invalidScheduleMove,
  saveFailed,
  emptyFilter,
}

final class UserRecoveryPresentation {
  const UserRecoveryPresentation({
    required this.message,
    required this.primaryActionLabel,
    required this.preservesWork,
    this.secondaryActionLabel,
  });

  final String message;
  final String primaryActionLabel;
  final String? secondaryActionLabel;
  final bool preservesWork;
}

UserRecoveryPresentation recoveryPresentationFor(
  UserRecoveryScenario scenario,
) {
  return switch (scenario) {
    UserRecoveryScenario.offline => const UserRecoveryPresentation(
      message: '저장된 일정은 계속 볼 수 있어요. 분석과 동기화는 인터넷 연결이 필요해요.',
      primaryActionLabel: '다시 시도',
      preservesWork: true,
    ),
    UserRecoveryScenario.analysisFailed => const UserRecoveryPresentation(
      message: '선택한 이미지는 유지했어요. 다시 분석하거나 직접 입력할 수 있어요.',
      primaryActionLabel: '다시 분석',
      secondaryActionLabel: '직접 입력',
      preservesWork: true,
    ),
    UserRecoveryScenario.partialExtraction => const UserRecoveryPresentation(
      message: '확인된 값은 유지했어요. 누락된 항목만 확인해 주세요.',
      primaryActionLabel: '확인 필요 항목 보기',
      preservesWork: true,
    ),
    UserRecoveryScenario.extractionConflict => const UserRecoveryPresentation(
      message: '이미지마다 다른 값이 있어요. 다른 일정 이미지가 섞였는지 확인해 주세요.',
      primaryActionLabel: '충돌 항목 확인',
      preservesWork: true,
    ),
    UserRecoveryScenario.missingRequired => const UserRecoveryPresentation(
      message: '필수 입력과 형식을 확인해 주세요.',
      primaryActionLabel: '누락 항목으로 이동',
      preservesWork: true,
    ),
    UserRecoveryScenario.notificationPermissionDenied =>
      const UserRecoveryPresentation(
        message: '알림을 허용하지 않아도 앱은 정상적으로 동작해요. 기기 설정에서 나중에 바꿀 수 있어요.',
        primaryActionLabel: '기기 설정 확인',
        preservesWork: true,
      ),
    UserRecoveryScenario.invalidScheduleMove => const UserRecoveryPresentation(
      message: '선택할 수 없는 날짜예요. 일정은 원래 날짜에 그대로 있어요.',
      primaryActionLabel: '가능한 날짜 확인',
      preservesWork: true,
    ),
    UserRecoveryScenario.saveFailed => const UserRecoveryPresentation(
      message: '저장하지 못했어요. 입력값은 그대로 유지했어요.',
      primaryActionLabel: '다시 저장',
      preservesWork: true,
    ),
    UserRecoveryScenario.emptyFilter => const UserRecoveryPresentation(
      message: '선택한 조건에 맞는 기록이 없어요.',
      primaryActionLabel: '전체 초기화',
      preservesWork: true,
    ),
  };
}

String recoveryLogCodeFor(UserRecoveryScenario scenario) {
  return switch (scenario) {
    UserRecoveryScenario.offline => 'recovery.offline',
    UserRecoveryScenario.analysisFailed => 'recovery.analysis_failed',
    UserRecoveryScenario.partialExtraction => 'recovery.partial_extraction',
    UserRecoveryScenario.extractionConflict => 'recovery.extraction_conflict',
    UserRecoveryScenario.missingRequired => 'recovery.missing_required',
    UserRecoveryScenario.notificationPermissionDenied =>
      'recovery.notification_permission_denied',
    UserRecoveryScenario.invalidScheduleMove =>
      'recovery.invalid_schedule_move',
    UserRecoveryScenario.saveFailed => 'recovery.save_failed',
    UserRecoveryScenario.emptyFilter => 'recovery.empty_filter',
  };
}

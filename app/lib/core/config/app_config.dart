enum AppEnvironment { development, test, production }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.firebaseProjectId,
    this.firebaseEmulatorHost,
    this.googleIosClientId,
    this.googleServerClientId,
    this.kakaoNativeAppKey,
    this.appVersion = '1.0.0+1',
  });

  static const String developmentProjectId = 'demo-review-calendar-dev';
  static const String testProjectId = 'demo-review-calendar-test';

  static const AppConfig development = AppConfig(
    environment: AppEnvironment.development,
    firebaseProjectId: developmentProjectId,
  );

  static const AppConfig test = AppConfig(
    environment: AppEnvironment.test,
    firebaseProjectId: testProjectId,
  );

  final AppEnvironment environment;
  final String firebaseProjectId;
  final String? firebaseEmulatorHost;
  final String? googleIosClientId;
  final String? googleServerClientId;
  final String? kakaoNativeAppKey;
  final String appVersion;

  bool get usesFirebaseEmulator => environment != AppEnvironment.production;

  String get publicEnvironmentLabel => switch (environment) {
    AppEnvironment.development => '개발',
    AppEnvironment.test => '테스트',
    AppEnvironment.production => '운영',
  };

  factory AppConfig.fromDartDefines() {
    return AppConfig.parse(
      environmentName: const String.fromEnvironment('APP_ENV'),
      firebaseProjectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
      firebaseEmulatorHost: const String.fromEnvironment(
        'FIREBASE_EMULATOR_HOST',
      ),
      googleIosClientId: const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
      googleServerClientId: const String.fromEnvironment(
        'GOOGLE_SERVER_CLIENT_ID',
      ),
      kakaoNativeAppKey: const String.fromEnvironment('KAKAO_NATIVE_APP_KEY'),
      appVersion: const String.fromEnvironment(
        'APP_VERSION',
        defaultValue: '1.0.0+1',
      ),
    );
  }

  factory AppConfig.parse({
    required String environmentName,
    required String firebaseProjectId,
    String firebaseEmulatorHost = '',
    String googleIosClientId = '',
    String googleServerClientId = '',
    String kakaoNativeAppKey = '',
    String appVersion = '1.0.0+1',
  }) {
    final environment = switch (environmentName) {
      'development' => AppEnvironment.development,
      'test' => AppEnvironment.test,
      'production' => AppEnvironment.production,
      _ => throw StateError(
        'APP_ENV must be development, test, or production.',
      ),
    };

    if (firebaseProjectId.isEmpty) {
      throw StateError('FIREBASE_PROJECT_ID must not be empty.');
    }

    switch (environment) {
      case AppEnvironment.development:
        if (firebaseProjectId != developmentProjectId) {
          throw StateError(
            'Development must use Firebase project $developmentProjectId.',
          );
        }
      case AppEnvironment.test:
        if (firebaseProjectId != testProjectId) {
          throw StateError('Tests must use Firebase project $testProjectId.');
        }
      case AppEnvironment.production:
        if (firebaseProjectId.startsWith('demo-') ||
            firebaseProjectId == 'replace-with-production-project-id') {
          throw StateError(
            'Production requires a real non-demo Firebase project.',
          );
        }
        _requireProductionValue('GOOGLE_IOS_CLIENT_ID', googleIosClientId);
        _requireProductionValue(
          'GOOGLE_SERVER_CLIENT_ID',
          googleServerClientId,
        );
        if (kakaoNativeAppKey.trim().isNotEmpty) {
          _requireProductionValue('KAKAO_NATIVE_APP_KEY', kakaoNativeAppKey);
        }
    }

    return AppConfig(
      environment: environment,
      firebaseProjectId: firebaseProjectId,
      firebaseEmulatorHost: _nullWhenEmpty(firebaseEmulatorHost),
      googleIosClientId: _nullWhenEmpty(googleIosClientId),
      googleServerClientId: _nullWhenEmpty(googleServerClientId),
      kakaoNativeAppKey: _nullWhenEmpty(kakaoNativeAppKey),
      appVersion: appVersion.trim().isEmpty ? '알 수 없음' : appVersion.trim(),
    );
  }
}

String? _nullWhenEmpty(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

void _requireProductionValue(String name, String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty ||
      normalized.contains('replace-with') ||
      normalized.contains('placeholder')) {
    throw StateError('Production requires a configured $name.');
  }
}

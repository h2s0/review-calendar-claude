import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:review_calendar/app/app_shell.dart';
import 'package:review_calendar/core/config/app_config.dart';
import 'package:review_calendar/core/firebase/firebase_bootstrap.dart';
import 'package:review_calendar/features/auth/data/auth_repository.dart';
import 'package:review_calendar/features/auth/data/federated_auth_provider_handlers.dart';
import 'package:review_calendar/features/auth/data/firebase_auth_repository.dart';
import 'package:review_calendar/features/auth/data/kakao_auth_provider_handler.dart';
import 'package:review_calendar/features/account/presentation/account_view_model.dart';
import 'package:review_calendar/features/auth/domain/auth_user.dart';
import 'package:review_calendar/features/auth/presentation/auth_gate.dart';
import 'package:review_calendar/features/auth/presentation/auth_view_model.dart';
import 'package:review_calendar/features/calendar/presentation/calendar_view_model.dart';
import 'package:review_calendar/features/campaign/data/campaign_repository.dart';
import 'package:review_calendar/features/campaign/data/firestore_campaign_repository.dart';
import 'package:review_calendar/features/campaign/domain/campaign_id.dart';
import 'package:review_calendar/features/home/presentation/home_view_model.dart';
import 'package:review_calendar/features/notification/data/firebase_notification_device_registration.dart';
import 'package:review_calendar/features/notification/domain/notification_device_registration.dart';
import 'package:review_calendar/features/records/data/firestore_record_categories_repository.dart';
import 'package:review_calendar/features/records/data/record_categories_repository.dart';
import 'package:review_calendar/features/registration/data/apple_vision_campaign_ocr_engine.dart';
import 'package:review_calendar/features/registration/data/fallback_campaign_analysis_service.dart';
import 'package:review_calendar/features/registration/data/gemini_campaign_analysis_service.dart';
import 'package:review_calendar/features/registration/domain/local_campaign_ocr.dart';
import 'package:review_calendar/features/revenue/presentation/revenue_view_model.dart';
import 'package:review_calendar/ui/core/theme/rc_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromDartDefines();
  await initializeFirebase(config);
  await initializeKakaoSdk(config);

  final auth = firebase.FirebaseAuth.instance;
  final functions = await _createFunctions(config);
  final kakaoSignOut = createKakaoProviderSignOut(config);

  runApp(
    ReviewCalendarApp(
      authRepository: FirebaseAuthRepository(
        auth: auth,
        providerSignIns:
            createFederatedProviderSignIns(auth: auth, config: config)
              ..[AuthProvider.kakao] = createKakaoProviderSignIn(
                auth: auth,
                functions: functions,
                config: config,
              ),
        providerSignOuts: [createGoogleProviderSignOut(config), ?kakaoSignOut],
        accountDeletion: () async {
          try {
            await functions
                .httpsCallable(
                  'deleteAccount',
                  options: HttpsCallableOptions(
                    timeout: const Duration(seconds: 30),
                    limitedUseAppCheckToken: true,
                  ),
                )
                .call<Map<String, dynamic>>();
          } on FirebaseFunctionsException catch (error) {
            throw firebase.FirebaseAuthException(code: error.code);
          }
        },
      ),
      campaignRepositoryFactory: (user) => FirestoreCampaignRepository(
        firestore: FirebaseFirestore.instance,
        currentUserId: UserId(user.id),
      ),
      categoriesRepositoryFactory: (user) =>
          FirestoreRecordCategoriesRepository(
            firestore: FirebaseFirestore.instance,
            userId: user.id,
          ),
      notificationRegistrationFactory: (user) =>
          NotificationDeviceRegistrationController(
            userId: user.id,
            permissionGateway: FirebaseNotificationPermissionGateway(
              FirebaseMessaging.instance,
            ),
            tokenSource: FirebaseNotificationTokenSource(
              FirebaseMessaging.instance,
            ),
            tokenRepository: FirestoreNotificationTokenRepository(
              FirebaseFirestore.instance,
            ),
          ),
      // Gemini first (understands screenshot context/layout); silently
      // falls back to the on-device Vision OCR path if the free-tier quota
      // is exhausted, rate-limited, or the network/provider is down.
      analysisServiceFactory: (user) => FallbackCampaignAnalysisService(
        primary: GeminiCampaignAnalysisService(
          functions: functions,
          storage: FirebaseStorage.instance,
          ownerId: user.id,
        ),
        fallback: const OcrCampaignAnalysisService(
          AppleVisionCampaignOcrEngine(),
        ),
      ),
    ),
  );
}

/// On Apple platforms, `initializeFirebase` deliberately keeps the primary
/// `FirebaseApp` under its real `GoogleService-Info.plist` identity even in
/// emulator mode (Kakao/Google/Apple sign-in all validate against the real,
/// bundle-ID-registered app) — but the local Functions emulator only serves
/// the dart-define'd emulator project ID. A callable request built from the
/// primary app's real project ID 404s against it even though Firestore/
/// Auth/Storage happily redirect regardless of project ID. Routing
/// Functions through a second, emulator-scoped app fixes that without
/// touching the primary app's identity.
Future<FirebaseFunctions> _createFunctions(AppConfig config) async {
  final usesAppleNativeConfig =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);
  if (!config.usesFirebaseEmulator || !usesAppleNativeConfig) {
    return FirebaseFunctions.instanceFor(region: 'asia-northeast3');
  }
  final emulatorApp = await Firebase.initializeApp(
    name: 'emulatorFunctions',
    options: firebaseEmulatorOptions(config),
  );
  final functions = FirebaseFunctions.instanceFor(
    app: emulatorApp,
    region: 'asia-northeast3',
  );
  functions.useFunctionsEmulator(
    config.firebaseEmulatorHost ?? '127.0.0.1',
    5001,
    automaticHostMapping: false,
  );
  return functions;
}

class ReviewCalendarApp extends StatefulWidget {
  const ReviewCalendarApp({
    required this.authRepository,
    required this.campaignRepositoryFactory,
    required this.categoriesRepositoryFactory,
    this.notificationRegistrationFactory,
    this.analysisServiceFactory,
    super.key,
  });

  final AuthRepository authRepository;
  final CampaignRepository Function(AuthUser user) campaignRepositoryFactory;
  final RecordCategoriesRepository Function(AuthUser user)
  categoriesRepositoryFactory;
  // Nullable: tests don't need a real (or fake) push-notification stack to
  // exercise the product flows, matching the sibling's own optional wiring.
  final NotificationDeviceRegistrationController Function(AuthUser user)?
  notificationRegistrationFactory;
  // Nullable: null lets UploadFlow fall back to its own default (currently
  // the on-device OCR path) — tests inject a fake instead of this factory.
  final LocalCampaignAnalysisService Function(AuthUser user)?
  analysisServiceFactory;

  @override
  State<ReviewCalendarApp> createState() => _ReviewCalendarAppState();
}

class _ReviewCalendarAppState extends State<ReviewCalendarApp> {
  late final AuthViewModel _authViewModel;

  @override
  void initState() {
    super.initState();
    _authViewModel = AuthViewModel(widget.authRepository);
  }

  @override
  void dispose() {
    _authViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '리뷰캘린더',
      debugShowCheckedModeBanner: false,
      theme: RcTheme.light(),
      home: AuthGate(
        viewModel: _authViewModel,
        authenticatedBuilder: (user) => _AuthenticatedApp(
          key: ValueKey(user.id),
          ownerId: user.id,
          authRepository: widget.authRepository,
          campaignRepository: widget.campaignRepositoryFactory(user),
          categoriesRepository: widget.categoriesRepositoryFactory(user),
          notificationRegistration: widget.notificationRegistrationFactory
              ?.call(user),
          analysisService: widget.analysisServiceFactory?.call(user),
        ),
      ),
    );
  }
}

/// Owns the lifecycle of view models that depend on the signed-in user —
/// rebuilt fresh (via the `ValueKey(user.id)` above) whenever the user
/// changes, so a sign-out/sign-in never leaks the previous user's data.
class _AuthenticatedApp extends StatefulWidget {
  const _AuthenticatedApp({
    required this.authRepository,
    required this.campaignRepository,
    required this.categoriesRepository,
    required this.ownerId,
    this.notificationRegistration,
    this.analysisService,
    super.key,
  });

  final AuthRepository authRepository;
  final CampaignRepository campaignRepository;
  final RecordCategoriesRepository categoriesRepository;
  final String ownerId;
  final NotificationDeviceRegistrationController? notificationRegistration;
  final LocalCampaignAnalysisService? analysisService;

  @override
  State<_AuthenticatedApp> createState() => _AuthenticatedAppState();
}

class _AuthenticatedAppState extends State<_AuthenticatedApp> {
  late final CalendarViewModel _calendarViewModel;
  late final HomeViewModel _homeViewModel;
  late final RevenueViewModel _revenueViewModel;
  late final AccountViewModel _accountViewModel;

  @override
  void initState() {
    super.initState();
    _calendarViewModel = CalendarViewModel(widget.campaignRepository);
    _homeViewModel = HomeViewModel(widget.campaignRepository);
    _revenueViewModel = RevenueViewModel(widget.campaignRepository);
    _accountViewModel = AccountViewModel(widget.authRepository);
    unawaited(_initializeNotifications());
  }

  @override
  void dispose() {
    _calendarViewModel.dispose();
    _homeViewModel.dispose();
    _revenueViewModel.dispose();
    _accountViewModel.dispose();
    unawaited(widget.categoriesRepository.dispose());
    unawaited(widget.notificationRegistration?.close());
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    try {
      await widget.notificationRegistration?.initialize();
    } catch (_) {
      // Notification setup must never block the authenticated product flow.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      calendarViewModel: _calendarViewModel,
      homeViewModel: _homeViewModel,
      revenueViewModel: _revenueViewModel,
      accountViewModel: _accountViewModel,
      campaignRepository: widget.campaignRepository,
      categoriesRepository: widget.categoriesRepository,
      ownerId: widget.ownerId,
      notificationRegistration: widget.notificationRegistration,
      analysisService: widget.analysisService,
    );
  }
}

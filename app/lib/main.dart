import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:review_calendar/app/app_shell.dart';
import 'package:review_calendar/core/config/app_config.dart';
import 'package:review_calendar/core/firebase/firebase_bootstrap.dart';
import 'package:review_calendar/features/auth/data/auth_repository.dart';
import 'package:review_calendar/features/auth/data/federated_auth_provider_handlers.dart';
import 'package:review_calendar/features/auth/data/firebase_auth_repository.dart';
import 'package:review_calendar/features/auth/data/kakao_auth_provider_handler.dart';
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
import 'package:review_calendar/features/revenue/presentation/revenue_view_model.dart';
import 'package:review_calendar/ui/core/theme/rc_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromDartDefines();
  await initializeFirebase(config);
  await initializeKakaoSdk(config);

  final auth = firebase.FirebaseAuth.instance;
  final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');
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
    ),
  );
}

class ReviewCalendarApp extends StatefulWidget {
  const ReviewCalendarApp({
    required this.authRepository,
    required this.campaignRepositoryFactory,
    required this.categoriesRepositoryFactory,
    this.notificationRegistrationFactory,
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
          campaignRepository: widget.campaignRepositoryFactory(user),
          categoriesRepository: widget.categoriesRepositoryFactory(user),
          notificationRegistration: widget.notificationRegistrationFactory
              ?.call(user),
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
    required this.campaignRepository,
    required this.categoriesRepository,
    required this.ownerId,
    this.notificationRegistration,
    super.key,
  });

  final CampaignRepository campaignRepository;
  final RecordCategoriesRepository categoriesRepository;
  final String ownerId;
  final NotificationDeviceRegistrationController? notificationRegistration;

  @override
  State<_AuthenticatedApp> createState() => _AuthenticatedAppState();
}

class _AuthenticatedAppState extends State<_AuthenticatedApp> {
  late final CalendarViewModel _calendarViewModel;
  late final HomeViewModel _homeViewModel;
  late final RevenueViewModel _revenueViewModel;

  @override
  void initState() {
    super.initState();
    _calendarViewModel = CalendarViewModel(widget.campaignRepository);
    _homeViewModel = HomeViewModel(widget.campaignRepository);
    _revenueViewModel = RevenueViewModel(widget.campaignRepository);
    unawaited(_initializeNotifications());
  }

  @override
  void dispose() {
    _calendarViewModel.dispose();
    _homeViewModel.dispose();
    _revenueViewModel.dispose();
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
      campaignRepository: widget.campaignRepository,
      categoriesRepository: widget.categoriesRepository,
      ownerId: widget.ownerId,
      notificationRegistration: widget.notificationRegistration,
    );
  }
}

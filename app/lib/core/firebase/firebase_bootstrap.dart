import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:review_calendar/core/config/app_config.dart';
import 'package:review_calendar/core/firebase/firestore_offline_config.dart';

/// Ported verbatim from review-calendar/app/lib/core/firebase/firebase_bootstrap.dart
/// (only the firestore_offline_config import path changed — that file lives
/// under core/firebase here instead of features/campaign/data, since the
/// campaign feature hasn't been ported yet).
Future<void> initializeFirebase(AppConfig config) async {
  if (config.usesFirebaseEmulator) {
    final usesApplePlatformConfig =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    if (usesApplePlatformConfig) {
      await Firebase.initializeApp();
    } else {
      await Firebase.initializeApp(options: firebaseEmulatorOptions(config));
    }
  } else {
    await Firebase.initializeApp();
  }

  if (!kIsWeb) {
    final usesDebugAppCheck = shouldUseDebugAppCheckProvider(config);
    await _activateAppCheck(usesDebugProvider: usesDebugAppCheck);
    if (usesDebugAppCheck) {
      try {
        await FirebaseAppCheck.instance.getToken(true);
      } catch (_) {
        await _activateAppCheck(usesDebugProvider: true);
        await FirebaseAppCheck.instance.getToken(true);
      }
    }
  }

  configureFirestoreOffline(FirebaseFirestore.instance);

  if (!config.usesFirebaseEmulator) {
    return;
  }

  final host =
      config.firebaseEmulatorHost ??
      (defaultTargetPlatform == TargetPlatform.android
          ? '10.0.2.2'
          : '127.0.0.1');
  FirebaseFirestore.instance.useFirestoreEmulator(
    host,
    8180,
    automaticHostMapping: false,
  );
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  await FirebaseStorage.instance.useStorageEmulator(
    host,
    9199,
    automaticHostMapping: false,
  );
  FirebaseFunctions.instanceFor(
    region: 'asia-northeast3',
  ).useFunctionsEmulator(host, 5001, automaticHostMapping: false);
}

Future<void> _activateAppCheck({required bool usesDebugProvider}) =>
    FirebaseAppCheck.instance.activate(
      providerAndroid: usesDebugProvider
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: usesDebugProvider
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );

@visibleForTesting
bool shouldUseDebugAppCheckProvider(
  AppConfig config, {
  bool isDebugBuild = kDebugMode,
}) => config.usesFirebaseEmulator || isDebugBuild;

// Also used by main.dart to scope a secondary FirebaseApp for the
// Functions emulator on Apple platforms — see `_createFunctions`'s doc
// comment there for why that's needed.
FirebaseOptions firebaseEmulatorOptions(AppConfig config) {
  return FirebaseOptions(
    apiKey: 'AIzaSy000000000000000000000000000000000',
    appId: '1:1234567890:ios:1234567890abcdef',
    messagingSenderId: '1234567890',
    projectId: config.firebaseProjectId,
    storageBucket: '${config.firebaseProjectId}.appspot.com',
  );
}

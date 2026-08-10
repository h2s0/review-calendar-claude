import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:review_calendar/core/config/app_config.dart';
import 'package:review_calendar/features/auth/data/auth_repository.dart';
import 'package:review_calendar/features/auth/data/firebase_auth_repository.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

typedef PopupSignIn = Future<void> Function(firebase.AuthProvider provider);
typedef CredentialSignIn =
    Future<void> Function(firebase.AuthCredential credential);
typedef InitializeGoogle = Future<void> Function();
typedef AuthenticateGoogle = Future<String?> Function();
typedef RequestAppleCredential =
    Future<AppleIdentityToken> Function(String hashedNonce);

final class AppleIdentityToken {
  const AppleIdentityToken({
    required this.identityToken,
    this.givenName,
    this.familyName,
  });

  final String? identityToken;
  final String? givenName;
  final String? familyName;
}

final class FederatedAuthProviderHandlers {
  FederatedAuthProviderHandlers({
    required this.usePopup,
    required this.popupSignIn,
    required this.credentialSignIn,
    required this.initializeGoogle,
    required this.authenticateGoogle,
    required this.requestAppleCredential,
    this.nonceGenerator = generateNonce,
  });

  final bool usePopup;
  final PopupSignIn popupSignIn;
  final CredentialSignIn credentialSignIn;
  final InitializeGoogle initializeGoogle;
  final AuthenticateGoogle authenticateGoogle;
  final RequestAppleCredential requestAppleCredential;
  final String Function() nonceGenerator;

  Map<AuthProvider, FirebaseProviderSignIn> asMap() {
    return {
      AuthProvider.google: signInWithGoogle,
      AuthProvider.apple: signInWithApple,
    };
  }

  Future<void> signInWithGoogle() async {
    if (usePopup) {
      await popupSignIn(firebase.GoogleAuthProvider());
      return;
    }

    try {
      await initializeGoogle();
      final idToken = await authenticateGoogle();
      if (idToken == null || idToken.isEmpty) {
        throw const AuthProviderConfigurationException(
          'Google 로그인 토큰을 확인하지 못했어요. 앱 설정을 확인해 주세요.',
        );
      }
      await credentialSignIn(
        firebase.GoogleAuthProvider.credential(idToken: idToken),
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        throw const AuthProviderCancelledException();
      }
      throw const AuthProviderConfigurationException(
        'Google 로그인을 시작하지 못했어요. 앱 등록 설정을 확인해 주세요.',
      );
    }
  }

  Future<void> signInWithApple() async {
    if (usePopup) {
      final provider = firebase.AppleAuthProvider()..addScope('email');
      await popupSignIn(provider);
      return;
    }

    try {
      final rawNonce = nonceGenerator();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
      final appleCredential = await requestAppleCredential(hashedNonce);
      final identityToken = appleCredential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw const AuthProviderConfigurationException(
          'Apple 로그인 토큰을 확인하지 못했어요. 다시 시도해 주세요.',
        );
      }

      await credentialSignIn(
        firebase.AppleAuthProvider.credentialWithIDToken(
          identityToken,
          rawNonce,
          firebase.AppleFullPersonName(
            givenName: appleCredential.givenName,
            familyName: appleCredential.familyName,
          ),
        ),
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw const AuthProviderCancelledException();
      }
      throw const AuthProviderConfigurationException(
        'Apple 로그인을 시작하지 못했어요. 앱 등록 설정을 확인해 주세요.',
      );
    } on SignInWithAppleException {
      throw const AuthProviderConfigurationException(
        'Apple 로그인을 시작하지 못했어요. 앱 등록 설정을 확인해 주세요.',
      );
    }
  }
}

Map<AuthProvider, FirebaseProviderSignIn> createFederatedProviderSignIns({
  required firebase.FirebaseAuth auth,
  required AppConfig config,
}) {
  final googleSignIn = GoogleSignIn.instance;
  Future<void>? googleInitialization;

  final handlers = FederatedAuthProviderHandlers(
    usePopup: kIsWeb,
    popupSignIn: (provider) async {
      await auth.signInWithPopup(provider);
    },
    credentialSignIn: (credential) async {
      await auth.signInWithCredential(credential);
    },
    initializeGoogle: () {
      return googleInitialization ??= googleSignIn.initialize(
        clientId: config.googleIosClientId,
        serverClientId: config.googleServerClientId,
      );
    },
    authenticateGoogle: () async {
      final account = await googleSignIn.authenticate();
      return account.authentication.idToken;
    },
    requestAppleCredential: (hashedNonce) async {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      return AppleIdentityToken(
        identityToken: credential.identityToken,
        givenName: credential.givenName,
        familyName: credential.familyName,
      );
    },
  );
  return handlers.asMap();
}

FirebaseProviderSignOut createGoogleProviderSignOut(AppConfig config) {
  final googleSignIn = GoogleSignIn.instance;
  Future<void>? googleInitialization;

  return () async {
    await (googleInitialization ??= googleSignIn.initialize(
      clientId: config.googleIosClientId,
      serverClientId: config.googleServerClientId,
    ));
    await googleSignIn.signOut();
  };
}

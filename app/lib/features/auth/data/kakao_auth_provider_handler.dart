import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:review_calendar/core/config/app_config.dart';
import 'package:review_calendar/features/auth/data/auth_repository.dart';
import 'package:review_calendar/features/auth/data/firebase_auth_repository.dart';

typedef AuthenticateWithKakao = Future<String> Function();
typedef ExchangeKakaoToken = Future<String> Function(String accessToken);
typedef SignInWithFirebaseCustomToken =
    Future<void> Function(String customToken);

final class KakaoAuthProviderHandler {
  const KakaoAuthProviderHandler({
    required this.authenticateWithKakao,
    required this.exchangeKakaoToken,
    required this.signInWithFirebaseCustomToken,
  });

  final AuthenticateWithKakao authenticateWithKakao;
  final ExchangeKakaoToken exchangeKakaoToken;
  final SignInWithFirebaseCustomToken signInWithFirebaseCustomToken;

  Future<void> signIn() async {
    try {
      final accessToken = await authenticateWithKakao();
      final customToken = await exchangeKakaoToken(accessToken);
      await signInWithFirebaseCustomToken(customToken);
    } on KakaoClientException catch (error) {
      debugPrint('Kakao sign-in client failure: ${error.reason}');
      if (error.reason == ClientErrorCause.cancelled) {
        throw const AuthProviderCancelledException();
      }
      throw const AuthProviderConfigurationException(
        '카카오 로그인을 시작하지 못했어요. 앱 등록 설정을 확인해 주세요.',
      );
    } on KakaoAuthException catch (error) {
      debugPrint(
        'Kakao sign-in auth failure: ${error.error} '
        'description=${error.errorDescription}',
      );
      throw AuthProviderConfigurationException(switch (error.error) {
        AuthErrorCause.misconfigured =>
          '카카오 iOS 플랫폼 설정을 확인해 주세요. 번들 ID가 앱과 같아야 해요.',
        AuthErrorCause.unauthorized => '카카오 로그인이 비활성화되어 있어요. 제품 설정에서 활성화해 주세요.',
        AuthErrorCause.invalidClient =>
          '카카오 Native App Key가 올바르지 않아요. 플랫폼 키를 확인해 주세요.',
        _ => '카카오 인증 설정을 확인하지 못했어요. 잠시 후 다시 시도해 주세요.',
      });
    } on KakaoException catch (error) {
      debugPrint('Kakao sign-in SDK failure: ${error.runtimeType}');
      throw const AuthProviderConfigurationException(
        '카카오 로그인을 시작하지 못했어요. 잠시 후 다시 시도해 주세요.',
      );
    } on PlatformException catch (error) {
      debugPrint('Kakao sign-in platform failure: ${error.code}');
      if (error.code == 'CANCELED') {
        throw const AuthProviderCancelledException();
      }
      throw const AuthProviderConfigurationException(
        '카카오 로그인을 시작하지 못했어요. 잠시 후 다시 시도해 주세요.',
      );
    } on FirebaseFunctionsException catch (error) {
      debugPrint(
        'Kakao token exchange failure: ${error.code} message=${error.message}',
      );
      throw mapKakaoFunctionFailure(error.code);
    }
  }
}

AuthProviderException mapKakaoFunctionFailure(String code) {
  return switch (code) {
    'unavailable' ||
    'deadline-exceeded' ||
    'internal' => const AuthProviderNetworkException(),
    'resource-exhausted' => const AuthProviderConfigurationException(
      '로그인 요청이 너무 많아요. 잠시 후 다시 시도해 주세요.',
    ),
    'unauthenticated' => const AuthProviderConfigurationException(
      '카카오 로그인 정보가 만료되었어요. 다시 로그인해 주세요.',
    ),
    'permission-denied' => const AuthProviderConfigurationException(
      '카카오 앱 설정이 일치하지 않아요. 앱 키와 앱 ID를 확인해 주세요.',
    ),
    _ => const AuthProviderConfigurationException(
      '카카오 로그인을 완료하지 못했어요. 잠시 후 다시 시도해 주세요.',
    ),
  };
}

Future<void> initializeKakaoSdk(AppConfig config) async {
  final nativeAppKey = config.kakaoNativeAppKey;
  if (nativeAppKey == null) {
    return;
  }
  await KakaoSdk.init(nativeAppKey: nativeAppKey, loggingEnabled: kDebugMode);
}

FirebaseProviderSignIn createKakaoProviderSignIn({
  required firebase.FirebaseAuth auth,
  required FirebaseFunctions functions,
  required AppConfig config,
}) {
  final handler = KakaoAuthProviderHandler(
    authenticateWithKakao: () async {
      if (config.kakaoNativeAppKey == null) {
        throw const AuthProviderConfigurationException(
          '카카오 앱 등록이 아직 완료되지 않았어요.',
        );
      }

      if (await isKakaoTalkInstalled()) {
        try {
          final token = await UserApi.instance.loginWithKakaoTalk();
          return token.accessToken;
        } on PlatformException catch (error) {
          if (error.code == 'CANCELED') {
            rethrow;
          }
        } on KakaoClientException catch (error) {
          if (error.reason == ClientErrorCause.cancelled) {
            rethrow;
          }
        }
      }
      final token = await UserApi.instance.loginWithKakaoAccount();
      return token.accessToken;
    },
    exchangeKakaoToken: (accessToken) async {
      final result = await functions
          .httpsCallable(
            'exchangeKakaoToken',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
          )
          .call<Map<String, dynamic>>({'accessToken': accessToken});
      final customToken = result.data['customToken'];
      if (customToken is! String || customToken.isEmpty) {
        throw const AuthProviderConfigurationException(
          '카카오 인증 응답을 확인하지 못했어요. 잠시 후 다시 시도해 주세요.',
        );
      }
      return customToken;
    },
    signInWithFirebaseCustomToken: (customToken) async {
      await auth.signInWithCustomToken(customToken);
    },
  );
  return handler.signIn;
}

FirebaseProviderSignOut? createKakaoProviderSignOut(AppConfig config) {
  if (config.kakaoNativeAppKey == null) {
    return null;
  }
  return () async {
    await UserApi.instance.logout();
  };
}

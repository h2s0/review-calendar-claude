import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:review_calendar/features/auth/data/auth_repository.dart';
import 'package:review_calendar/features/auth/domain/auth_user.dart';

typedef FirebaseProviderSignIn = Future<void> Function();
typedef FirebaseProviderSignOut = Future<void> Function();
typedef FirebaseAccountDeletion = Future<void> Function();

final class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required this.auth,
    this.providerSignIns = const {},
    this.providerSignOuts = const [],
    this.accountDeletion,
  });

  final firebase.FirebaseAuth auth;
  final Map<AuthProvider, FirebaseProviderSignIn> providerSignIns;
  final List<FirebaseProviderSignOut> providerSignOuts;
  final FirebaseAccountDeletion? accountDeletion;

  @override
  Stream<AuthUser?> authStateChanges() {
    return auth.authStateChanges().map((user) {
      if (user == null) {
        return null;
      }
      return AuthUser(
        id: user.uid,
        displayName: user.displayName,
        email: user.email,
      );
    });
  }

  @override
  Future<AuthSignInResult> signIn(AuthProvider provider) async {
    final signIn = providerSignIns[provider];
    if (signIn == null) {
      return const AuthSignInFailure(
        kind: AuthFailureKind.provider,
        message: '이 로그인 방식은 아직 연결을 준비하고 있어요.',
      );
    }

    try {
      await signIn();
      return const AuthSignInSuccess();
    } on AuthProviderCancelledException {
      return const AuthSignInFailure(kind: AuthFailureKind.cancelled);
    } on AuthProviderNetworkException {
      return const AuthSignInFailure(kind: AuthFailureKind.network);
    } on AuthProviderConfigurationException catch (error) {
      return AuthSignInFailure(
        kind: AuthFailureKind.provider,
        message: error.message ?? _providerFailureMessage,
      );
    } on firebase.FirebaseAuthException catch (error) {
      return mapFirebaseAuthFailure(error);
    }
  }

  @override
  Future<AccountActionResult> signOut() async {
    var providerCleanupFailed = false;
    for (final providerSignOut in providerSignOuts) {
      try {
        await providerSignOut();
      } on Object {
        providerCleanupFailed = true;
      }
    }

    try {
      await auth.signOut();
      return providerCleanupFailed
          ? const AccountActionFailure(
              kind: AccountFailureKind.provider,
              message: '로그아웃했지만 연결된 로그인 앱의 세션 정리가 필요할 수 있어요.',
            )
          : const AccountActionSuccess();
    } on firebase.FirebaseAuthException catch (error) {
      return mapFirebaseAccountFailure(error);
    }
  }

  @override
  Future<AccountActionResult> reauthenticate(AuthProvider provider) async {
    final expectedUserId = auth.currentUser?.uid;
    if (expectedUserId == null) {
      return const AccountActionFailure(
        kind: AccountFailureKind.recentLoginRequired,
      );
    }

    final result = await signIn(provider);
    switch (result) {
      case AuthSignInFailure(:final kind, :final message):
        return AccountActionFailure(
          kind: switch (kind) {
            AuthFailureKind.cancelled => AccountFailureKind.cancelled,
            AuthFailureKind.network => AccountFailureKind.network,
            AuthFailureKind.provider => AccountFailureKind.provider,
          },
          message: message,
        );
      case AuthSignInSuccess():
        if (auth.currentUser?.uid != expectedUserId) {
          await auth.signOut();
          return const AccountActionFailure(
            kind: AccountFailureKind.differentAccount,
          );
        }
        return const AccountActionSuccess();
    }
  }

  @override
  Future<AccountActionResult> deleteAccount() async {
    final deletion = accountDeletion;
    if (deletion == null) {
      return const AccountActionFailure(
        kind: AccountFailureKind.provider,
        message: '계정 삭제 서버가 연결되지 않았어요.',
      );
    }

    try {
      await deletion();
      await _clearProviderSessions();
      await auth.signOut();
      return const AccountActionSuccess();
    } on firebase.FirebaseAuthException catch (error) {
      return mapFirebaseAccountFailure(error);
    } on Object {
      return const AccountActionFailure(kind: AccountFailureKind.retryable);
    }
  }

  Future<void> _clearProviderSessions() async {
    for (final providerSignOut in providerSignOuts) {
      try {
        await providerSignOut();
      } on Object {
        // The server-side deletion already completed. Local Firebase sign-out
        // remains authoritative even if a provider has no active session.
      }
    }
  }
}

const _providerFailureMessage = '로그인 공급자 연결을 완료하지 못했어요. 잠시 후 다시 시도해 주세요.';
const _accountConflictMessage =
    '이미 다른 로그인 방식으로 가입된 계정이에요. 기존 방식으로 로그인한 뒤 계정을 연결해 주세요.';

AuthSignInFailure mapFirebaseAuthFailure(firebase.FirebaseAuthException error) {
  return switch (error.code) {
    'popup-closed-by-user' ||
    'web-context-cancelled' ||
    'canceled' => const AuthSignInFailure(kind: AuthFailureKind.cancelled),
    'network-request-failed' ||
    'timeout' => const AuthSignInFailure(kind: AuthFailureKind.network),
    'account-exists-with-different-credential' ||
    'credential-already-in-use' ||
    'email-already-in-use' => const AuthSignInFailure(
      kind: AuthFailureKind.provider,
      message: _accountConflictMessage,
    ),
    _ => const AuthSignInFailure(
      kind: AuthFailureKind.provider,
      message: _providerFailureMessage,
    ),
  };
}

AccountActionFailure mapFirebaseAccountFailure(
  firebase.FirebaseAuthException error,
) {
  return switch (error.code) {
    'network-request-failed' || 'timeout' || 'unavailable' =>
      const AccountActionFailure(kind: AccountFailureKind.network),
    'requires-recent-login' || 'failed-precondition' =>
      const AccountActionFailure(kind: AccountFailureKind.recentLoginRequired),
    _ => const AccountActionFailure(kind: AccountFailureKind.retryable),
  };
}

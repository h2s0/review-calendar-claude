import 'package:review_calendar/features/auth/domain/auth_user.dart';

enum AuthProvider { apple, google, kakao }

enum AuthFailureKind { cancelled, network, provider }

enum AccountFailureKind {
  cancelled,
  network,
  recentLoginRequired,
  differentAccount,
  retryable,
  provider,
}

sealed class AuthProviderException implements Exception {
  const AuthProviderException();
}

final class AuthProviderCancelledException extends AuthProviderException {
  const AuthProviderCancelledException();
}

final class AuthProviderNetworkException extends AuthProviderException {
  const AuthProviderNetworkException();
}

final class AuthProviderConfigurationException extends AuthProviderException {
  const AuthProviderConfigurationException([this.message]);

  final String? message;
}

sealed class AuthSignInResult {
  const AuthSignInResult();
}

final class AuthSignInSuccess extends AuthSignInResult {
  const AuthSignInSuccess();
}

final class AuthSignInFailure extends AuthSignInResult {
  const AuthSignInFailure({required this.kind, this.message});

  final AuthFailureKind kind;
  final String? message;
}

sealed class AccountActionResult {
  const AccountActionResult();
}

final class AccountActionSuccess extends AccountActionResult {
  const AccountActionSuccess();
}

final class AccountActionFailure extends AccountActionResult {
  const AccountActionFailure({required this.kind, this.message});

  final AccountFailureKind kind;
  final String? message;
}

abstract interface class AuthRepository {
  Stream<AuthUser?> authStateChanges();

  Future<AuthSignInResult> signIn(AuthProvider provider);

  Future<AccountActionResult> signOut();

  Future<AccountActionResult> reauthenticate(AuthProvider provider);

  Future<AccountActionResult> deleteAccount();
}

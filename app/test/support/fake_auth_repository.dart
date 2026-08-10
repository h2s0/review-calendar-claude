import 'dart:async';

import 'package:review_calendar/features/auth/data/auth_repository.dart';
import 'package:review_calendar/features/auth/domain/auth_user.dart';

typedef FakeSignInHandler =
    Future<AuthSignInResult> Function(AuthProvider provider);
typedef FakeAccountActionHandler = Future<AccountActionResult> Function();
typedef FakeReauthenticationHandler =
    Future<AccountActionResult> Function(AuthProvider provider);

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    AuthUser? initialUser = const AuthUser(id: 'user-001'),
    this.emitInitialState = true,
    FakeSignInHandler? signInHandler,
    FakeAccountActionHandler? signOutHandler,
    FakeReauthenticationHandler? reauthenticationHandler,
    FakeAccountActionHandler? deleteAccountHandler,
    this.userAfterSuccessfulSignIn = const AuthUser(id: 'user-001'),
  }) : _currentUser = initialUser,
       _signInHandler =
           signInHandler ?? ((_) async => const AuthSignInSuccess()),
       _signOutHandler =
           signOutHandler ?? (() async => const AccountActionSuccess()),
       _reauthenticationHandler =
           reauthenticationHandler ??
           ((_) async => const AccountActionSuccess()),
       _deleteAccountHandler =
           deleteAccountHandler ?? (() async => const AccountActionSuccess());

  final StreamController<AuthUser?> _changes =
      StreamController<AuthUser?>.broadcast();
  final bool emitInitialState;
  final FakeSignInHandler _signInHandler;
  final FakeAccountActionHandler _signOutHandler;
  final FakeReauthenticationHandler _reauthenticationHandler;
  final FakeAccountActionHandler _deleteAccountHandler;

  AuthUser? _currentUser;
  AuthUser? userAfterSuccessfulSignIn;
  final List<AuthProvider> signInCalls = [];
  final List<AuthProvider> reauthenticationCalls = [];
  int signOutCalls = 0;
  int deleteAccountCalls = 0;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    if (emitInitialState) {
      yield _currentUser;
    }
    yield* _changes.stream;
  }

  @override
  Future<AuthSignInResult> signIn(AuthProvider provider) async {
    signInCalls.add(provider);
    final result = await _signInHandler(provider);
    if (result is AuthSignInSuccess) {
      emit(userAfterSuccessfulSignIn);
    }
    return result;
  }

  @override
  Future<AccountActionResult> signOut() async {
    signOutCalls += 1;
    final result = await _signOutHandler();
    if (result is AccountActionSuccess) {
      emit(null);
    }
    return result;
  }

  @override
  Future<AccountActionResult> reauthenticate(AuthProvider provider) {
    reauthenticationCalls.add(provider);
    return _reauthenticationHandler(provider);
  }

  @override
  Future<AccountActionResult> deleteAccount() async {
    deleteAccountCalls += 1;
    final result = await _deleteAccountHandler();
    if (result is AccountActionSuccess) {
      emit(null);
    }
    return result;
  }

  void emit(AuthUser? user) {
    _currentUser = user;
    _changes.add(user);
  }

  Future<void> dispose() => _changes.close();
}

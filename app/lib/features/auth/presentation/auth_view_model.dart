import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:review_calendar/features/auth/data/auth_repository.dart';
import 'package:review_calendar/features/auth/domain/auth_user.dart';
import 'package:review_calendar/features/auth/presentation/auth_ui_state.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository) {
    _subscription = _repository.authStateChanges().listen(
      _onAuthStateChanged,
      onError: _onAuthStateError,
    );
  }

  final AuthRepository _repository;
  late final StreamSubscription<AuthUser?> _subscription;

  AuthUiState _state = const AuthUiState.initializing();

  AuthUiState get state => _state;

  Future<void> signIn(AuthProvider provider) async {
    if (_state.isSigningIn) {
      return;
    }

    _setState(
      AuthUiState(
        gateStatus: AuthGateStatus.signedOut,
        actionStatus: AuthActionStatus.signingIn,
        activeProvider: provider,
      ),
    );

    final result = await _repository.signIn(provider);
    switch (result) {
      case AuthSignInSuccess():
        if (_state.gateStatus != AuthGateStatus.signedIn) {
          _setState(
            AuthUiState(
              gateStatus: AuthGateStatus.signedOut,
              actionStatus: AuthActionStatus.idle,
              message: '로그인 확인을 기다리고 있어요.',
              messageTone: AuthMessageTone.info,
            ),
          );
        }
      case AuthSignInFailure(:final kind, :final message):
        _setState(
          AuthUiState(
            gateStatus: AuthGateStatus.signedOut,
            actionStatus: AuthActionStatus.idle,
            message: message ?? _messageFor(kind),
            messageTone: kind == AuthFailureKind.cancelled
                ? AuthMessageTone.info
                : AuthMessageTone.error,
          ),
        );
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _onAuthStateChanged(AuthUser? user) {
    if (user == null) {
      _setState(
        const AuthUiState(
          gateStatus: AuthGateStatus.signedOut,
          actionStatus: AuthActionStatus.idle,
        ),
      );
      return;
    }

    _setState(
      AuthUiState(
        gateStatus: AuthGateStatus.signedIn,
        actionStatus: AuthActionStatus.idle,
        user: user,
      ),
    );
  }

  void _onAuthStateError(Object error, StackTrace stackTrace) {
    _setState(
      const AuthUiState(
        gateStatus: AuthGateStatus.signedOut,
        actionStatus: AuthActionStatus.idle,
        message: '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.',
      ),
    );
  }

  String _messageFor(AuthFailureKind kind) {
    return switch (kind) {
      AuthFailureKind.cancelled => '로그인이 취소됐어요. 다시 시도할 수 있어요.',
      AuthFailureKind.network => '인터넷 연결을 확인하고 다시 시도해 주세요.',
      AuthFailureKind.provider => '로그인을 완료하지 못했어요. 다시 시도해 주세요.',
    };
  }

  void _setState(AuthUiState nextState) {
    _state = nextState;
    notifyListeners();
  }
}

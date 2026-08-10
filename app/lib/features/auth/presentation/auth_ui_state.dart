import 'package:review_calendar/features/auth/data/auth_repository.dart';
import 'package:review_calendar/features/auth/domain/auth_user.dart';

enum AuthGateStatus { initializing, signedOut, signedIn }

enum AuthActionStatus { idle, signingIn }

enum AuthMessageTone { info, error }

final class AuthUiState {
  const AuthUiState({
    required this.gateStatus,
    required this.actionStatus,
    this.user,
    this.activeProvider,
    this.message,
    this.messageTone = AuthMessageTone.error,
  });

  const AuthUiState.initializing()
    : this(
        gateStatus: AuthGateStatus.initializing,
        actionStatus: AuthActionStatus.idle,
      );

  final AuthGateStatus gateStatus;
  final AuthActionStatus actionStatus;
  final AuthUser? user;
  final AuthProvider? activeProvider;
  final String? message;
  final AuthMessageTone messageTone;

  bool get isSigningIn => actionStatus == AuthActionStatus.signingIn;
}

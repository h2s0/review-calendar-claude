import 'package:review_calendar/features/auth/data/auth_repository.dart';

/// Ported verbatim from
/// review-calendar/app/lib/features/account/presentation/account_ui_state.dart
enum AccountActionStatus { idle, signingOut, reauthenticating, deleting }

final class AccountUiState {
  const AccountUiState({
    this.status = AccountActionStatus.idle,
    this.activeProvider,
    this.message,
    this.isError = false,
  });

  final AccountActionStatus status;
  final AuthProvider? activeProvider;
  final String? message;
  final bool isError;

  bool get isBusy => status != AccountActionStatus.idle;
}

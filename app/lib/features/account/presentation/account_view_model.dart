import 'package:flutter/foundation.dart';
import 'package:review_calendar/features/account/presentation/account_ui_state.dart';
import 'package:review_calendar/features/auth/data/auth_repository.dart';

/// Ported verbatim from
/// review-calendar/app/lib/features/account/presentation/account_view_model.dart
class AccountViewModel extends ChangeNotifier {
  AccountViewModel(this._repository);

  final AuthRepository _repository;

  AccountUiState _state = const AccountUiState();

  AccountUiState get state => _state;

  Future<bool> signOut() async {
    if (_state.isBusy) {
      return false;
    }
    _setState(const AccountUiState(status: AccountActionStatus.signingOut));
    return _finish(await _repository.signOut());
  }

  Future<bool> reauthenticate(AuthProvider provider) async {
    if (_state.isBusy) {
      return false;
    }
    _setState(
      AccountUiState(
        status: AccountActionStatus.reauthenticating,
        activeProvider: provider,
      ),
    );
    return _finish(await _repository.reauthenticate(provider));
  }

  Future<bool> deleteAccount() async {
    if (_state.isBusy) {
      return false;
    }
    _setState(const AccountUiState(status: AccountActionStatus.deleting));
    return _finish(await _repository.deleteAccount());
  }

  bool _finish(AccountActionResult result) {
    switch (result) {
      case AccountActionSuccess():
        _setState(const AccountUiState());
        return true;
      case AccountActionFailure(:final kind, :final message):
        _setState(
          AccountUiState(
            message: message ?? _messageFor(kind),
            isError: kind != AccountFailureKind.cancelled,
          ),
        );
        return false;
    }
  }

  String _messageFor(AccountFailureKind kind) {
    return switch (kind) {
      AccountFailureKind.cancelled => '본인 확인이 취소됐어요.',
      AccountFailureKind.network => '인터넷 연결을 확인하고 다시 시도해 주세요.',
      AccountFailureKind.recentLoginRequired => '계정 보호를 위해 다시 로그인한 뒤 삭제해 주세요.',
      AccountFailureKind.differentAccount =>
        '현재 계정과 다른 계정으로 로그인했어요. 원래 계정으로 다시 확인해 주세요.',
      AccountFailureKind.retryable =>
        '일부 삭제 작업을 완료하지 못했어요. 다시 시도하면 남은 작업부터 이어집니다.',
      AccountFailureKind.provider => '로그인 공급자와 연결하지 못했어요. 잠시 후 다시 시도해 주세요.',
    };
  }

  void _setState(AccountUiState state) {
    _state = state;
    notifyListeners();
  }
}

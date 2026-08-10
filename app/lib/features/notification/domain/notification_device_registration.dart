import 'dart:async';

/// Ported verbatim from
/// review-calendar/app/lib/features/notification/domain/notification_device_registration.dart
enum NotificationPermissionStatus {
  notDetermined,
  authorized,
  denied,
  permanentlyDenied,
}

abstract interface class NotificationPermissionGateway {
  Future<NotificationPermissionStatus> currentStatus();

  Future<NotificationPermissionStatus> requestPermission();
}

abstract interface class NotificationTokenSource {
  Future<String?> getToken();

  Stream<String> get tokenRefreshes;
}

abstract interface class NotificationTokenRepository {
  Future<void> register({required String userId, required String token});

  Future<void> revoke({required String userId, required String token});
}

final class NotificationDeviceRegistrationController {
  NotificationDeviceRegistrationController({
    required this.userId,
    required this.permissionGateway,
    required this.tokenSource,
    required this.tokenRepository,
  });

  final String userId;
  final NotificationPermissionGateway permissionGateway;
  final NotificationTokenSource tokenSource;
  final NotificationTokenRepository tokenRepository;

  NotificationPermissionStatus _status =
      NotificationPermissionStatus.notDetermined;
  StreamSubscription<String>? _refreshSubscription;
  String? _registeredToken;
  bool _offerHandled = false;
  bool _closed = false;

  NotificationPermissionStatus get status => _status;

  bool get shouldOfferAfterCampaign =>
      !_offerHandled &&
      _status != NotificationPermissionStatus.authorized &&
      !_closed;

  Future<void> initialize() async {
    if (_closed) {
      return;
    }
    _status = await permissionGateway.currentStatus();
    if (_status == NotificationPermissionStatus.authorized) {
      await _synchronizeToken();
    }
  }

  void declineForNow() {
    _offerHandled = true;
    if (_status == NotificationPermissionStatus.notDetermined) {
      _status = NotificationPermissionStatus.denied;
    }
  }

  Future<NotificationPermissionStatus> requestAfterExplanation() async {
    _offerHandled = true;
    if (_closed) {
      return _status;
    }
    _status = await permissionGateway.requestPermission();
    if (_status == NotificationPermissionStatus.authorized) {
      await _synchronizeToken();
    }
    return _status;
  }

  Future<void> _synchronizeToken() async {
    final token = await tokenSource.getToken();
    if (_closed || token == null || token.isEmpty) {
      return;
    }
    await _replaceToken(token);
    _refreshSubscription ??= tokenSource.tokenRefreshes.listen(_replaceToken);
  }

  Future<void> _replaceToken(String token) async {
    if (_closed || token.isEmpty || token == _registeredToken) {
      return;
    }
    final previous = _registeredToken;
    await tokenRepository.register(userId: userId, token: token);
    _registeredToken = token;
    if (previous != null) {
      await tokenRepository.revoke(userId: userId, token: previous);
    }
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _refreshSubscription?.cancel();
    final token = _registeredToken;
    _registeredToken = null;
    if (token != null) {
      await tokenRepository.revoke(userId: userId, token: token);
    }
  }
}

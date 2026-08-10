import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:review_calendar/features/notification/domain/notification_device_registration.dart';

/// Ported verbatim from
/// review-calendar/app/lib/features/notification/data/firebase_notification_device_registration.dart
final class FirebaseNotificationPermissionGateway
    implements NotificationPermissionGateway {
  FirebaseNotificationPermissionGateway(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  Future<NotificationPermissionStatus> currentStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return _mapStatus(settings.authorizationStatus, afterRequest: false);
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return _mapStatus(settings.authorizationStatus, afterRequest: true);
  }

  NotificationPermissionStatus _mapStatus(
    AuthorizationStatus status, {
    required bool afterRequest,
  }) {
    return switch (status) {
      AuthorizationStatus.authorized || AuthorizationStatus.provisional =>
        NotificationPermissionStatus.authorized,
      AuthorizationStatus.denied when afterRequest =>
        NotificationPermissionStatus.permanentlyDenied,
      AuthorizationStatus.denied => NotificationPermissionStatus.denied,
      AuthorizationStatus.notDetermined =>
        NotificationPermissionStatus.notDetermined,
    };
  }
}

final class FirebaseNotificationTokenSource implements NotificationTokenSource {
  FirebaseNotificationTokenSource(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;
}

final class FirestoreNotificationTokenRepository
    implements NotificationTokenRepository {
  FirestoreNotificationTokenRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> register({required String userId, required String token}) async {
    await _tokenDocument(userId, token).set({
      'schemaVersion': 1,
      'token': token,
      'platform': Platform.operatingSystem,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> revoke({required String userId, required String token}) {
    return _tokenDocument(userId, token).delete();
  }

  DocumentReference<Map<String, dynamic>> _tokenDocument(
    String userId,
    String token,
  ) {
    final tokenId = sha256.convert(token.codeUnits).toString();
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notificationTokens')
        .doc(tokenId);
  }
}

import 'dart:async';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../common/app_shared_preferences/app_shared_preferences.dart';
import '../../../common/app_shared_preferences/app_shared_preferences_key.dart';
import '../../../core/storage/storage_manager.dart';
import '../../../main.dart';
import '../../domain/usecases/src/demo_usecase.dart';
import '../models/src/user_model.dart';
import 'fcm_background_handler.dart';
import 'fcm_notification_helper.dart';

class FcmMessagingService {
  FcmMessagingService({required AppSharedPreferences preferences})
      : _preferences = preferences;

  final AppSharedPreferences _preferences;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? _cachedToken;
  StreamSubscription<String>? _tokenRefreshSubscription;

  String? get cachedToken => _cachedToken;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await setupFcmLocalNotifications();

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    log(
      'FCM permission: ${settings.authorizationStatus}',
      name: 'FcmMessagingService',
    );

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    _cachedToken = await getToken();
    if (_cachedToken != null) {
      await _persistToken(_cachedToken!);
      log('FCM token: $_cachedToken', name: 'FcmMessagingService');
    }

    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) async {
      _cachedToken = token;
      await _persistToken(token);
      log('FCM token refreshed: $token', name: 'FcmMessagingService');
      await syncTokenToBackend(token);
    });

    FirebaseMessaging.onMessage.listen((message) async {
      log(
        'FCM foreground: ${message.notification?.title} data=${message.data}',
        name: 'FcmMessagingService',
      );
      await showFcmNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      log(
        'FCM opened app: ${message.messageId} data=${message.data}',
        name: 'FcmMessagingService',
      );
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      log(
        'FCM launched from terminated: ${initialMessage.messageId}',
        name: 'FcmMessagingService',
      );
    }
  }

  /// Returns the current FCM registration token for push notifications.
  Future<String?> getToken() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          log(
            'APNs token not available — skipping FCM getToken. '
            'Token will be picked up via onTokenRefresh when ready.',
            name: 'FcmMessagingService',
          );
          return _cachedToken;
        }
      }

      final token = await _messaging.getToken();
      _cachedToken = token;
      if (token != null) {
        await _persistToken(token);
      }
      return token;
    } catch (e, st) {
      log(
        'FCM getToken failed: $e',
        name: 'FcmMessagingService',
        error: e,
        stackTrace: st,
      );
      return _cachedToken;
    }
  }

  /// Sends [token] to BE when user is already logged in (e.g. token refresh).
  Future<void> syncTokenToBackend(String token) async {
    final email = await StorageManager.getUserEmail();
    if (email == null || email.isEmpty) return;
    if (!getIt.isRegistered<DemoUsecase>()) return;

    try {
      final result = await getIt<DemoUsecase>().getOrCreateNewUser(
        UserModel(gmail: email, tokenDevice: token),
      );
      result.fold(
        (error) => log(
          'FCM token sync failed: $error',
          name: 'FcmMessagingService',
        ),
        (_) => log('FCM token synced to BE', name: 'FcmMessagingService'),
      );
    } catch (e) {
      log('FCM token sync error: $e', name: 'FcmMessagingService');
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
  }

  Future<void> _persistToken(String token) async {
    await _preferences.setString(AppSharedPreferencesKey.fcmToken, token);
  }
}

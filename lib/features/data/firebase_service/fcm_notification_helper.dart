import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android channel id — must match [AndroidManifest] meta-data if set.
const String kFcmNotificationChannelId = 'high_importance_channel';

late AndroidNotificationChannel _androidChannel;
late FlutterLocalNotificationsPlugin _localNotifications;
bool _localNotificationsReady = false;

Future<void> setupFcmLocalNotifications() async {
  if (_localNotificationsReady) return;

  _androidChannel = const AndroidNotificationChannel(
    kFcmNotificationChannelId,
    'Thông báo',
    description: 'Thông báo từ server',
    importance: Importance.high,
  );

  _localNotifications = FlutterLocalNotificationsPlugin();

  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );
  await _localNotifications.initialize(initSettings);

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  _localNotificationsReady = true;
}

/// Parses BE payloads:
/// - FCM `notification` block
/// - `data.title` / `data.body`
/// - `data.data` JSON string: `{"title":"...","body":"..."}`
class FcmNotificationContent {
  const FcmNotificationContent({required this.title, required this.body});

  final String title;
  final String body;
}

FcmNotificationContent? parseFcmNotificationContent(RemoteMessage message) {
  final remote = message.notification;
  if (remote?.title != null && remote!.title!.isNotEmpty) {
    return FcmNotificationContent(
      title: remote.title!,
      body: remote.body ?? '',
    );
  }

  final data = message.data;
  if (data.isEmpty) return null;

  final directTitle = _string(data['title']);
  final directBody = _string(data['body']);
  if (directTitle != null && directTitle.isNotEmpty) {
    return FcmNotificationContent(title: directTitle, body: directBody ?? '');
  }

  final nested = data['data'];
  if (nested != null) {
    try {
      final dynamic decoded =
          nested is String ? jsonDecode(nested) : nested;
      if (decoded is Map) {
        final title = _string(decoded['title']);
        final body = _string(decoded['body']);
        if (title != null && title.isNotEmpty) {
          return FcmNotificationContent(title: title, body: body ?? '');
        }
      }
    } catch (e) {
      log('FCM parse data.data failed: $e', name: 'FcmNotification');
    }
  }

  final messageText = _string(data['message']);
  if (messageText != null && messageText.isNotEmpty) {
    return FcmNotificationContent(
      title: directTitle ?? 'Thông báo',
      body: directBody ?? messageText,
    );
  }

  return null;
}

String? _string(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

/// Shows a heads-up notification. Skips duplicate when Android/iOS already
/// displays a [notification] payload in background.
Future<void> showFcmNotification(RemoteMessage message) async {
  log(
    'FCM raw: notification=${message.notification?.toMap()} data=${message.data}',
    name: 'FcmNotification',
  );

  final content = parseFcmNotificationContent(message);
  if (content == null) {
    log('FCM: no title/body to display', name: 'FcmNotification');
    return;
  }

  if (defaultTargetPlatform == TargetPlatform.iOS &&
      message.notification != null) {
    return;
  }

  if (!_localNotificationsReady) {
    await setupFcmLocalNotifications();
  }

  final id = message.messageId?.hashCode ??
      DateTime.now().millisecondsSinceEpoch.remainder(100000);

  await _localNotifications.show(
    id,
    content.title,
    content.body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
  );

  log(
    'FCM shown: ${content.title} — ${content.body}',
    name: 'FcmNotification',
  );
}

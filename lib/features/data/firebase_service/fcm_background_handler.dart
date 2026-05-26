import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../common/utils/common_utils.dart';
import 'fcm_notification_helper.dart';

/// Top-level handler required for background/terminated FCM messages.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await initFirebase();
  await setupFcmLocalNotifications();
  await showFcmNotification(message);
}

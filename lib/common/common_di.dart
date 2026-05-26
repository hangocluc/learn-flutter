
import 'package:get_it/get_it.dart';

import '../core/interceptor/api_header.dart';
import 'app_shared_preferences/app_shared_preferences.dart';
import 'widget/app_loading_overlay/app_loading_overlay.dart';
import 'package:native_shared_preferences/native_shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widget/app_toast/app_toast.dart';
import '../features/data/firebase_service/fcm_messaging_service.dart';

Future<void> commonDI(GetIt sl) async {
  final prefs = await SharedPreferences.getInstance();
  final nativePrefs = await NativeSharedPreferences.getInstance();
  sl.registerLazySingleton(
      () => AppSharedPreferences(prefs: prefs, nativePrefs: nativePrefs));
  sl.registerLazySingleton(
    () => ApiHeader(preferences: sl.get()),
  );
  sl.registerLazySingleton<AppLoadingOverlay>(() => AppLoadingOverlayImpl());
  sl.registerLazySingleton(() => AppToastWidget());
  sl.registerLazySingleton(
    () => FcmMessagingService(preferences: sl.get()),
  );
}

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import 'common/constants/src/app_constants.dart';
import 'common/generate/assets.gen.dart';
import 'common/utils/common_utils.dart';
import 'common/widget/app_loading_overlay/app_loading_overlay.dart';
import 'core/navigator/navigator_service.dart';
import 'features/app.dart';
import 'features/app/app_env/env.dart';
import 'features/app/app_env/network_env.dart';
import 'features/app/dependencies/dependencies.dart';

final GetIt getIt = GetIt.instance;

const appIcon = Assets.icons;
//Alice? alice;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initFirebase();
  await enableFirebaseAnalytics();
  registerNavigator(getIt);
  await setupEnv();
  await logInitUrls();
  //setupAlice();
  await registerDependencies(getIt);
  configLoading();
  runApp(const MyApp());
}

String envConfig(String flavor) {
  switch (flavor) {
    case AppConstants.STAGING:
      return AppConstants.ENV_STAGING_PATH;
    case AppConstants.PROD:
      return AppConstants.ENV_PROD_PATH;
    default:
      return AppConstants.ENV_DEV_PATH;
  }
}

Future<void> setupEnv() async {
  const flavor = String.fromEnvironment(
    AppConstants.FLAVOR,
    defaultValue: AppConstants.STAGING,
  );
  final envFileName = envConfig(flavor);
  await dotenv.load(fileName: envFileName);
  final env = EnvNetwork.envNetworkFromConfigure();
  final apiServer = env.apiServer.trim();
  if (apiServer.isEmpty) {
    throw StateError(
      'Env load failed: `api_server` is empty. flavor=$flavor, envFile=$envFileName, loadedKeys=${dotenv.env.keys.toList()..sort()}',
    );
  }
  getIt.registerLazySingleton(
    () => Env(
      envNetwork: env,
      isProduction: flavor == AppConstants.PROD,
    ),
  );
  await Future.delayed(const Duration(seconds: 2));
  Logger().d("Env initial $flavor ($envFileName): $apiServer");
}

Future<void> logInitUrls() async {
  final logger = Logger();

  // Your API base URL (from env).
  try {
    final env = getIt<Env>();
    logger.i(
      'Init API baseUrl: ${env.envNetwork.apiServer} (production=${env.isProduction})',
    );
  } catch (_) {
    // Env may not be registered; ignore.
  }

  // Dart VM Service URL (debug/profile).
  if (!kReleaseMode) {
    try {
      final info = await developer.Service.getInfo();
      final serverUri = info.serverUri;
      if (serverUri != null) {
        logger.i('VM Service: $serverUri');
      }
    } catch (_) {
      // Not available on some platforms/modes.
    }
  }
}

GlobalKey<NavigatorState>? getNavigatorKeyByEnv() {
  final isProd = getIt<Env>().isProduction;
  if (isProd) {
    return getIt<NavigationService>().navigatorKey;
  }
  return null;
}

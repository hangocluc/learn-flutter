import 'package:flutter/foundation.dart';

/// Lets pushed routes (e.g. quiz) return to [MainPage] home tab safely.
class MainTabNavigator {
  VoidCallback? onGoHome;

  void goHome() => onGoHome?.call();
}

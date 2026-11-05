import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoUtils {
  // Private constructor
  DeviceInfoUtils._privateConstructor();

  // Singleton instance
  static final DeviceInfoUtils _instance =
      DeviceInfoUtils._privateConstructor();

  // Factory method to return the same instance
  factory DeviceInfoUtils() {
    return _instance;
  }

  // instance getter
  static DeviceInfoUtils get instance => _instance;
  AndroidDeviceInfo? _androidInfo;
  IosDeviceInfo? _iosInfo;

  // Initialization method
  Future<void> initial() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        _androidInfo = await deviceInfoPlugin.androidInfo;
        log('Running on ${_androidInfo?.model}');
      } else if (Platform.isIOS) {
        _iosInfo = await deviceInfoPlugin.iosInfo;
        log('Running on ${_iosInfo?.utsname.machine}');
      }
    } catch (e) {
      log('Failed to get platform version');
    }
  }

  // Add your device info methods and properties here
  String getDeviceName() {
    // Example method to get device name
    if (Platform.isAndroid) {
      return _androidInfo?.model ?? 'Unknown';
    } else if (Platform.isIOS) {
      return _iosInfo?.utsname.machine ?? 'Unknown';
    }
    return 'Unknown';
  }

  String getDeviceUid() {
    if (Platform.isAndroid) {
      return _androidInfo?.fingerprint ?? 'Unknown';
    } else if (Platform.isIOS) {
      return _iosInfo?.identifierForVendor ?? 'Unknown';
    }
    return 'Unknown';
  }

  Future<AndroidDeviceInfo> _androidDeviceInfo() async {
    if (_androidInfo != null) return _androidInfo!;
    _androidInfo = await DeviceInfoPlugin().androidInfo;
    return _androidInfo!;
  }

  /// Android emulator (goldfish / generic / sdk_gphone, …).
  Future<bool> isAndroidEmulator() async {
    if (!Platform.isAndroid) return false;
    final info = await _androidDeviceInfo();
    return !info.isPhysicalDevice;
  }

  /// Flutter Web preview (CanvasKit in WebView) often OOMs on emulator / low-RAM devices.
  Future<bool> isFlutterWebPreviewRisky() async {
    if (!Platform.isAndroid) return false;
    final info = await _androidDeviceInfo();
    return !info.isPhysicalDevice || info.isLowRamDevice;
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class PlatformBridge {
  static const _channel = MethodChannel('com.huapohen.doubaoinput.flutter/system');

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static Future<bool> isImeEnabled() async {
    if (!isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isImeEnabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openImeSettings() async {
    if (!isAndroid) {
      return openAppSettingsPage();
    }
    try {
      return await _channel.invokeMethod<bool>('openImeSettings') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> showImePicker() async {
    if (!isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('showImePicker') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openAppSettingsPage() async {
    try {
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openUrl(String url) async {
    try {
      return await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<void> openKeyboardSystemSettings() async {
    if (isAndroid) {
      await openImeSettings();
    } else {
      await openAppSettingsPage();
    }
  }
}

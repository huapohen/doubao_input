import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Small built-in deep link bridge. It lets the iOS/Android shell open any
/// in-app route (used by automation and by external shortcuts such as
/// `doubaoinput://keyboard?panel=emoji`).
class DeepLinkService {
  static const _channel = MethodChannel('com.huapohen.doubaoinput.flutter/deeplink');
  static final navigatorKey = GlobalKey<NavigatorState>();
  static String? _pending;
  static bool _attached = false;

  static void init() {
    if (_attached) return;
    _attached = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'open' && call.arguments is String) {
        handle(call.arguments as String);
      }
      return null;
    });
    _channel.invokeMethod<String>('getInitialUrl').then((url) {
      if (url != null && url.isNotEmpty) handle(url);
    }).catchError((_) {});
  }

  static void handle(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    final host = uri.host.isNotEmpty ? uri.host : uri.path.replaceAll('/', '');
    final route = '/$host';
    final args = <String, dynamic>{
      ...uri.queryParameters,
      if (uri.queryParameters['panel'] != null) 'panel': uri.queryParameters['panel'],
      if (uri.queryParameters['mode'] != null) 'mode': uri.queryParameters['mode'],
      if (uri.queryParameters['composing'] != null) 'composing': uri.queryParameters['composing'],
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = navigatorKey.currentState;
      if (nav == null) {
        _pending = raw;
        Future.delayed(const Duration(milliseconds: 400), () {
          if (_pending == raw) {
            _pending = null;
            handle(raw);
          }
        });
      } else {
        nav.pushNamed(route, arguments: args);
      }
    });
  }
}

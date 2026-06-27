import 'package:flutter/services.dart';

/// Communication channel between Flutter and native Android for home screen shortcuts.
class ShortcutChannel {
  static const MethodChannel _channel = MethodChannel('com.webnest/shortcut');

  static Function(String)? _onLaunchListener;

  /// Register a listener that gets invoked when the user opens a website app shortcut
  /// while the main app is running (onNewIntent).
  static void setLaunchListener(Function(String) listener) {
    _onLaunchListener = listener;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onLaunchApp') {
        final appId = call.arguments as String?;
        if (appId != null && _onLaunchListener != null) {
          _onLaunchListener!(appId);
        }
      }
    });
  }

  /// Request the native system to pin a shortcut for a WebApp.
  /// Returns a status code string: "SUCCESS", "NOT_SUPPORTED", "FAILED", or "ERROR_..."
  static Future<String> pinShortcut({
    required String appId,
    required String appName,
    required String themeColor,
    required String faviconUrl,
  }) async {
    try {
      final String? status = await _channel.invokeMethod<String>('pinShortcut', {
        'appId': appId,
        'appName': appName,
        'themeColor': themeColor,
        'faviconUrl': faviconUrl,
      });
      return status ?? 'FAILED';
    } catch (e) {
      return 'ERROR_${e.toString()}';
    }
  }

  /// Queries the native side for any app ID that was used to start this session.
  /// (e.g. from the launch intent when the process starts).
  static Future<String?> getInitialAppId() async {
    try {
      return await _channel.invokeMethod<String?>('getInitialAppId');
    } catch (e) {
      return null;
    }
  }
}


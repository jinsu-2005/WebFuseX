import 'package:flutter/services.dart';

/// Flutter-side channel for the native Shield (ad blocker) engine.
///
/// Provides methods to load filter list files into the native
/// [WebNestShieldEngine] and query its status.
class ShieldChannel {
  static const MethodChannel _channel = MethodChannel('com.webnest/shield');

  ShieldChannel._();

  /// Loads a single filter list file from [filePath] into the native engine.
  /// The native side parses the Adblock Plusâ€“format text and updates its rule set.
  static Future<bool> loadFilterList(String filePath) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'loadFilterList',
        {'filePath': filePath},
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Loads multiple filter list files in sequence.
  static Future<void> loadFilterLists(List<String> filePaths) async {
    await clearRules();
    for (final path in filePaths) {
      await loadFilterList(path);
    }
  }

  /// Clears all loaded rules from the native engine.
  static Future<void> clearRules() async {
    try {
      await _channel.invokeMethod<void>('clearRules');
    } catch (_) {}
  }

  /// Returns the number of rules currently loaded in the native engine.
  static Future<int> getRuleCount() async {
    try {
      final result = await _channel.invokeMethod<int>('getRuleCount');
      return result ?? 0;
    } catch (_) {
      return 0;
    }
  }
}


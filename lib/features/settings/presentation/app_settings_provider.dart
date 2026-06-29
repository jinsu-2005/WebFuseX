import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/app_settings.dart';
import '../../website_app/presentation/web_app_provider.dart';

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;
  static const _key = 'webnest_app_settings';

  AppSettingsNotifier(this._prefs) : super(const AppSettings()) {
    _load();
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        state = AppSettings.fromJson(json);
      } catch (_) {
        state = const AppSettings();
      }
    }
  }

  Future<void> _save() async {
    await _prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> setTwoFingerReloadEnabled(bool value) async {
    state = state.copyWith(twoFingerReloadEnabled: value);
    await _save();
  }

  Future<void> setJavascriptEnabled(bool value) async {
    state = state.copyWith(javascriptEnabled: value);
    await _save();
  }

  Future<void> setCookiesEnabled(bool value) async {
    state = state.copyWith(cookiesEnabled: value);
    await _save();
  }

  Future<void> setThirdPartyCookiesEnabled(bool value) async {
    state = state.copyWith(thirdPartyCookiesEnabled: value);
    await _save();
  }

  Future<void> setPopupBlockingEnabled(bool value) async {
    state = state.copyWith(popupBlockingEnabled: value);
    await _save();
  }

  Future<void> setTrackerBlockingEnabled(bool value) async {
    state = state.copyWith(trackerBlockingEnabled: value);
    await _save();
  }

  Future<void> setForceDarkMode(bool value) async {
    state = state.copyWith(forceDarkModeForWebsites: value);
    await _save();
  }

  Future<void> setDefaultMode(AppDefaultMode value) async {
    state = state.copyWith(defaultMode: value);
    await _save();
  }

  Future<void> setHardwareAcceleration(bool value) async {
    state = state.copyWith(hardwareAccelerationEnabled: value);
    await _save();
  }

  Future<void> setBackgroundPlayback(bool value) async {
    state = state.copyWith(backgroundPlaybackEnabled: value);
    await _save();
  }

  Future<void> setAdBlockerEnabled(bool value) async {
    state = state.copyWith(adBlockerEnabled: value);
    await _save();
  }

  Future<void> markFilterListsUpdated() async {
    state = state.copyWith(filterListsLastUpdated: DateTime.now());
    await _save();
  }

  Future<void> setDnsMode(DnsMode value) async {
    state = state.copyWith(dnsMode: value);
    await _save();
  }

  Future<void> setUserAgentMode(UserAgentMode value) async {
    state = state.copyWith(userAgentMode: value);
    await _save();
  }

  Future<void> setCustomUserAgent(String value) async {
    state = state.copyWith(customUserAgent: value);
    await _save();
  }

  Future<void> setDownloadLocation(String value) async {
    state = state.copyWith(downloadLocation: value);
    await _save();
  }

  Future<void> setRestorePreviousSession(bool value) async {
    state = state.copyWith(restorePreviousSession: value);
    await _save();
  }

  Future<void> setAutoRefreshEnabled(bool value) async {
    state = state.copyWith(autoRefreshEnabled: value);
    await _save();
  }

  Future<void> setAutoRefreshInterval(int value) async {
    state = state.copyWith(autoRefreshInterval: value);
    await _save();
  }

  Future<void> setPinchToZoomEnabled(bool value) async {
    state = state.copyWith(pinchToZoomEnabled: value);
    await _save();
  }

  Future<void> setOpenLinksExternally(bool value) async {
    state = state.copyWith(openLinksExternally: value);
    await _save();
  }

  Future<void> setLoadImagesEnabled(bool value) async {
    state = state.copyWith(loadImagesEnabled: value);
    await _save();
  }

  Future<void> toggleFilterList(String id, bool enabled) async {
    final list = List<String>.from(state.enabledFilterLists);
    if (enabled) {
      if (!list.contains(id)) list.add(id);
    } else {
      list.remove(id);
    }
    state = state.copyWith(enabledFilterLists: list);
    await _save();
  }

  Future<void> updateSettings(AppSettings settings) async {
    state = settings;
    await _save();
  }
}

// â”€â”€â”€ Provider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return AppSettingsNotifier(prefs);
    });

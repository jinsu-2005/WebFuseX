import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../website_app/presentation/web_app_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_settings_provider.dart';

enum PermissionState { prompt, granted, denied }

class AppPermissions {
  final Map<String, PermissionState> defaultPermissions;
  final Map<String, Map<String, PermissionState>> sitePermissions;

  AppPermissions({
    required this.defaultPermissions,
    required this.sitePermissions,
  });

  AppPermissions copyWith({
    Map<String, PermissionState>? defaultPermissions,
    Map<String, Map<String, PermissionState>>? sitePermissions,
  }) {
    return AppPermissions(
      defaultPermissions: defaultPermissions ?? this.defaultPermissions,
      sitePermissions: sitePermissions ?? this.sitePermissions,
    );
  }

  factory AppPermissions.initial() {
    return AppPermissions(
      defaultPermissions: {
        'Camera': PermissionState.denied,
        'Microphone': PermissionState.denied,
        'Location': PermissionState.denied,
        'Notifications': PermissionState.denied,
        'Storage': PermissionState.granted,
      },
      sitePermissions: {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultPermissions': defaultPermissions.map((k, v) => MapEntry(k, v.name)),
      'sitePermissions': sitePermissions.map((k, v) => MapEntry(k, v.map((k2, v2) => MapEntry(k2, v2.name)))),
    };
  }

  factory AppPermissions.fromJson(Map<String, dynamic> json) {
    final dp = (json['defaultPermissions'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, PermissionState.values.firstWhere((e) => e.name == v, orElse: () => PermissionState.prompt)),
        ) ??
        AppPermissions.initial().defaultPermissions;

    final sp = (json['sitePermissions'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(
            k,
            (v as Map<String, dynamic>).map(
              (k2, v2) => MapEntry(k2, PermissionState.values.firstWhere((e) => e.name == v2, orElse: () => PermissionState.prompt)),
            ),
          ),
        ) ??
        {};

    return AppPermissions(defaultPermissions: dp, sitePermissions: sp);
  }
}

class PermissionsNotifier extends StateNotifier<AppPermissions> {
  final SharedPreferences _prefs;
  static const _key = 'webfusex_permissions';

  PermissionsNotifier(this._prefs) : super(AppPermissions.initial()) {
    _load();
  }

  void _load() {
    final str = _prefs.getString(_key);
    if (str != null) {
      try {
        state = AppPermissions.fromJson(jsonDecode(str));
      } catch (e) {
        state = AppPermissions.initial();
      }
    }
  }

  void _save(AppPermissions newState) {
    state = newState;
    _prefs.setString(_key, jsonEncode(newState.toJson()));
  }

  void setDefaultPermission(String resource, PermissionState s) {
    final dp = Map<String, PermissionState>.from(state.defaultPermissions);
    dp[resource] = s;
    _save(state.copyWith(defaultPermissions: dp));
  }

  void setSitePermission(String origin, String resource, PermissionState s) {
    final sp = Map<String, Map<String, PermissionState>>.from(state.sitePermissions);
    final siteMap = Map<String, PermissionState>.from(sp[origin] ?? {});
    siteMap[resource] = s;
    sp[origin] = siteMap;
    _save(state.copyWith(sitePermissions: sp));
  }

  void removeSitePermission(String origin, String resource) {
    final sp = Map<String, Map<String, PermissionState>>.from(state.sitePermissions);
    final siteMap = Map<String, PermissionState>.from(sp[origin] ?? {});
    siteMap.remove(resource);
    if (siteMap.isEmpty) {
      sp.remove(origin);
    } else {
      sp[origin] = siteMap;
    }
    _save(state.copyWith(sitePermissions: sp));
  }

  PermissionState getPermission(String origin, String resource) {
    final siteMap = state.sitePermissions[origin];
    if (siteMap != null && siteMap.containsKey(resource)) {
      return siteMap[resource]!;
    }
    return state.defaultPermissions[resource] ?? PermissionState.prompt;
  }
}

final permissionsProvider = StateNotifierProvider<PermissionsNotifier, AppPermissions>((ref) {
  return PermissionsNotifier(ref.watch(sharedPreferencesProvider));
});

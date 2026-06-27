/// Global application settings — stored independently from per-app WebApp data.
///
/// These are app-wide defaults and preferences, not per-website configuration.
class AppSettings {
  // ── Gesture ──────────────────────────────────────────────────────────────────
  final bool twoFingerReloadEnabled;

  // ── Privacy & Security ────────────────────────────────────────────────────────
  final bool javascriptEnabled;
  final bool cookiesEnabled;
  final bool thirdPartyCookiesEnabled;
  final bool popupBlockingEnabled;
  final bool trackerBlockingEnabled;

  // ── Appearance ────────────────────────────────────────────────────────────────
  final bool forceDarkModeForWebsites;
  final AppDefaultMode defaultMode;

  // ── Performance ───────────────────────────────────────────────────────────────
  final bool hardwareAccelerationEnabled;
  final bool backgroundPlaybackEnabled;

  // ── Ad Blocking ────────────────────────────────────────────────────────────────
  final bool adBlockerEnabled;
  final DateTime? filterListsLastUpdated;

  // ── Network ───────────────────────────────────────────────────────────────────
  final DnsMode dnsMode;
  final String customDnsServer;
  final UserAgentMode userAgentMode;
  final String customUserAgent;

  // ── Storage ───────────────────────────────────────────────────────────────────
  final String downloadLocation; // empty = system default

  // ── Session ───────────────────────────────────────────────────────────────────
  final bool restorePreviousSession;

  // ── Additional Advanced Overrides ──
  final List<String> enabledFilterLists;
  final List<String> disabledFilterLists;
  final bool autoRefreshEnabled;
  final int autoRefreshInterval; // in seconds
  final bool pinchToZoomEnabled;
  final bool openLinksExternally;
  final bool loadImagesEnabled;

  // ── Notch / Dropdown UI ──
  final bool hideNotch;
  final double notchTransparency;
  final String notchColorHex;
  final String notchAppearance;

  // ── Custom Filter Lists ──
  final List<Map<String, dynamic>> customFilterLists;

  const AppSettings({
    this.twoFingerReloadEnabled = false,
    this.javascriptEnabled = true,
    this.cookiesEnabled = true,
    this.thirdPartyCookiesEnabled = true,
    this.popupBlockingEnabled = true,
    this.trackerBlockingEnabled = true,
    this.forceDarkModeForWebsites = false,
    this.defaultMode = AppDefaultMode.mobile,
    this.hardwareAccelerationEnabled = true,
    this.backgroundPlaybackEnabled = false,
    this.adBlockerEnabled = true,
    this.filterListsLastUpdated,
    this.dnsMode = DnsMode.system,
    this.customDnsServer = '',
    this.userAgentMode = UserAgentMode.defaultAgent,
    this.customUserAgent = '',
    this.downloadLocation = '',
    this.restorePreviousSession = false,
    this.enabledFilterLists = const ['easylist', 'easyprivacy', 'ublock_base'],
    this.disabledFilterLists = const [],
    this.autoRefreshEnabled = false,
    this.autoRefreshInterval = 30,
    this.pinchToZoomEnabled = true,
    this.openLinksExternally = false,
    this.loadImagesEnabled = true,
    this.hideNotch = false,
    this.notchTransparency = 0.5,
    this.notchColorHex = 'FFFFFF',
    this.notchAppearance = 'pill',
    this.customFilterLists = const [],
  });

  AppSettings copyWith({
    bool? twoFingerReloadEnabled,
    bool? javascriptEnabled,
    bool? cookiesEnabled,
    bool? thirdPartyCookiesEnabled,
    bool? popupBlockingEnabled,
    bool? trackerBlockingEnabled,
    bool? forceDarkModeForWebsites,
    AppDefaultMode? defaultMode,
    bool? hardwareAccelerationEnabled,
    bool? backgroundPlaybackEnabled,
    bool? adBlockerEnabled,
    DateTime? filterListsLastUpdated,
    DnsMode? dnsMode,
    String? customDnsServer,
    UserAgentMode? userAgentMode,
    String? customUserAgent,
    String? downloadLocation,
    bool? restorePreviousSession,
    List<String>? enabledFilterLists,
    List<String>? disabledFilterLists,
    bool? autoRefreshEnabled,
    int? autoRefreshInterval,
    bool? pinchToZoomEnabled,
    bool? openLinksExternally,
    bool? loadImagesEnabled,
    bool? hideNotch,
    double? notchTransparency,
    String? notchColorHex,
    String? notchAppearance,
    List<Map<String, dynamic>>? customFilterLists,
  }) {
    return AppSettings(
      twoFingerReloadEnabled:
          twoFingerReloadEnabled ?? this.twoFingerReloadEnabled,
      javascriptEnabled: javascriptEnabled ?? this.javascriptEnabled,
      cookiesEnabled: cookiesEnabled ?? this.cookiesEnabled,
      thirdPartyCookiesEnabled:
          thirdPartyCookiesEnabled ?? this.thirdPartyCookiesEnabled,
      popupBlockingEnabled: popupBlockingEnabled ?? this.popupBlockingEnabled,
      trackerBlockingEnabled:
          trackerBlockingEnabled ?? this.trackerBlockingEnabled,
      forceDarkModeForWebsites:
          forceDarkModeForWebsites ?? this.forceDarkModeForWebsites,
      defaultMode: defaultMode ?? this.defaultMode,
      hardwareAccelerationEnabled:
          hardwareAccelerationEnabled ?? this.hardwareAccelerationEnabled,
      backgroundPlaybackEnabled:
          backgroundPlaybackEnabled ?? this.backgroundPlaybackEnabled,
      adBlockerEnabled: adBlockerEnabled ?? this.adBlockerEnabled,
      filterListsLastUpdated:
          filterListsLastUpdated ?? this.filterListsLastUpdated,
      dnsMode: dnsMode ?? this.dnsMode,
      customDnsServer: customDnsServer ?? this.customDnsServer,
      userAgentMode: userAgentMode ?? this.userAgentMode,
      customUserAgent: customUserAgent ?? this.customUserAgent,
      downloadLocation: downloadLocation ?? this.downloadLocation,
      restorePreviousSession:
          restorePreviousSession ?? this.restorePreviousSession,
      enabledFilterLists: enabledFilterLists ?? this.enabledFilterLists,
      disabledFilterLists: disabledFilterLists ?? this.disabledFilterLists,
      autoRefreshEnabled: autoRefreshEnabled ?? this.autoRefreshEnabled,
      autoRefreshInterval: autoRefreshInterval ?? this.autoRefreshInterval,
      pinchToZoomEnabled: pinchToZoomEnabled ?? this.pinchToZoomEnabled,
      openLinksExternally: openLinksExternally ?? this.openLinksExternally,
      loadImagesEnabled: loadImagesEnabled ?? this.loadImagesEnabled,
      hideNotch: hideNotch ?? this.hideNotch,
      notchTransparency: notchTransparency ?? this.notchTransparency,
      notchColorHex: notchColorHex ?? this.notchColorHex,
      notchAppearance: notchAppearance ?? this.notchAppearance,
      customFilterLists: customFilterLists ?? this.customFilterLists,
    );
  }

  /// Serialize to a flat Map for SharedPreferences storage.
  Map<String, dynamic> toJson() => {
        'twoFingerReloadEnabled': twoFingerReloadEnabled,
        'javascriptEnabled': javascriptEnabled,
        'cookiesEnabled': cookiesEnabled,
        'thirdPartyCookiesEnabled': thirdPartyCookiesEnabled,
        'popupBlockingEnabled': popupBlockingEnabled,
        'trackerBlockingEnabled': trackerBlockingEnabled,
        'forceDarkModeForWebsites': forceDarkModeForWebsites,
        'defaultMode': defaultMode.name,
        'hardwareAccelerationEnabled': hardwareAccelerationEnabled,
        'backgroundPlaybackEnabled': backgroundPlaybackEnabled,
        'adBlockerEnabled': adBlockerEnabled,
        'filterListsLastUpdated': filterListsLastUpdated?.toIso8601String(),
        'dnsMode': dnsMode.name,
        'customDnsServer': customDnsServer,
        'userAgentMode': userAgentMode.name,
        'customUserAgent': customUserAgent,
        'downloadLocation': downloadLocation,
        'restorePreviousSession': restorePreviousSession,
        'enabledFilterLists': enabledFilterLists,
        'disabledFilterLists': disabledFilterLists,
        'autoRefreshEnabled': autoRefreshEnabled,
        'autoRefreshInterval': autoRefreshInterval,
        'pinchToZoomEnabled': pinchToZoomEnabled,
        'openLinksExternally': openLinksExternally,
        'loadImagesEnabled': loadImagesEnabled,
        'hideNotch': hideNotch,
        'notchTransparency': notchTransparency,
        'notchColorHex': notchColorHex,
        'notchAppearance': notchAppearance,
        'customFilterLists': customFilterLists,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        twoFingerReloadEnabled:
            json['twoFingerReloadEnabled'] as bool? ?? false,
        javascriptEnabled: json['javascriptEnabled'] as bool? ?? true,
        cookiesEnabled: json['cookiesEnabled'] as bool? ?? true,
        thirdPartyCookiesEnabled:
            json['thirdPartyCookiesEnabled'] as bool? ?? true,
        popupBlockingEnabled: json['popupBlockingEnabled'] as bool? ?? true,
        trackerBlockingEnabled:
            json['trackerBlockingEnabled'] as bool? ?? true,
        forceDarkModeForWebsites:
            json['forceDarkModeForWebsites'] as bool? ?? false,
        defaultMode: AppDefaultMode.values.firstWhere(
          (e) => e.name == json['defaultMode'],
          orElse: () => AppDefaultMode.mobile,
        ),
        hardwareAccelerationEnabled:
            json['hardwareAccelerationEnabled'] as bool? ?? true,
        backgroundPlaybackEnabled:
            json['backgroundPlaybackEnabled'] as bool? ?? false,
        adBlockerEnabled: json['adBlockerEnabled'] as bool? ?? true,
        filterListsLastUpdated: json['filterListsLastUpdated'] != null
            ? DateTime.tryParse(json['filterListsLastUpdated'] as String)
            : null,
        dnsMode: DnsMode.values.firstWhere(
          (e) => e.name == json['dnsMode'],
          orElse: () => DnsMode.system,
        ),
        customDnsServer: json['customDnsServer'] as String? ?? '',
        userAgentMode: UserAgentMode.values.firstWhere(
          (e) => e.name == json['userAgentMode'],
          orElse: () => UserAgentMode.defaultAgent,
        ),
        customUserAgent: json['customUserAgent'] as String? ?? '',
        downloadLocation: json['downloadLocation'] as String? ?? '',
        restorePreviousSession:
            json['restorePreviousSession'] as bool? ?? false,
        enabledFilterLists: (json['enabledFilterLists'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const ['easylist', 'easyprivacy', 'ublock_base'],
        disabledFilterLists: (json['disabledFilterLists'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        autoRefreshEnabled: json['autoRefreshEnabled'] as bool? ?? false,
        autoRefreshInterval: json['autoRefreshInterval'] as int? ?? 30,
        pinchToZoomEnabled: json['pinchToZoomEnabled'] as bool? ?? true,
        openLinksExternally: json['openLinksExternally'] as bool? ?? false,
        loadImagesEnabled: json['loadImagesEnabled'] as bool? ?? true,
        hideNotch: json['hideNotch'] as bool? ?? false,
        notchTransparency: (json['notchTransparency'] as num?)?.toDouble() ?? 0.5,
        notchColorHex: json['notchColorHex'] as String? ?? 'FFFFFF',
        notchAppearance: json['notchAppearance'] as String? ?? 'pill',
        customFilterLists: (json['customFilterLists'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            const [],
      );
}

enum AppDefaultMode { mobile, desktop }

enum DnsMode { system, custom }

enum UserAgentMode { defaultAgent, desktop, custom }

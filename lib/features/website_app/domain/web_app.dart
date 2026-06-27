import 'package:freezed_annotation/freezed_annotation.dart';

part 'web_app.freezed.dart';
part 'web_app.g.dart';

/// A WebApp represents a single website that has been installed as an
/// independent application inside WebFuseX.
///
/// A WebApp is NOT a person profile â€” it IS a website.
/// Each WebApp has its own isolated cookies, storage, cache,
/// permissions, history, and native Android identity.
@freezed
class WebApp with _$WebApp {
  const factory WebApp({
    /// Unique ID â€” used as the WebKit profile key for storage isolation.
    required String id,

    /// The homepage URL that this WebApp always opens to.
    /// e.g. "https://hianime.to"
    required String url,

    /// User-facing display name. e.g. "HiAnime"
    required String name,

    /// URL of the fetched favicon image.
    @Default('') String faviconUrl,

    /// Theme color extracted from <meta name="theme-color"> or Web App Manifest.
    /// Drives the splash screen, status bar color, and app card accent.
    @Default('#6366F1') String themeColorHex,

    /// Whether the WebFuseX Shield (ad + tracker blocker) is active for this app.
    @Default(true) bool shieldEnabled,

    /// Whether this website is opened in Desktop mode (overrides User-Agent).
    @Default(false) bool desktopMode,

    /// Custom User-Agent string. Empty string = use default.
    @Default('') String customUserAgent,

    /// Whether this is an Incognito instance â€” storage is wiped on close.
    @Default(false) bool isIncognito,

    /// Whether the user has pinned this app to the Android home screen.
    @Default(false) bool shortcutInstalled,

    /// Whether the user has marked this app as a Favorite.
    @Default(false) bool isFavorite,

    /// Last time this app was launched. Used for "Recently Used" section.
    DateTime? lastUsed,

    /// Sub-profiles for the same website (e.g. YouTube Personal + YouTube Work).
    /// The parent WebApp acts as the primary identity.
    @Default([]) List<WebApp> subProfiles,

    // â”€â”€ Customization (Feature 2) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Custom display name set by the user. Overrides [name] in the UI when set.
    /// Empty string = use [name].
    @Default('') String customDisplayName,

    /// Custom short name shown on app cards. Overrides [name] when set.
    /// Empty string = use effective display name.
    @Default('') String customShortName,

    /// Absolute path to a user-selected custom icon image file.
    /// Empty string = use [faviconUrl].
    @Default('') String customIconPath,

    // â”€â”€ Organisation (Feature 4) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// ID of the folder this app belongs to. Empty = no folder.
    @Default('') String folderId,

    /// Predefined or custom category label.
    /// e.g. "Anime", "Music", "Social", or a user-defined string.
    @Default('') String category,

    /// Sort order within its section (folder or root). Lower = higher up.
    @Default(0) int sortOrder,

    // ── Local Settings Overrides ──
    bool? jsEnabledOverride,
    bool? cookiesEnabledOverride,
    bool? thirdPartyCookiesEnabledOverride,
    bool? desktopModeOverride,
    bool? shieldEnabledOverride,
    bool? autoRefreshEnabledOverride,
    int? autoRefreshIntervalOverride,
    bool? pinchToZoomEnabledOverride,
    bool? openLinksExternallyOverride,
    bool? loadImagesEnabledOverride,
  }) = _WebApp;

  factory WebApp.fromJson(Map<String, dynamic> json) => _$WebAppFromJson(json);
}

/// Temporary struct returned by the metadata fetcher during the Add Website flow.
/// This is NOT persisted â€” it is used to pre-fill the WebApp creation form.
class WebsiteMetadata {
  final String resolvedUrl;
  final String title;
  final String faviconUrl;
  final String themeColorHex;
  final String manifestName;

  const WebsiteMetadata({
    required this.resolvedUrl,
    required this.title,
    required this.faviconUrl,
    required this.themeColorHex,
    required this.manifestName,
  });

  static const empty = WebsiteMetadata(
    resolvedUrl: '',
    title: '',
    faviconUrl: '',
    themeColorHex: '',
    manifestName: '',
  );
}


// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'web_app.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

WebApp _$WebAppFromJson(Map<String, dynamic> json) {
  return _WebApp.fromJson(json);
}

/// @nodoc
mixin _$WebApp {
  /// Unique ID â€” used as the WebKit profile key for storage isolation.
  String get id => throw _privateConstructorUsedError;

  /// The homepage URL that this WebApp always opens to.
  /// e.g. "https://hianime.to"
  String get url => throw _privateConstructorUsedError;

  /// User-facing display name. e.g. "HiAnime"
  String get name => throw _privateConstructorUsedError;

  /// URL of the fetched favicon image.
  String get faviconUrl => throw _privateConstructorUsedError;

  /// Theme color extracted from <meta name="theme-color"> or Web App Manifest.
  /// Drives the splash screen, status bar color, and app card accent.
  String get themeColorHex => throw _privateConstructorUsedError;

  /// Whether the WebFuseX Shield (ad + tracker blocker) is active for this app.
  bool get shieldEnabled => throw _privateConstructorUsedError;

  /// Whether this website is opened in Desktop mode (overrides User-Agent).
  bool get desktopMode => throw _privateConstructorUsedError;

  /// Custom User-Agent string. Empty string = use default.
  String get customUserAgent => throw _privateConstructorUsedError;

  /// Whether this is an Incognito instance â€” storage is wiped on close.
  bool get isIncognito => throw _privateConstructorUsedError;

  /// Whether the user has pinned this app to the Android home screen.
  bool get shortcutInstalled => throw _privateConstructorUsedError;

  /// Whether the user has marked this app as a Favorite.
  bool get isFavorite => throw _privateConstructorUsedError;

  /// Last time this app was launched. Used for "Recently Used" section.
  DateTime? get lastUsed => throw _privateConstructorUsedError;

  /// Sub-profiles for the same website (e.g. YouTube Personal + YouTube Work).
  /// The parent WebApp acts as the primary identity.
  List<WebApp> get subProfiles =>
      throw _privateConstructorUsedError; // â”€â”€ Customization (Feature 2) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Custom display name set by the user. Overrides [name] in the UI when set.
  /// Empty string = use [name].
  String get customDisplayName => throw _privateConstructorUsedError;

  /// Custom short name shown on app cards. Overrides [name] when set.
  /// Empty string = use effective display name.
  String get customShortName => throw _privateConstructorUsedError;

  /// Absolute path to a user-selected custom icon image file.
  /// Empty string = use [faviconUrl].
  String get customIconPath =>
      throw _privateConstructorUsedError; // â”€â”€ Organisation (Feature 4) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// ID of the folder this app belongs to. Empty = no folder.
  String get folderId => throw _privateConstructorUsedError;

  /// Predefined or custom category label.
  /// e.g. "Anime", "Music", "Social", or a user-defined string.
  String get category => throw _privateConstructorUsedError;

  /// Sort order within its section (folder or root). Lower = higher up.
  int get sortOrder =>
      throw _privateConstructorUsedError; // ── Local Settings Overrides ──
  bool? get jsEnabledOverride => throw _privateConstructorUsedError;
  bool? get cookiesEnabledOverride => throw _privateConstructorUsedError;
  bool? get thirdPartyCookiesEnabledOverride =>
      throw _privateConstructorUsedError;
  bool? get desktopModeOverride => throw _privateConstructorUsedError;
  bool? get shieldEnabledOverride => throw _privateConstructorUsedError;
  bool? get autoRefreshEnabledOverride => throw _privateConstructorUsedError;
  int? get autoRefreshIntervalOverride => throw _privateConstructorUsedError;
  bool? get pinchToZoomEnabledOverride => throw _privateConstructorUsedError;
  bool? get openLinksExternallyOverride => throw _privateConstructorUsedError;
  bool? get loadImagesEnabledOverride => throw _privateConstructorUsedError;

  /// Serializes this WebApp to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WebApp
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WebAppCopyWith<WebApp> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WebAppCopyWith<$Res> {
  factory $WebAppCopyWith(WebApp value, $Res Function(WebApp) then) =
      _$WebAppCopyWithImpl<$Res, WebApp>;
  @useResult
  $Res call({
    String id,
    String url,
    String name,
    String faviconUrl,
    String themeColorHex,
    bool shieldEnabled,
    bool desktopMode,
    String customUserAgent,
    bool isIncognito,
    bool shortcutInstalled,
    bool isFavorite,
    DateTime? lastUsed,
    List<WebApp> subProfiles,
    String customDisplayName,
    String customShortName,
    String customIconPath,
    String folderId,
    String category,
    int sortOrder,
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
  });
}

/// @nodoc
class _$WebAppCopyWithImpl<$Res, $Val extends WebApp>
    implements $WebAppCopyWith<$Res> {
  _$WebAppCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WebApp
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? name = null,
    Object? faviconUrl = null,
    Object? themeColorHex = null,
    Object? shieldEnabled = null,
    Object? desktopMode = null,
    Object? customUserAgent = null,
    Object? isIncognito = null,
    Object? shortcutInstalled = null,
    Object? isFavorite = null,
    Object? lastUsed = freezed,
    Object? subProfiles = null,
    Object? customDisplayName = null,
    Object? customShortName = null,
    Object? customIconPath = null,
    Object? folderId = null,
    Object? category = null,
    Object? sortOrder = null,
    Object? jsEnabledOverride = freezed,
    Object? cookiesEnabledOverride = freezed,
    Object? thirdPartyCookiesEnabledOverride = freezed,
    Object? desktopModeOverride = freezed,
    Object? shieldEnabledOverride = freezed,
    Object? autoRefreshEnabledOverride = freezed,
    Object? autoRefreshIntervalOverride = freezed,
    Object? pinchToZoomEnabledOverride = freezed,
    Object? openLinksExternallyOverride = freezed,
    Object? loadImagesEnabledOverride = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            faviconUrl: null == faviconUrl
                ? _value.faviconUrl
                : faviconUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            themeColorHex: null == themeColorHex
                ? _value.themeColorHex
                : themeColorHex // ignore: cast_nullable_to_non_nullable
                      as String,
            shieldEnabled: null == shieldEnabled
                ? _value.shieldEnabled
                : shieldEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            desktopMode: null == desktopMode
                ? _value.desktopMode
                : desktopMode // ignore: cast_nullable_to_non_nullable
                      as bool,
            customUserAgent: null == customUserAgent
                ? _value.customUserAgent
                : customUserAgent // ignore: cast_nullable_to_non_nullable
                      as String,
            isIncognito: null == isIncognito
                ? _value.isIncognito
                : isIncognito // ignore: cast_nullable_to_non_nullable
                      as bool,
            shortcutInstalled: null == shortcutInstalled
                ? _value.shortcutInstalled
                : shortcutInstalled // ignore: cast_nullable_to_non_nullable
                      as bool,
            isFavorite: null == isFavorite
                ? _value.isFavorite
                : isFavorite // ignore: cast_nullable_to_non_nullable
                      as bool,
            lastUsed: freezed == lastUsed
                ? _value.lastUsed
                : lastUsed // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            subProfiles: null == subProfiles
                ? _value.subProfiles
                : subProfiles // ignore: cast_nullable_to_non_nullable
                      as List<WebApp>,
            customDisplayName: null == customDisplayName
                ? _value.customDisplayName
                : customDisplayName // ignore: cast_nullable_to_non_nullable
                      as String,
            customShortName: null == customShortName
                ? _value.customShortName
                : customShortName // ignore: cast_nullable_to_non_nullable
                      as String,
            customIconPath: null == customIconPath
                ? _value.customIconPath
                : customIconPath // ignore: cast_nullable_to_non_nullable
                      as String,
            folderId: null == folderId
                ? _value.folderId
                : folderId // ignore: cast_nullable_to_non_nullable
                      as String,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
            jsEnabledOverride: freezed == jsEnabledOverride
                ? _value.jsEnabledOverride
                : jsEnabledOverride // ignore: cast_nullable_to_non_nullable
                      as bool?,
            cookiesEnabledOverride: freezed == cookiesEnabledOverride
                ? _value.cookiesEnabledOverride
                : cookiesEnabledOverride // ignore: cast_nullable_to_non_nullable
                      as bool?,
            thirdPartyCookiesEnabledOverride:
                freezed == thirdPartyCookiesEnabledOverride
                ? _value.thirdPartyCookiesEnabledOverride
                : thirdPartyCookiesEnabledOverride // ignore: cast_nullable_to_non_nullable
                      as bool?,
            desktopModeOverride: freezed == desktopModeOverride
                ? _value.desktopModeOverride
                : desktopModeOverride // ignore: cast_nullable_to_non_nullable
                      as bool?,
            shieldEnabledOverride: freezed == shieldEnabledOverride
                ? _value.shieldEnabledOverride
                : shieldEnabledOverride // ignore: cast_nullable_to_non_nullable
                      as bool?,
            autoRefreshEnabledOverride: freezed == autoRefreshEnabledOverride
                ? _value.autoRefreshEnabledOverride
                : autoRefreshEnabledOverride // ignore: cast_nullable_to_non_nullable
                      as bool?,
            autoRefreshIntervalOverride: freezed == autoRefreshIntervalOverride
                ? _value.autoRefreshIntervalOverride
                : autoRefreshIntervalOverride // ignore: cast_nullable_to_non_nullable
                      as int?,
            pinchToZoomEnabledOverride: freezed == pinchToZoomEnabledOverride
                ? _value.pinchToZoomEnabledOverride
                : pinchToZoomEnabledOverride // ignore: cast_nullable_to_non_nullable
                      as bool?,
            openLinksExternallyOverride: freezed == openLinksExternallyOverride
                ? _value.openLinksExternallyOverride
                : openLinksExternallyOverride // ignore: cast_nullable_to_non_nullable
                      as bool?,
            loadImagesEnabledOverride: freezed == loadImagesEnabledOverride
                ? _value.loadImagesEnabledOverride
                : loadImagesEnabledOverride // ignore: cast_nullable_to_non_nullable
                      as bool?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WebAppImplCopyWith<$Res> implements $WebAppCopyWith<$Res> {
  factory _$$WebAppImplCopyWith(
    _$WebAppImpl value,
    $Res Function(_$WebAppImpl) then,
  ) = __$$WebAppImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String url,
    String name,
    String faviconUrl,
    String themeColorHex,
    bool shieldEnabled,
    bool desktopMode,
    String customUserAgent,
    bool isIncognito,
    bool shortcutInstalled,
    bool isFavorite,
    DateTime? lastUsed,
    List<WebApp> subProfiles,
    String customDisplayName,
    String customShortName,
    String customIconPath,
    String folderId,
    String category,
    int sortOrder,
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
  });
}

/// @nodoc
class __$$WebAppImplCopyWithImpl<$Res>
    extends _$WebAppCopyWithImpl<$Res, _$WebAppImpl>
    implements _$$WebAppImplCopyWith<$Res> {
  __$$WebAppImplCopyWithImpl(
    _$WebAppImpl _value,
    $Res Function(_$WebAppImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WebApp
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? name = null,
    Object? faviconUrl = null,
    Object? themeColorHex = null,
    Object? shieldEnabled = null,
    Object? desktopMode = null,
    Object? customUserAgent = null,
    Object? isIncognito = null,
    Object? shortcutInstalled = null,
    Object? isFavorite = null,
    Object? lastUsed = freezed,
    Object? subProfiles = null,
    Object? customDisplayName = null,
    Object? customShortName = null,
    Object? customIconPath = null,
    Object? folderId = null,
    Object? category = null,
    Object? sortOrder = null,
    Object? jsEnabledOverride = freezed,
    Object? cookiesEnabledOverride = freezed,
    Object? thirdPartyCookiesEnabledOverride = freezed,
    Object? desktopModeOverride = freezed,
    Object? shieldEnabledOverride = freezed,
    Object? autoRefreshEnabledOverride = freezed,
    Object? autoRefreshIntervalOverride = freezed,
    Object? pinchToZoomEnabledOverride = freezed,
    Object? openLinksExternallyOverride = freezed,
    Object? loadImagesEnabledOverride = freezed,
  }) {
    return _then(
      _$WebAppImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        faviconUrl: null == faviconUrl
            ? _value.faviconUrl
            : faviconUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        themeColorHex: null == themeColorHex
            ? _value.themeColorHex
            : themeColorHex // ignore: cast_nullable_to_non_nullable
                  as String,
        shieldEnabled: null == shieldEnabled
            ? _value.shieldEnabled
            : shieldEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        desktopMode: null == desktopMode
            ? _value.desktopMode
            : desktopMode // ignore: cast_nullable_to_non_nullable
                  as bool,
        customUserAgent: null == customUserAgent
            ? _value.customUserAgent
            : customUserAgent // ignore: cast_nullable_to_non_nullable
                  as String,
        isIncognito: null == isIncognito
            ? _value.isIncognito
            : isIncognito // ignore: cast_nullable_to_non_nullable
                  as bool,
        shortcutInstalled: null == shortcutInstalled
            ? _value.shortcutInstalled
            : shortcutInstalled // ignore: cast_nullable_to_non_nullable
                  as bool,
        isFavorite: null == isFavorite
            ? _value.isFavorite
            : isFavorite // ignore: cast_nullable_to_non_nullable
                  as bool,
        lastUsed: freezed == lastUsed
            ? _value.lastUsed
            : lastUsed // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        subProfiles: null == subProfiles
            ? _value._subProfiles
            : subProfiles // ignore: cast_nullable_to_non_nullable
                  as List<WebApp>,
        customDisplayName: null == customDisplayName
            ? _value.customDisplayName
            : customDisplayName // ignore: cast_nullable_to_non_nullable
                  as String,
        customShortName: null == customShortName
            ? _value.customShortName
            : customShortName // ignore: cast_nullable_to_non_nullable
                  as String,
        customIconPath: null == customIconPath
            ? _value.customIconPath
            : customIconPath // ignore: cast_nullable_to_non_nullable
                  as String,
        folderId: null == folderId
            ? _value.folderId
            : folderId // ignore: cast_nullable_to_non_nullable
                  as String,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
        jsEnabledOverride: freezed == jsEnabledOverride
            ? _value.jsEnabledOverride
            : jsEnabledOverride // ignore: cast_nullable_to_non_nullable
                  as bool?,
        cookiesEnabledOverride: freezed == cookiesEnabledOverride
            ? _value.cookiesEnabledOverride
            : cookiesEnabledOverride // ignore: cast_nullable_to_non_nullable
                  as bool?,
        thirdPartyCookiesEnabledOverride:
            freezed == thirdPartyCookiesEnabledOverride
            ? _value.thirdPartyCookiesEnabledOverride
            : thirdPartyCookiesEnabledOverride // ignore: cast_nullable_to_non_nullable
                  as bool?,
        desktopModeOverride: freezed == desktopModeOverride
            ? _value.desktopModeOverride
            : desktopModeOverride // ignore: cast_nullable_to_non_nullable
                  as bool?,
        shieldEnabledOverride: freezed == shieldEnabledOverride
            ? _value.shieldEnabledOverride
            : shieldEnabledOverride // ignore: cast_nullable_to_non_nullable
                  as bool?,
        autoRefreshEnabledOverride: freezed == autoRefreshEnabledOverride
            ? _value.autoRefreshEnabledOverride
            : autoRefreshEnabledOverride // ignore: cast_nullable_to_non_nullable
                  as bool?,
        autoRefreshIntervalOverride: freezed == autoRefreshIntervalOverride
            ? _value.autoRefreshIntervalOverride
            : autoRefreshIntervalOverride // ignore: cast_nullable_to_non_nullable
                  as int?,
        pinchToZoomEnabledOverride: freezed == pinchToZoomEnabledOverride
            ? _value.pinchToZoomEnabledOverride
            : pinchToZoomEnabledOverride // ignore: cast_nullable_to_non_nullable
                  as bool?,
        openLinksExternallyOverride: freezed == openLinksExternallyOverride
            ? _value.openLinksExternallyOverride
            : openLinksExternallyOverride // ignore: cast_nullable_to_non_nullable
                  as bool?,
        loadImagesEnabledOverride: freezed == loadImagesEnabledOverride
            ? _value.loadImagesEnabledOverride
            : loadImagesEnabledOverride // ignore: cast_nullable_to_non_nullable
                  as bool?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WebAppImpl implements _WebApp {
  const _$WebAppImpl({
    required this.id,
    required this.url,
    required this.name,
    this.faviconUrl = '',
    this.themeColorHex = '#6366F1',
    this.shieldEnabled = true,
    this.desktopMode = false,
    this.customUserAgent = '',
    this.isIncognito = false,
    this.shortcutInstalled = false,
    this.isFavorite = false,
    this.lastUsed,
    final List<WebApp> subProfiles = const [],
    this.customDisplayName = '',
    this.customShortName = '',
    this.customIconPath = '',
    this.folderId = '',
    this.category = '',
    this.sortOrder = 0,
    this.jsEnabledOverride,
    this.cookiesEnabledOverride,
    this.thirdPartyCookiesEnabledOverride,
    this.desktopModeOverride,
    this.shieldEnabledOverride,
    this.autoRefreshEnabledOverride,
    this.autoRefreshIntervalOverride,
    this.pinchToZoomEnabledOverride,
    this.openLinksExternallyOverride,
    this.loadImagesEnabledOverride,
  }) : _subProfiles = subProfiles;

  factory _$WebAppImpl.fromJson(Map<String, dynamic> json) =>
      _$$WebAppImplFromJson(json);

  /// Unique ID â€” used as the WebKit profile key for storage isolation.
  @override
  final String id;

  /// The homepage URL that this WebApp always opens to.
  /// e.g. "https://hianime.to"
  @override
  final String url;

  /// User-facing display name. e.g. "HiAnime"
  @override
  final String name;

  /// URL of the fetched favicon image.
  @override
  @JsonKey()
  final String faviconUrl;

  /// Theme color extracted from <meta name="theme-color"> or Web App Manifest.
  /// Drives the splash screen, status bar color, and app card accent.
  @override
  @JsonKey()
  final String themeColorHex;

  /// Whether the WebFuseX Shield (ad + tracker blocker) is active for this app.
  @override
  @JsonKey()
  final bool shieldEnabled;

  /// Whether this website is opened in Desktop mode (overrides User-Agent).
  @override
  @JsonKey()
  final bool desktopMode;

  /// Custom User-Agent string. Empty string = use default.
  @override
  @JsonKey()
  final String customUserAgent;

  /// Whether this is an Incognito instance â€” storage is wiped on close.
  @override
  @JsonKey()
  final bool isIncognito;

  /// Whether the user has pinned this app to the Android home screen.
  @override
  @JsonKey()
  final bool shortcutInstalled;

  /// Whether the user has marked this app as a Favorite.
  @override
  @JsonKey()
  final bool isFavorite;

  /// Last time this app was launched. Used for "Recently Used" section.
  @override
  final DateTime? lastUsed;

  /// Sub-profiles for the same website (e.g. YouTube Personal + YouTube Work).
  /// The parent WebApp acts as the primary identity.
  final List<WebApp> _subProfiles;

  /// Sub-profiles for the same website (e.g. YouTube Personal + YouTube Work).
  /// The parent WebApp acts as the primary identity.
  @override
  @JsonKey()
  List<WebApp> get subProfiles {
    if (_subProfiles is EqualUnmodifiableListView) return _subProfiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_subProfiles);
  }

  // â”€â”€ Customization (Feature 2) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Custom display name set by the user. Overrides [name] in the UI when set.
  /// Empty string = use [name].
  @override
  @JsonKey()
  final String customDisplayName;

  /// Custom short name shown on app cards. Overrides [name] when set.
  /// Empty string = use effective display name.
  @override
  @JsonKey()
  final String customShortName;

  /// Absolute path to a user-selected custom icon image file.
  /// Empty string = use [faviconUrl].
  @override
  @JsonKey()
  final String customIconPath;
  // â”€â”€ Organisation (Feature 4) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// ID of the folder this app belongs to. Empty = no folder.
  @override
  @JsonKey()
  final String folderId;

  /// Predefined or custom category label.
  /// e.g. "Anime", "Music", "Social", or a user-defined string.
  @override
  @JsonKey()
  final String category;

  /// Sort order within its section (folder or root). Lower = higher up.
  @override
  @JsonKey()
  final int sortOrder;
  // ── Local Settings Overrides ──
  @override
  final bool? jsEnabledOverride;
  @override
  final bool? cookiesEnabledOverride;
  @override
  final bool? thirdPartyCookiesEnabledOverride;
  @override
  final bool? desktopModeOverride;
  @override
  final bool? shieldEnabledOverride;
  @override
  final bool? autoRefreshEnabledOverride;
  @override
  final int? autoRefreshIntervalOverride;
  @override
  final bool? pinchToZoomEnabledOverride;
  @override
  final bool? openLinksExternallyOverride;
  @override
  final bool? loadImagesEnabledOverride;

  @override
  String toString() {
    return 'WebApp(id: $id, url: $url, name: $name, faviconUrl: $faviconUrl, themeColorHex: $themeColorHex, shieldEnabled: $shieldEnabled, desktopMode: $desktopMode, customUserAgent: $customUserAgent, isIncognito: $isIncognito, shortcutInstalled: $shortcutInstalled, isFavorite: $isFavorite, lastUsed: $lastUsed, subProfiles: $subProfiles, customDisplayName: $customDisplayName, customShortName: $customShortName, customIconPath: $customIconPath, folderId: $folderId, category: $category, sortOrder: $sortOrder, jsEnabledOverride: $jsEnabledOverride, cookiesEnabledOverride: $cookiesEnabledOverride, thirdPartyCookiesEnabledOverride: $thirdPartyCookiesEnabledOverride, desktopModeOverride: $desktopModeOverride, shieldEnabledOverride: $shieldEnabledOverride, autoRefreshEnabledOverride: $autoRefreshEnabledOverride, autoRefreshIntervalOverride: $autoRefreshIntervalOverride, pinchToZoomEnabledOverride: $pinchToZoomEnabledOverride, openLinksExternallyOverride: $openLinksExternallyOverride, loadImagesEnabledOverride: $loadImagesEnabledOverride)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WebAppImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.faviconUrl, faviconUrl) ||
                other.faviconUrl == faviconUrl) &&
            (identical(other.themeColorHex, themeColorHex) ||
                other.themeColorHex == themeColorHex) &&
            (identical(other.shieldEnabled, shieldEnabled) ||
                other.shieldEnabled == shieldEnabled) &&
            (identical(other.desktopMode, desktopMode) ||
                other.desktopMode == desktopMode) &&
            (identical(other.customUserAgent, customUserAgent) ||
                other.customUserAgent == customUserAgent) &&
            (identical(other.isIncognito, isIncognito) ||
                other.isIncognito == isIncognito) &&
            (identical(other.shortcutInstalled, shortcutInstalled) ||
                other.shortcutInstalled == shortcutInstalled) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.lastUsed, lastUsed) ||
                other.lastUsed == lastUsed) &&
            const DeepCollectionEquality().equals(
              other._subProfiles,
              _subProfiles,
            ) &&
            (identical(other.customDisplayName, customDisplayName) ||
                other.customDisplayName == customDisplayName) &&
            (identical(other.customShortName, customShortName) ||
                other.customShortName == customShortName) &&
            (identical(other.customIconPath, customIconPath) ||
                other.customIconPath == customIconPath) &&
            (identical(other.folderId, folderId) ||
                other.folderId == folderId) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.jsEnabledOverride, jsEnabledOverride) ||
                other.jsEnabledOverride == jsEnabledOverride) &&
            (identical(other.cookiesEnabledOverride, cookiesEnabledOverride) ||
                other.cookiesEnabledOverride == cookiesEnabledOverride) &&
            (identical(
                  other.thirdPartyCookiesEnabledOverride,
                  thirdPartyCookiesEnabledOverride,
                ) ||
                other.thirdPartyCookiesEnabledOverride ==
                    thirdPartyCookiesEnabledOverride) &&
            (identical(other.desktopModeOverride, desktopModeOverride) ||
                other.desktopModeOverride == desktopModeOverride) &&
            (identical(other.shieldEnabledOverride, shieldEnabledOverride) ||
                other.shieldEnabledOverride == shieldEnabledOverride) &&
            (identical(
                  other.autoRefreshEnabledOverride,
                  autoRefreshEnabledOverride,
                ) ||
                other.autoRefreshEnabledOverride ==
                    autoRefreshEnabledOverride) &&
            (identical(
                  other.autoRefreshIntervalOverride,
                  autoRefreshIntervalOverride,
                ) ||
                other.autoRefreshIntervalOverride ==
                    autoRefreshIntervalOverride) &&
            (identical(
                  other.pinchToZoomEnabledOverride,
                  pinchToZoomEnabledOverride,
                ) ||
                other.pinchToZoomEnabledOverride ==
                    pinchToZoomEnabledOverride) &&
            (identical(
                  other.openLinksExternallyOverride,
                  openLinksExternallyOverride,
                ) ||
                other.openLinksExternallyOverride ==
                    openLinksExternallyOverride) &&
            (identical(
                  other.loadImagesEnabledOverride,
                  loadImagesEnabledOverride,
                ) ||
                other.loadImagesEnabledOverride == loadImagesEnabledOverride));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    url,
    name,
    faviconUrl,
    themeColorHex,
    shieldEnabled,
    desktopMode,
    customUserAgent,
    isIncognito,
    shortcutInstalled,
    isFavorite,
    lastUsed,
    const DeepCollectionEquality().hash(_subProfiles),
    customDisplayName,
    customShortName,
    customIconPath,
    folderId,
    category,
    sortOrder,
    jsEnabledOverride,
    cookiesEnabledOverride,
    thirdPartyCookiesEnabledOverride,
    desktopModeOverride,
    shieldEnabledOverride,
    autoRefreshEnabledOverride,
    autoRefreshIntervalOverride,
    pinchToZoomEnabledOverride,
    openLinksExternallyOverride,
    loadImagesEnabledOverride,
  ]);

  /// Create a copy of WebApp
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WebAppImplCopyWith<_$WebAppImpl> get copyWith =>
      __$$WebAppImplCopyWithImpl<_$WebAppImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WebAppImplToJson(this);
  }
}

abstract class _WebApp implements WebApp {
  const factory _WebApp({
    required final String id,
    required final String url,
    required final String name,
    final String faviconUrl,
    final String themeColorHex,
    final bool shieldEnabled,
    final bool desktopMode,
    final String customUserAgent,
    final bool isIncognito,
    final bool shortcutInstalled,
    final bool isFavorite,
    final DateTime? lastUsed,
    final List<WebApp> subProfiles,
    final String customDisplayName,
    final String customShortName,
    final String customIconPath,
    final String folderId,
    final String category,
    final int sortOrder,
    final bool? jsEnabledOverride,
    final bool? cookiesEnabledOverride,
    final bool? thirdPartyCookiesEnabledOverride,
    final bool? desktopModeOverride,
    final bool? shieldEnabledOverride,
    final bool? autoRefreshEnabledOverride,
    final int? autoRefreshIntervalOverride,
    final bool? pinchToZoomEnabledOverride,
    final bool? openLinksExternallyOverride,
    final bool? loadImagesEnabledOverride,
  }) = _$WebAppImpl;

  factory _WebApp.fromJson(Map<String, dynamic> json) = _$WebAppImpl.fromJson;

  /// Unique ID â€” used as the WebKit profile key for storage isolation.
  @override
  String get id;

  /// The homepage URL that this WebApp always opens to.
  /// e.g. "https://hianime.to"
  @override
  String get url;

  /// User-facing display name. e.g. "HiAnime"
  @override
  String get name;

  /// URL of the fetched favicon image.
  @override
  String get faviconUrl;

  /// Theme color extracted from <meta name="theme-color"> or Web App Manifest.
  /// Drives the splash screen, status bar color, and app card accent.
  @override
  String get themeColorHex;

  /// Whether the WebFuseX Shield (ad + tracker blocker) is active for this app.
  @override
  bool get shieldEnabled;

  /// Whether this website is opened in Desktop mode (overrides User-Agent).
  @override
  bool get desktopMode;

  /// Custom User-Agent string. Empty string = use default.
  @override
  String get customUserAgent;

  /// Whether this is an Incognito instance â€” storage is wiped on close.
  @override
  bool get isIncognito;

  /// Whether the user has pinned this app to the Android home screen.
  @override
  bool get shortcutInstalled;

  /// Whether the user has marked this app as a Favorite.
  @override
  bool get isFavorite;

  /// Last time this app was launched. Used for "Recently Used" section.
  @override
  DateTime? get lastUsed;

  /// Sub-profiles for the same website (e.g. YouTube Personal + YouTube Work).
  /// The parent WebApp acts as the primary identity.
  @override
  List<WebApp> get subProfiles; // â”€â”€ Customization (Feature 2) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Custom display name set by the user. Overrides [name] in the UI when set.
  /// Empty string = use [name].
  @override
  String get customDisplayName;

  /// Custom short name shown on app cards. Overrides [name] when set.
  /// Empty string = use effective display name.
  @override
  String get customShortName;

  /// Absolute path to a user-selected custom icon image file.
  /// Empty string = use [faviconUrl].
  @override
  String get customIconPath; // â”€â”€ Organisation (Feature 4) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// ID of the folder this app belongs to. Empty = no folder.
  @override
  String get folderId;

  /// Predefined or custom category label.
  /// e.g. "Anime", "Music", "Social", or a user-defined string.
  @override
  String get category;

  /// Sort order within its section (folder or root). Lower = higher up.
  @override
  int get sortOrder; // ── Local Settings Overrides ──
  @override
  bool? get jsEnabledOverride;
  @override
  bool? get cookiesEnabledOverride;
  @override
  bool? get thirdPartyCookiesEnabledOverride;
  @override
  bool? get desktopModeOverride;
  @override
  bool? get shieldEnabledOverride;
  @override
  bool? get autoRefreshEnabledOverride;
  @override
  int? get autoRefreshIntervalOverride;
  @override
  bool? get pinchToZoomEnabledOverride;
  @override
  bool? get openLinksExternallyOverride;
  @override
  bool? get loadImagesEnabledOverride;

  /// Create a copy of WebApp
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WebAppImplCopyWith<_$WebAppImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_app.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WebAppImpl _$$WebAppImplFromJson(Map<String, dynamic> json) => _$WebAppImpl(
  id: json['id'] as String,
  url: json['url'] as String,
  name: json['name'] as String,
  faviconUrl: json['faviconUrl'] as String? ?? '',
  themeColorHex: json['themeColorHex'] as String? ?? '#6366F1',
  shieldEnabled: json['shieldEnabled'] as bool? ?? true,
  desktopMode: json['desktopMode'] as bool? ?? false,
  customUserAgent: json['customUserAgent'] as String? ?? '',
  isIncognito: json['isIncognito'] as bool? ?? false,
  shortcutInstalled: json['shortcutInstalled'] as bool? ?? false,
  isFavorite: json['isFavorite'] as bool? ?? false,
  lastUsed: json['lastUsed'] == null
      ? null
      : DateTime.parse(json['lastUsed'] as String),
  subProfiles:
      (json['subProfiles'] as List<dynamic>?)
          ?.map((e) => WebApp.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  customDisplayName: json['customDisplayName'] as String? ?? '',
  customShortName: json['customShortName'] as String? ?? '',
  customIconPath: json['customIconPath'] as String? ?? '',
  folderId: json['folderId'] as String? ?? '',
  category: json['category'] as String? ?? '',
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  jsEnabledOverride: json['jsEnabledOverride'] as bool?,
  cookiesEnabledOverride: json['cookiesEnabledOverride'] as bool?,
  thirdPartyCookiesEnabledOverride:
      json['thirdPartyCookiesEnabledOverride'] as bool?,
  desktopModeOverride: json['desktopModeOverride'] as bool?,
  shieldEnabledOverride: json['shieldEnabledOverride'] as bool?,
  autoRefreshEnabledOverride: json['autoRefreshEnabledOverride'] as bool?,
  autoRefreshIntervalOverride: (json['autoRefreshIntervalOverride'] as num?)
      ?.toInt(),
  pinchToZoomEnabledOverride: json['pinchToZoomEnabledOverride'] as bool?,
  openLinksExternallyOverride: json['openLinksExternallyOverride'] as bool?,
  loadImagesEnabledOverride: json['loadImagesEnabledOverride'] as bool?,
);

Map<String, dynamic> _$$WebAppImplToJson(
  _$WebAppImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'url': instance.url,
  'name': instance.name,
  'faviconUrl': instance.faviconUrl,
  'themeColorHex': instance.themeColorHex,
  'shieldEnabled': instance.shieldEnabled,
  'desktopMode': instance.desktopMode,
  'customUserAgent': instance.customUserAgent,
  'isIncognito': instance.isIncognito,
  'shortcutInstalled': instance.shortcutInstalled,
  'isFavorite': instance.isFavorite,
  'lastUsed': instance.lastUsed?.toIso8601String(),
  'subProfiles': instance.subProfiles,
  'customDisplayName': instance.customDisplayName,
  'customShortName': instance.customShortName,
  'customIconPath': instance.customIconPath,
  'folderId': instance.folderId,
  'category': instance.category,
  'sortOrder': instance.sortOrder,
  'jsEnabledOverride': instance.jsEnabledOverride,
  'cookiesEnabledOverride': instance.cookiesEnabledOverride,
  'thirdPartyCookiesEnabledOverride': instance.thirdPartyCookiesEnabledOverride,
  'desktopModeOverride': instance.desktopModeOverride,
  'shieldEnabledOverride': instance.shieldEnabledOverride,
  'autoRefreshEnabledOverride': instance.autoRefreshEnabledOverride,
  'autoRefreshIntervalOverride': instance.autoRefreshIntervalOverride,
  'pinchToZoomEnabledOverride': instance.pinchToZoomEnabledOverride,
  'openLinksExternallyOverride': instance.openLinksExternallyOverride,
  'loadImagesEnabledOverride': instance.loadImagesEnabledOverride,
};

/// URLs for uBlock Origin-compatible filter lists.
///
/// These lists are fetched at runtime â€” they are NOT bundled in the APK.
/// All lists are downloaded from their canonical CDN/raw locations.
///
/// LICENSE NOTICE:
/// - EasyList and EasyPrivacy are (c) EasyList authors, licensed under CC BY-SA 3.0.
/// - uBlock Origin Filter Lists are (c) uBlockOrigin contributors, licensed under GPL v3.
/// These lists are not redistributed with the app â€” they are fetched on demand.
class FilterListUrls {
  FilterListUrls._();

  static const String easyList = 'https://ublockorigin.pages.dev/thirdparties/easylist.txt';
  static const String easyPrivacy = 'https://ublockorigin.pages.dev/thirdparties/easyprivacy.txt';
  static const String uBlockBase = 'https://ublockorigin.pages.dev/filters/filters.min.txt';
  static const String uBlockPrivacy = 'https://ublockorigin.pages.dev/filters/privacy.min.txt';
  static const String uBlockBadware = 'https://ublockorigin.github.io/uAssetsCDN/filters/badware.min.txt';
  static const String uBlockQuickFixes = 'https://cdn.jsdelivr.net/gh/uBlockOrigin/uAssetsCDN@main/filters/quick-fixes.min.txt';
  static const String uBlockUnbreak = 'https://cdn.jsdelivr.net/gh/uBlockOrigin/uAssetsCDN@main/filters/unbreak.min.txt';
  static const String urlhaus = 'https://malware-filter.gitlab.io/urlhaus-filter/urlhaus-filter-ag-online.txt';
  static const String peterlowelist = 'https://pgl.yoyo.org/adservers/serverlist.php?hostformat=adblockplus&showintro=0&mimetype=plaintext';
  static const String adguardBase = 'https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_2_Base/filter.txt';
  static const String adguardMobileAds = 'https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_11_Mobile/filter.txt';

  /// All lists that are enabled by default
  static const List<FilterList> defaults = [
    FilterList(
      id: 'easylist',
      name: 'EasyList',
      url: easyList,
      description: 'Primary ad-blocking filter list',
      license: 'CC BY-SA 3.0',
      enabled: true,
    ),
    FilterList(
      id: 'easyprivacy',
      name: 'EasyPrivacy',
      url: easyPrivacy,
      description: 'Tracker and privacy protection',
      license: 'CC BY-SA 3.0',
      enabled: true,
    ),
    FilterList(
      id: 'adguard_base',
      name: 'AdGuard Base',
      url: adguardBase,
      description: 'AdGuard primary ad-blocking filters',
      license: 'GPL v3',
      enabled: true,
    ),
    FilterList(
      id: 'adguard_mobile',
      name: 'AdGuard Mobile Ads',
      url: adguardMobileAds,
      description: 'Filters specific to mobile ad networks',
      license: 'GPL v3',
      enabled: true,
    ),
    FilterList(
      id: 'ublock_base',
      name: 'uBlock Base Filters',
      url: uBlockBase,
      description: 'Curated lightweight filters by uBlock Origin',
      license: 'GPL v3',
      enabled: true,
    ),
    FilterList(
      id: 'ublock_privacy',
      name: 'uBlock Privacy',
      url: uBlockPrivacy,
      description: 'Additional privacy-focused filters',
      license: 'GPL v3',
      enabled: true,
    ),
    FilterList(
      id: 'ublock_badware',
      name: 'uBlock Badware',
      url: uBlockBadware,
      description: 'Blocks malicious websites',
      license: 'GPL v3',
      enabled: true,
    ),
    FilterList(
      id: 'ublock_quickfixes',
      name: 'uBlock Quick Fixes',
      url: uBlockQuickFixes,
      description: 'Rapid hotfixes for broken sites',
      license: 'GPL v3',
      enabled: true,
    ),
    FilterList(
      id: 'ublock_unbreak',
      name: 'uBlock Unbreak',
      url: uBlockUnbreak,
      description: 'Fixes for site breakages',
      license: 'GPL v3',
      enabled: true,
    ),
    FilterList(
      id: 'urlhaus',
      name: 'URLhaus Malware',
      url: urlhaus,
      description: 'Malicious URL blocklist',
      license: 'CC0',
      enabled: true,
    ),
    FilterList(
      id: 'peterlow',
      name: "Peter Lowe's List",
      url: peterlowelist,
      description: 'Public domain ad server list',
      license: 'Public Domain',
      enabled: true,
    ),
  ];
}

class FilterList {
  final String id;
  final String name;
  final String url;
  final String description;
  final String license;
  final bool enabled;

  const FilterList({
    required this.id,
    required this.name,
    required this.url,
    required this.description,
    required this.license,
    required this.enabled,
  });

  FilterList copyWith({bool? enabled}) => FilterList(
        id: id,
        name: name,
        url: url,
        description: description,
        license: license,
        enabled: enabled ?? this.enabled,
      );
}


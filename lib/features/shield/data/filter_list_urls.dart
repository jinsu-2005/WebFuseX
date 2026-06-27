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

  /// EasyList â€” primary ad-blocking filter list
  static const String easyList =
      'https://easylist.to/easylist/easylist.txt';

  /// EasyPrivacy â€” tracker blocking companion to EasyList
  static const String easyPrivacy =
      'https://easylist.to/easylist/easyprivacy.txt';

  /// uBlock Origin Base Filters â€” curated lightweight list
  static const String uBlockBase =
      'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt';

  /// uBlock Origin Privacy Filters
  static const String uBlockPrivacy =
      'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/privacy.txt';

  /// uBlock Origin Badware Filters
  static const String uBlockBadware =
      'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/badware.txt';

  /// Peter Lowe's Ad and tracking server list (public domain â€” safest for bundling)
  static const String peterlowelist =
      'https://pgl.yoyo.org/adservers/serverlist.php?hostformat=adblockplus&showintro=0&mimetype=plaintext';

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
      enabled: false,
    ),
    FilterList(
      id: 'peterlow',
      name: "Peter Lowe's List",
      url: peterlowelist,
      description: 'Public domain ad server list',
      license: 'Public Domain',
      enabled: false,
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


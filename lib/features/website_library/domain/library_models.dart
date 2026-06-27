
class LibraryCategoryConfig {
  final String id;
  final String title;
  final int sortOrder;

  const LibraryCategoryConfig({
    required this.id,
    required this.title,
    required this.sortOrder,
  });
}

class LibraryAppConfig {
  final String id;
  final String primaryUrl;
  final List<String> mirrors;
  final String? nameOverride;
  final String? faviconOverride;
  final String categoryId;
  final List<String> badges;
  final int priority;
  final bool isFeatured;

  const LibraryAppConfig({
    required this.id,
    required this.primaryUrl,
    this.mirrors = const [],
    this.nameOverride,
    this.faviconOverride,
    required this.categoryId,
    this.badges = const [],
    this.priority = 0,
    this.isFeatured = false,
  });
}

class LibraryAppMetadata {
  final String resolvedUrl;
  final String title;
  final String faviconUrl;
  final String themeColorHex;

  const LibraryAppMetadata({
    required this.resolvedUrl,
    required this.title,
    required this.faviconUrl,
    required this.themeColorHex,
  });

  Map<String, dynamic> toJson() => {
        'resolvedUrl': resolvedUrl,
        'title': title,
        'faviconUrl': faviconUrl,
        'themeColorHex': themeColorHex,
      };

  factory LibraryAppMetadata.fromJson(Map<String, dynamic> json) =>
      LibraryAppMetadata(
        resolvedUrl: json['resolvedUrl'] as String? ?? '',
        title: json['title'] as String? ?? '',
        faviconUrl: json['faviconUrl'] as String? ?? '',
        themeColorHex: json['themeColorHex'] as String? ?? '',
      );
}

class LibraryAppRuntime {
  final LibraryAppConfig config;
  final LibraryAppMetadata metadata;

  const LibraryAppRuntime({
    required this.config,
    required this.metadata,
  });
}

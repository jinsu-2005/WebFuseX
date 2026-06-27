import 'dart:convert';

/// Represents a dynamic category that groups WebApps in the library screen.
class WebAppCategory {
  final String id;
  final String name;
  final String emoji;
  final int sortOrder;

  const WebAppCategory({
    required this.id,
    required this.name,
    required this.emoji,
    this.sortOrder = 0,
  });

  WebAppCategory copyWith({
    String? id,
    String? name,
    String? emoji,
    int? sortOrder,
  }) {
    return WebAppCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'sortOrder': sortOrder,
      };

  factory WebAppCategory.fromJson(Map<String, dynamic> json) => WebAppCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String? ?? '📁',
        sortOrder: json['sortOrder'] as int? ?? 0,
      );

  static List<WebAppCategory> listFromJson(String raw) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => WebAppCategory.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<WebAppCategory> categories) {
    return jsonEncode(categories.map((c) => c.toJson()).toList());
  }

        static final List<WebAppCategory> defaults = [
    const WebAppCategory(id: 'anime', name: 'Featured Anime', emoji: 'dYZO', sortOrder: 0),
    const WebAppCategory(id: 'indian_anime', name: 'Indian Anime & Cartoons', emoji: 'dYrdY3', sortOrder: 1),
    const WebAppCategory(id: 'multi_content', name: 'Multi-Content', emoji: 'dYO?', sortOrder: 2),
    const WebAppCategory(id: 'english_movies', name: 'English Movies & TV Shows', emoji: 'dYZ', sortOrder: 3),
    const WebAppCategory(id: 'tamil_movies', name: 'Tamil Movies', emoji: 'dYrdY3', sortOrder: 4),
    const WebAppCategory(id: 'k_dramas', name: 'K-Dramas', emoji: 'dYdY', sortOrder: 5),
    const WebAppCategory(id: 'manga', name: 'Manga', emoji: 'dY"-', sortOrder: 6),
    const WebAppCategory(id: 'anime_manga_ln', name: 'Anime + Manga + Light Novels', emoji: 'dY"s', sortOrder: 7),
    const WebAppCategory(id: 'light_novels', name: 'Light Novels', emoji: 'dY"s', sortOrder: 8),
    const WebAppCategory(id: 'japanese_movies', name: 'Japanese Movies', emoji: 'dY_dY', sortOrder: 9),
    const WebAppCategory(id: 'cartoons', name: 'Cartoons', emoji: 'dY"', sortOrder: 10),
  ];
}

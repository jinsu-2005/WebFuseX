import 'dart:convert';

/// Represents a named folder that groups WebApps in the Website Library.
class WebAppFolder {
  final String id;
  final String name;
  final int sortOrder;
  final bool isExpanded;

  const WebAppFolder({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    this.isExpanded = true,
  });

  WebAppFolder copyWith({
    String? id,
    String? name,
    int? sortOrder,
    bool? isExpanded,
  }) {
    return WebAppFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sortOrder': sortOrder,
        'isExpanded': isExpanded,
      };

  factory WebAppFolder.fromJson(Map<String, dynamic> json) => WebAppFolder(
        id: json['id'] as String,
        name: json['name'] as String,
        sortOrder: json['sortOrder'] as int? ?? 0,
        isExpanded: json['isExpanded'] as bool? ?? true,
      );

  static List<WebAppFolder> listFromJson(String raw) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => WebAppFolder.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<WebAppFolder> folders) {
    return jsonEncode(folders.map((f) => f.toJson()).toList());
  }
}


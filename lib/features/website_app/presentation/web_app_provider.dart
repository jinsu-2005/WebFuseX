import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/web_app.dart';
import '../../website_library/domain/web_app_folder.dart';
import '../../website_library/domain/web_app_category.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class WebAppLibraryState {
  final List<WebApp> apps;
  final List<WebAppFolder> folders;
  final List<WebAppCategory> categories;

  const WebAppLibraryState({
    required this.apps,
    this.folders = const [],
    this.categories = const [],
  });

  WebAppLibraryState copyWith({
    List<WebApp>? apps,
    List<WebAppFolder>? folders,
    List<WebAppCategory>? categories,
  }) {
    return WebAppLibraryState(
      apps: apps ?? this.apps,
      folders: folders ?? this.folders,
      categories: categories ?? this.categories,
    );
  }

  List<WebApp> get favorites => apps.where((a) => a.isFavorite).toList();

  List<WebApp> get recentlyUsed {
    final withLastUsed =
        apps.where((a) => a.lastUsed != null).toList()
          ..sort((a, b) => b.lastUsed!.compareTo(a.lastUsed!));
    return withLastUsed.take(8).toList();
  }

  /// Returns apps that belong to a specific folder, ordered by sortOrder.
  List<WebApp> appsInFolder(String folderId) {
    return apps
        .where((a) => a.folderId == folderId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Returns apps that are NOT in any folder (root-level apps).
  List<WebApp> get rootApps {
    return apps.where((a) => a.folderId.isEmpty).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Folders ordered by sortOrder.
  List<WebAppFolder> get sortedFolders {
    return [...folders]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Categories ordered by sortOrder.
  List<WebAppCategory> get sortedCategories {
    return [...categories]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
}

// â”€â”€â”€ Notifier â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class WebAppNotifier extends StateNotifier<WebAppLibraryState> {
  final SharedPreferences _prefs;

  WebAppNotifier(this._prefs)
      : super(const WebAppLibraryState(apps: [])) {
    _loadApps();
  }

  static const String _keyApps = 'streamnest_web_apps';
  static const String _keyFolders = 'webnest_folders';
  static const String _keyCategories = 'webnest_categories';

  // ─── Persistence ──────────────────────────────────────────────────────────────

  void _loadApps() {
    final String? appsJson = _prefs.getString(_keyApps);
    final String? foldersJson = _prefs.getString(_keyFolders);
    final String? categoriesJson = _prefs.getString(_keyCategories);

    var apps = <WebApp>[];
    if (appsJson != null) {
      try {
        final List<dynamic> decoded = json.decode(appsJson);
        apps = decoded.map((item) => WebApp.fromJson(item)).toList();
      } catch (_) {
        apps = [];
      }
    }

    final List<WebAppFolder> folders;
    if (foldersJson == null) {
      folders = [];
    } else {
      folders = WebAppFolder.listFromJson(foldersJson);
    }

    final List<WebAppCategory> categories;
    if (categoriesJson == null) {
      categories = WebAppCategory.defaults;
    } else {
      final parsed = WebAppCategory.listFromJson(categoriesJson);
      // Keep only custom categories (IDs are purely digits)
      final customCats = parsed.where((c) => int.tryParse(c.id) != null).toList();
      categories = [
        ...WebAppCategory.defaults,
        ...customCats,
      ];
      // Reset sortOrder to match their position
      for (int i = 0; i < categories.length; i++) {
        categories[i] = categories[i].copyWith(sortOrder: i);
      }
    }

    state = WebAppLibraryState(apps: apps, folders: folders, categories: categories);
  }

  Future<void> _saveApps() async {
    final listJson = state.apps.map((a) => a.toJson()).toList();
    await _prefs.setString(_keyApps, json.encode(listJson));
  }

  Future<void> _saveFolders() async {
    await _prefs.setString(
        _keyFolders, WebAppFolder.listToJson(state.folders));
  }

  Future<void> _saveCategories() async {
    await _prefs.setString(
        _keyCategories, WebAppCategory.listToJson(state.categories));
  }

  // â”€â”€â”€ App API â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Add a newly installed WebApp to the library.
  Future<void> addApp(WebApp app) async {
    final sortOrder = state.apps.length;
    state = state.copyWith(apps: [...state.apps, app.copyWith(sortOrder: sortOrder)]);
    await _saveApps();
  }

  /// Remove a WebApp and all its data from the library.
  Future<void> removeApp(String id) async {
    state = state.copyWith(apps: state.apps.where((a) => a.id != id).toList());
    await _saveApps();
  }

  /// Update any mutable property of a WebApp (name, icon, settings, etc.).
  Future<void> updateApp(WebApp updated) async {
    state = state.copyWith(
      apps: state.apps.map((a) => a.id == updated.id ? updated : a).toList(),
    );
    await _saveApps();
  }

  /// Record that the user launched this app (updates lastUsed timestamp).
  Future<void> recordLaunch(String id) async {
    final app = state.apps.firstWhere((a) => a.id == id,
        orElse: () => throw StateError('App not found: $id'));
    await updateApp(app.copyWith(lastUsed: DateTime.now()));
  }

  /// Toggle favorite status.
  Future<void> toggleFavorite(String id) async {
    final app = state.apps.firstWhere((a) => a.id == id,
        orElse: () => throw StateError('App not found: $id'));
    await updateApp(app.copyWith(isFavorite: !app.isFavorite));
  }

  /// Mark that a home screen shortcut was installed for this app.
  Future<void> markShortcutInstalled(String id) async {
    final app = state.apps.firstWhere((a) => a.id == id,
        orElse: () => throw StateError('App not found: $id'));
    await updateApp(app.copyWith(shortcutInstalled: true));
  }

  /// Find a WebApp by ID. Returns null if not found.
  WebApp? findById(String id) {
    try {
      return state.apps.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Reorder apps within the full list using their new sort indices.
  Future<void> reorderApps(List<String> orderedIds) async {
    final idToApp = {for (final a in state.apps) a.id: a};
    final reordered = <WebApp>[];
    for (int i = 0; i < orderedIds.length; i++) {
      final app = idToApp[orderedIds[i]];
      if (app != null) reordered.add(app.copyWith(sortOrder: i));
    }
    // Append any apps not in the ordered list (shouldn't happen normally)
    for (final app in state.apps) {
      if (!orderedIds.contains(app.id)) {
        reordered.add(app.copyWith(sortOrder: reordered.length));
      }
    }
    state = state.copyWith(apps: reordered);
    await _saveApps();
  }

  /// Move an app to a folder (or remove from folder if folderId is empty).
  Future<void> moveAppToFolder(String appId, String folderId) async {
    final app = state.apps.firstWhere((a) => a.id == appId,
        orElse: () => throw StateError('App not found: $appId'));
    await updateApp(app.copyWith(folderId: folderId));
  }

  /// Set a category label for an app.
  Future<void> setCategory(String appId, String category) async {
    final app = state.apps.firstWhere((a) => a.id == appId,
        orElse: () => throw StateError('App not found: $appId'));
    await updateApp(app.copyWith(category: category));
  }

  // â”€â”€â”€ Folder API â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<WebAppFolder> addFolder(String name) async {
    final folder = WebAppFolder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      sortOrder: state.folders.length,
    );
    state = state.copyWith(folders: [...state.folders, folder]);
    await _saveFolders();
    return folder;
  }

  Future<void> renameFolder(String id, String newName) async {
    state = state.copyWith(
      folders: state.folders
          .map((f) => f.id == id ? f.copyWith(name: newName) : f)
          .toList(),
    );
    await _saveFolders();
  }

  Future<void> removeFolder(String id) async {
    // Move apps out of the deleted folder back to root
    final updatedApps = state.apps
        .map((a) => a.folderId == id ? a.copyWith(folderId: '') : a)
        .toList();
    state = state.copyWith(
      apps: updatedApps,
      folders: state.folders.where((f) => f.id != id).toList(),
    );
    await _saveApps();
    await _saveFolders();
  }

  Future<void> reorderFolders(List<String> orderedIds) async {
    final idToFolder = {for (final f in state.folders) f.id: f};
    final reordered = <WebAppFolder>[];
    for (int i = 0; i < orderedIds.length; i++) {
      final folder = idToFolder[orderedIds[i]];
      if (folder != null) reordered.add(folder.copyWith(sortOrder: i));
    }
    state = state.copyWith(folders: reordered);
    await _saveFolders();
  }

  Future<void> toggleFolderExpanded(String id) async {
    state = state.copyWith(
      folders: state.folders
          .map((f) =>
              f.id == id ? f.copyWith(isExpanded: !f.isExpanded) : f)
          .toList(),
    );
    // No need to persist expanded state — resets on app restart is acceptable
  }

  // ─── Category API ─────────────────────────────────────────────────────────────

  Future<WebAppCategory> addCategory(String name, String emoji) async {
    final category = WebAppCategory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      emoji: emoji,
      sortOrder: state.categories.length,
    );
    state = state.copyWith(categories: [...state.categories, category]);
    await _saveCategories();
    return category;
  }

  Future<void> renameCategory(String id, String newName, String newEmoji) async {
    state = state.copyWith(
      categories: state.categories
          .map((c) => c.id == id ? c.copyWith(name: newName, emoji: newEmoji) : c)
          .toList(),
    );
    // Update any apps that use this category name as their category label to update their label as well
    // Wait, the apps store app.category as a String matching category.name, or category.id?
    // In original code: app.category = cat.label (which is category name/label!).
    // For consistency, let's keep category label matching the name, or update apps containing the old name.
    // Actually, let's update app.category to match the newName for all apps that had the old category name!
    final oldCategory = state.categories.firstWhere((c) => c.id == id);
    final updatedApps = state.apps
        .map((a) => a.category == oldCategory.name ? a.copyWith(category: newName) : a)
        .toList();
    
    state = state.copyWith(apps: updatedApps);
    await _saveApps();
    await _saveCategories();
  }

  Future<void> removeCategory(String id) async {
    final category = state.categories.firstWhere((c) => c.id == id);
    // Reset category field for any apps belonging to this category
    final updatedApps = state.apps
        .map((a) => a.category == category.name ? a.copyWith(category: '') : a)
        .toList();

    state = state.copyWith(
      apps: updatedApps,
      categories: state.categories.where((c) => c.id != id).toList(),
    );
    await _saveApps();
    await _saveCategories();
  }

  Future<void> reorderCategories(List<String> orderedIds) async {
    final idToCategory = {for (final c in state.categories) c.id: c};
    final reordered = <WebAppCategory>[];
    for (int i = 0; i < orderedIds.length; i++) {
      final category = idToCategory[orderedIds[i]];
      if (category != null) reordered.add(category.copyWith(sortOrder: i));
    }
    state = state.copyWith(categories: reordered);
    await _saveCategories();
  }
}

// â”€â”€â”€ Providers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPreferencesProvider in main.dart');
});

final webAppNotifierProvider =
    StateNotifierProvider<WebAppNotifier, WebAppLibraryState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return WebAppNotifier(prefs);
});


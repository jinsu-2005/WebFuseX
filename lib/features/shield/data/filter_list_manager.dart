import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'filter_list_urls.dart';

/// Manages download, caching, and updates of uBlock-compatible filter lists.
///
/// Lists are stored in the app's private documents directory under shield/.
/// They are updated at most once every 24 hours.
///
/// No filter list content is bundled in the APK â€” all content is fetched
/// at runtime to comply with GPL v3 requirements.
class FilterListManager {
  static const Duration _updateInterval = Duration(hours: 24);

  /// Returns the cache directory for filter lists.
  static Future<Directory> _getCacheDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/shield');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Returns the local file path for a given filter list ID.
  static Future<File> _listFile(String id) async {
    final dir = await _getCacheDir();
    return File('${dir.path}/$id.txt');
  }

  /// Returns the timestamp file for a given filter list ID.
  static Future<File> _timestampFile(String id) async {
    final dir = await _getCacheDir();
    return File('${dir.path}/$id.ts');
  }

  /// Checks if a filter list needs updating (older than [_updateInterval]).
  static Future<bool> _needsUpdate(String id) async {
    final tsFile = await _timestampFile(id);
    if (!await tsFile.exists()) return true;
    try {
      final ts = DateTime.parse(await tsFile.readAsString());
      return DateTime.now().difference(ts) > _updateInterval;
    } catch (_) {
      return true;
    }
  }

  /// Downloads and caches the given filter list if it needs updating.
  /// Returns the local file path, or null on failure.
  static Future<String?> downloadList(FilterList list) async {
    final file = await _listFile(list.id);
    if (!await _needsUpdate(list.id) && await file.exists()) {
      return file.path;
    }

    try {
      final response = await http
          .get(Uri.parse(list.url), headers: {
            'User-Agent': 'WebFuseX/1.0 FilterListFetcher',
          })
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        await file.writeAsString(response.body);
        final tsFile = await _timestampFile(list.id);
        await tsFile.writeAsString(DateTime.now().toIso8601String());
        return file.path;
      }
    } catch (_) {
      // If download fails, return existing cached file if available
      if (await file.exists()) return file.path;
    }
    return null;
  }

  /// Downloads all enabled default filter lists.
  /// Returns a list of successfully cached file paths.
  static Future<List<String>> updateEnabledLists(
      List<FilterList> lists) async {
    final results = <String>[];
    for (final list in lists.where((l) => l.enabled)) {
      final path = await downloadList(list);
      if (path != null) results.add(path);
    }
    return results;
  }

  /// Returns the last update timestamp for a list, or null if never updated.
  static Future<DateTime?> getLastUpdated(String id) async {
    final tsFile = await _timestampFile(id);
    if (!await tsFile.exists()) return null;
    try {
      return DateTime.parse(await tsFile.readAsString());
    } catch (_) {
      return null;
    }
  }

  /// Returns cached file paths for all lists that already exist on disk.
  static Future<List<String>> getCachedListPaths(
      List<FilterList> lists) async {
    final results = <String>[];
    for (final list in lists) {
      final file = await _listFile(list.id);
      if (await file.exists()) results.add(file.path);
    }
    return results;
  }

  /// Clears all cached filter list files.
  static Future<void> clearCache() async {
    try {
      final dir = await _getCacheDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }
}


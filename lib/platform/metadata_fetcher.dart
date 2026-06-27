import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../features/website_app/domain/web_app.dart';

/// Fetches website metadata from a URL to pre-fill the Add Website flow.
///
/// Attempts to extract:
///   - Page title (from <title> tag)
///   - Theme color (from <meta name="theme-color">)
///   - Favicon URL (from <link rel="icon">, with fallback to Google's favicon service)
///   - Web App Manifest name (from manifest.json if linked)
///
/// This is a best-effort fetch. If any field cannot be determined,
/// sensible defaults are returned.
class MetadataFetcher {
  static const Duration _timeout = Duration(seconds: 10);

  /// Canonical entry point. Normalizes the URL, fetches and parses metadata.
  static Future<WebsiteMetadata> fetch(String rawUrl) async {
    final url = _normalizeUrl(rawUrl);

    try {
      final response = await http
          .get(Uri.parse(url), headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 14) StreamNest/1.0 Metadata-Fetcher',
            'Accept': 'text/html',
          })
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 400) {
        return _fallback(url);
      }

      final html = response.body;
      final baseUri = Uri.parse(url);

      final title = _extractTitle(html);
      final themeColor = _extractThemeColor(html);
      final faviconUrl = _extractFavicon(html, baseUri);
      final manifestName = await _extractManifestName(html, baseUri);

      return WebsiteMetadata(
        resolvedUrl: url,
        title: manifestName.isNotEmpty
            ? manifestName
            : (title.isNotEmpty ? title : _hostLabel(url)),
        faviconUrl: faviconUrl,
        themeColorHex: themeColor,
        manifestName: manifestName,
      );
    } catch (_) {
      return _fallback(url);
    }
  }

  // â”€â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static String _normalizeUrl(String raw) {
    String url = raw.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    return url;
  }

  static WebsiteMetadata _fallback(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    return WebsiteMetadata(
      resolvedUrl: url,
      title: _hostLabel(url),
      faviconUrl: _googleFaviconUrl(host),
      themeColorHex: '#6366F1',
      manifestName: '',
    );
  }

  static String _hostLabel(String url) {
    final host = Uri.tryParse(url)?.host ?? url;
    return host.replaceFirst(RegExp(r'^www\.'), '');
  }

  static String _extractTitle(String html) {
    // Match <title>...</title>
    final match = RegExp(
      '<title[^>]*>([^<]+)</title>',
      caseSensitive: false,
    ).firstMatch(html);
    return match?.group(1)?.trim() ?? '';
  }

  static String _extractThemeColor(String html) {
    // Match <meta name="theme-color" content="..."> in either attribute order
    final patterns = [
      RegExp(
        'name=["\']theme-color["\'][^>]+content=["\']([^"\']+)["\']',
        caseSensitive: false,
      ),
      RegExp(
        'content=["\']([^"\']+)["\'][^>]+name=["\']theme-color["\']',
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null) {
        final color = match.group(1)?.trim() ?? '';
        if (color.isNotEmpty) return color;
      }
    }
    return '';
  }

  static String _extractFavicon(String html, Uri baseUri) {
    // Try link tags in preference order
    final relValues = [
      'apple-touch-icon',
      'shortcut icon',
      'icon',
    ];

    for (final rel in relValues) {
      final pattern = RegExp(
        'rel=["\']$rel["\'][^>]+href=["\']([^"\']+)["\']',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(html);
      if (match != null) {
        final href = match.group(1) ?? '';
        if (href.isNotEmpty) {
          return _resolveUrl(href, baseUri);
        }
      }
    }

    // Fallback: Google favicon service (reliable and fast)
    return _googleFaviconUrl(baseUri.host);
  }

  static Future<String> _extractManifestName(
      String html, Uri baseUri) async {
    final match = RegExp(
      'rel=["\']manifest["\'][^>]+href=["\']([^"\']+)["\']',
      caseSensitive: false,
    ).firstMatch(html);

    if (match == null) return '';

    final manifestHref = match.group(1) ?? '';
    if (manifestHref.isEmpty) return '';

    try {
      final manifestUrl = _resolveUrl(manifestHref, baseUri);
      final response = await http
          .get(Uri.parse(manifestUrl))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final manifest = json.decode(response.body) as Map<String, dynamic>;
        return (manifest['short_name'] ?? manifest['name'] ?? '').toString();
      }
    } catch (_) {}

    return '';
  }

  static String _resolveUrl(String href, Uri baseUri) {
    if (href.startsWith('http://') || href.startsWith('https://')) {
      return href;
    }
    if (href.startsWith('//')) {
      return '${baseUri.scheme}:$href';
    }
    if (href.startsWith('/')) {
      return '${baseUri.scheme}://${baseUri.host}$href';
    }
    return '${baseUri.scheme}://${baseUri.host}/$href';
  }

  static String _googleFaviconUrl(String host) {
    return 'https://www.google.com/s2/favicons?domain=$host&sz=128';
  }
}


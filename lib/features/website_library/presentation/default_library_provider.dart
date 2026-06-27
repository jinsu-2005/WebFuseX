import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../platform/metadata_fetcher.dart';
import '../domain/library_models.dart';
import '../../website_app/presentation/web_app_provider.dart';

const _kMetadataCacheKey = 'webfusex_library_metadata_cache';

// ── Category order ────────────────────────────────────────────────────────────
final defaultLibraryCategoriesProvider = Provider<List<LibraryCategoryConfig>>((ref) {
      return const [
    LibraryCategoryConfig(id: 'anime',           title: 'Featured Anime',               sortOrder: 0),
    LibraryCategoryConfig(id: 'indian_anime',    title: 'Indian Anime & Cartoons',      sortOrder: 1),
    LibraryCategoryConfig(id: 'multi_content',   title: 'Multi-Content',                sortOrder: 2),
    LibraryCategoryConfig(id: 'english_movies',  title: 'English Movies & TV Shows',    sortOrder: 3),
    LibraryCategoryConfig(id: 'tamil_movies',    title: 'Tamil Movies',                sortOrder: 4),
    LibraryCategoryConfig(id: 'k_dramas',        title: 'K-Dramas',                   sortOrder: 5),
    LibraryCategoryConfig(id: 'manga',           title: 'Manga',                        sortOrder: 6),
    LibraryCategoryConfig(id: 'anime_manga_ln',  title: 'Anime + Manga + Light Novels', sortOrder: 7),
    LibraryCategoryConfig(id: 'light_novels',    title: 'Light Novels',                 sortOrder: 8),
    LibraryCategoryConfig(id: 'japanese_movies', title: 'Japanese Movies',             sortOrder: 9),
    LibraryCategoryConfig(id: 'cartoons',        title: 'Cartoons',                     sortOrder: 10),
  ];
});

// ── App catalog ───────────────────────────────────────────────────────────────
final defaultLibraryAppsProvider = Provider<List<LibraryAppConfig>>((ref) {
  return const [
    // ── Anime ──────────────────────────────────────────────────────────────────
    LibraryAppConfig(id: 'miruro',     primaryUrl: 'https://www.miruro.to/',    mirrors: ['https://www.miruro.bz/', 'https://www.miruro.tv/'], categoryId: 'anime', nameOverride: 'Miruro',        badges: ['Hard Subs', 'Dub', 'Airing Status'], priority: 5, isFeatured: true),
    LibraryAppConfig(id: 'animetsu',   primaryUrl: 'https://animetsu.net/',     mirrors: ['https://animetsu.cc/', 'https://animetsu.bz/'],   categoryId: 'anime', nameOverride: 'Animetsu',      badges: ['Sub', 'Dub'], priority: 5, isFeatured: true),
    LibraryAppConfig(id: 'kaa',        primaryUrl: 'https://kaa.lt/',           categoryId: 'anime', nameOverride: 'KickAssAnime', badges: ['Sub', 'Dub']),
    LibraryAppConfig(id: 'animex',     primaryUrl: 'https://animex.one/home',   categoryId: 'anime', nameOverride: 'AnimeX',        badges: ['Sub', 'Dub']),
    LibraryAppConfig(id: 'anidap',     primaryUrl: 'https://anidap.se/',        categoryId: 'anime', nameOverride: 'Anidap',        badges: ['Sub', 'Dub']),
    LibraryAppConfig(id: 'kuroiru',    primaryUrl: 'https://anikuro.to/',       categoryId: 'anime', nameOverride: 'Kuroiru'),
    LibraryAppConfig(id: 'reanime',    primaryUrl: 'https://reanime.to/home',   categoryId: 'anime', nameOverride: 'Reanime'),
    LibraryAppConfig(id: 'animeverse', primaryUrl: 'https://animeverse.to/',    categoryId: 'anime', nameOverride: 'AnimeVerse'),
    LibraryAppConfig(id: 'anizone',    primaryUrl: 'https://anizone.to/',       categoryId: 'anime', nameOverride: 'AniZone', faviconOverride: 'https://icon.horse/icon/anizone.to'),
    LibraryAppConfig(id: 'miraculous', primaryUrl: 'https://miraculous.is/',    categoryId: 'anime', nameOverride: 'Miraculous'),
    LibraryAppConfig(id: 'animekhor',  primaryUrl: 'https://animekhor.org/',    categoryId: 'anime', nameOverride: 'AnimeKhor'),
    LibraryAppConfig(id: 'anikoto',    primaryUrl: 'https://anikoto.cz/home',   categoryId: 'anime', nameOverride: 'Anikoto'),

    // ── Tamil Anime ────────────────────────────────────────────────────────────
    LibraryAppConfig(id: 'animelok_tamil', primaryUrl: 'https://animelok.net/languages/tamil',             categoryId: 'indian_anime', priority: 5, isFeatured: true, nameOverride: 'AnimeLok Tamil'),
    LibraryAppConfig(id: 'animesalt',      primaryUrl: 'https://animesalt.ac/category/language/tamil/', categoryId: 'indian_anime', nameOverride: 'AnimeSalt'),

    // ── Indian Anime & Cartoons ────────────────────────────────────────────────
    LibraryAppConfig(id: 'piratexplay',     primaryUrl: 'https://piratexplay.cc/home',  categoryId: 'indian_anime', nameOverride: 'PirateXPlay'),
    LibraryAppConfig(id: 'toonstream',      primaryUrl: 'https://toonstream.vip/home',  categoryId: 'indian_anime', nameOverride: 'ToonStream'),
    LibraryAppConfig(id: 'animelok',        primaryUrl: 'https://animelok.net/home',    categoryId: 'indian_anime', nameOverride: 'AnimeLok'),
    LibraryAppConfig(id: 'watchanimeworld', primaryUrl: 'https://watchanimeworld.net/', categoryId: 'indian_anime', nameOverride: 'AnimeWorld'),

    // ── Cartoons ───────────────────────────────────────────────────────────────
    LibraryAppConfig(id: 'kimcartoon_si', primaryUrl: 'https://kimcartoon.si/', categoryId: 'cartoons', nameOverride: 'KimCartoon SI'),
    LibraryAppConfig(id: 'kimcartoon_me', primaryUrl: 'https://kimcartoon.me/', categoryId: 'cartoons', nameOverride: 'KimCartoon ME'),

    // ── Multi-Content ──────────────────────────────────────────────────────────
    LibraryAppConfig(id: 'multimovies', primaryUrl: 'https://multimovies.makeup/', categoryId: 'multi_content', badges: ['Hollywood', 'Bollywood', 'South Indian', 'OTT'], isFeatured: true, nameOverride: 'MultiMovies'),

    // ── English Movies & TV Shows (seeflix removed) ────────────────────────────
    LibraryAppConfig(id: 'cineby',        primaryUrl: 'https://www.cineby.at/',          categoryId: 'english_movies', nameOverride: 'Cineby'),
    LibraryAppConfig(id: 'rivestream',    primaryUrl: 'https://www.rivestream.app/',     categoryId: 'english_movies', nameOverride: 'Rivestream'),
    LibraryAppConfig(id: 'popcornmovies', primaryUrl: 'https://popcornmovies.org/home',  categoryId: 'english_movies', nameOverride: 'PopcornMovies'),
    LibraryAppConfig(id: 'flixer',        primaryUrl: 'https://flixer.su/',              categoryId: 'english_movies', nameOverride: 'Flixer'),
    LibraryAppConfig(id: 'flickystream',  primaryUrl: 'https://flickystream.su/',        categoryId: 'english_movies', nameOverride: 'FlickyStream'),
    LibraryAppConfig(id: 'meowtv',        primaryUrl: 'https://meowtv.ru/',             categoryId: 'english_movies', nameOverride: 'MeowTV'),
    LibraryAppConfig(id: 'cinemora',      primaryUrl: 'https://cinemora.ru/',            categoryId: 'english_movies', nameOverride: 'Cinemora'),
    LibraryAppConfig(id: 'bcine',         primaryUrl: 'https://bcine.ru/',               categoryId: 'english_movies', nameOverride: 'BCine'),
    LibraryAppConfig(id: 'popr',          primaryUrl: 'https://popr.ink/',               categoryId: 'english_movies', nameOverride: 'Popr'),
    LibraryAppConfig(id: 'cinegram',      primaryUrl: 'https://cinegram.tv/home',        categoryId: 'english_movies', nameOverride: 'Cinegram'),
    LibraryAppConfig(id: 'shuttletv',     primaryUrl: 'https://shuttletv.su/',           categoryId: 'english_movies', nameOverride: 'ShuttleTV'),
    LibraryAppConfig(id: 'lordflix',      primaryUrl: 'https://lordflix.org/',           categoryId: 'english_movies', nameOverride: 'LordFlix'),
    LibraryAppConfig(id: 'moonflix',      primaryUrl: 'https://moonflix.site/browse',    categoryId: 'english_movies', nameOverride: 'MoonFlix'),
    LibraryAppConfig(id: 'watchflix',     primaryUrl: 'https://watchflix.to/',           categoryId: 'english_movies', nameOverride: 'WatchFlix'),
    LibraryAppConfig(id: 'cinestream',    primaryUrl: 'https://cinestream.kje.us/',      categoryId: 'english_movies', nameOverride: 'CineStream'),
    LibraryAppConfig(id: 'primeshows',    primaryUrl: 'https://primeshows.uk/',          categoryId: 'english_movies', nameOverride: 'PrimeShows'),
    LibraryAppConfig(id: '67movies',      primaryUrl: 'https://67movies.net/',           categoryId: 'english_movies', nameOverride: '67Movies'),
    LibraryAppConfig(id: 'aether',        primaryUrl: 'https://aether.bar/',             categoryId: 'english_movies', nameOverride: 'Aether'),

    // ── Tamil Movies ───────────────────────────────────────────────────────────
    LibraryAppConfig(id: '1tamilmv',       primaryUrl: 'https://www.1tamilmv.durban/',           categoryId: 'tamil_movies', nameOverride: '1TamilMV'),
    LibraryAppConfig(id: 'tamilgun',       primaryUrl: 'https://tamilgun.now/movies/',           categoryId: 'tamil_movies', nameOverride: 'TamilGun'),
    LibraryAppConfig(id: '1tamilcrow',     primaryUrl: 'https://www.1tamilcrow.net/',            categoryId: 'tamil_movies', nameOverride: '1TamilCrow'),
    LibraryAppConfig(id: 'tamilbulb',      primaryUrl: 'https://tamilbulb.cc/',                 categoryId: 'tamil_movies', nameOverride: 'TamilBulb'),
    LibraryAppConfig(id: '1tamilblasters', primaryUrl: 'https://www.1tamilblasters.republican/', categoryId: 'tamil_movies', nameOverride: '1TamilBlasters'),

    // ── K-Dramas ───────────────────────────────────────────────────────────────
    LibraryAppConfig(id: 'goplay',     primaryUrl: 'https://goplay.su/',      categoryId: 'k_dramas', nameOverride: 'GoPlay', faviconOverride: 'https://icon.horse/icon/goplay.su'),
    LibraryAppConfig(id: 'dramacoolg', primaryUrl: 'https://dramacoolg.top/', categoryId: 'k_dramas', nameOverride: 'DramaCoolG'),
    LibraryAppConfig(id: 'kisskh',     primaryUrl: 'https://kisskh.nl/',      categoryId: 'k_dramas', nameOverride: 'KissKH'),
    LibraryAppConfig(id: 'dramacoold', primaryUrl: 'https://dramacoold.top/', categoryId: 'k_dramas', nameOverride: 'DramaCoolD'),

    // ── Manga ──────────────────────────────────────────────────────────────────
    LibraryAppConfig(id: 'mangadex',    primaryUrl: 'https://mangadex.org/',     categoryId: 'manga', nameOverride: 'MangaDex'),
    LibraryAppConfig(id: 'kagane',      primaryUrl: 'https://kagane.to/',        categoryId: 'manga', nameOverride: 'Kagane'),
    LibraryAppConfig(id: 'weebcentral', primaryUrl: 'https://weebcentral.com/',  categoryId: 'manga', nameOverride: 'WeebCentral', faviconOverride: 'https://icons.duckduckgo.com/ip3/weebcentral.com.ico'),
    LibraryAppConfig(id: 'mangafire',   primaryUrl: 'https://mangafire.to/home', categoryId: 'manga', nameOverride: 'MangaFire'),
    LibraryAppConfig(id: 'atsu',        primaryUrl: 'https://atsu.moe/',         categoryId: 'manga', nameOverride: 'Atsu'),
    LibraryAppConfig(id: 'mangadot',    primaryUrl: 'https://mangadot.net/',     categoryId: 'manga', nameOverride: 'MangaDot'),
    LibraryAppConfig(id: 'onisaga',     primaryUrl: 'https://onisaga.com/home',  categoryId: 'manga', nameOverride: 'OniSaga'),

    // ── Anime + Manga + Light Novels ───────────────────────────────────────────
    LibraryAppConfig(id: 'allmanga', primaryUrl: 'https://allmanga.to/anime?tr=sub&cty=ALL', categoryId: 'anime_manga_ln', nameOverride: 'AllManga', badges: ['Anime', 'Manga', 'Light Novels']),

    // ── Light Novels ───────────────────────────────────────────────────────────
    LibraryAppConfig(id: 'lightnovelworld', primaryUrl: 'https://lightnovelworld.org/', categoryId: 'light_novels', isFeatured: true, nameOverride: 'LightNovelWorld', faviconOverride: 'https://icon.horse/icon/lightnovelworld.org'),

    // ── Japanese Movies ────────────────────────────────────────────────────────
    LibraryAppConfig(id: 'jp_films', primaryUrl: 'https://jp-films.com/', categoryId: 'japanese_movies', nameOverride: 'JP Films'),
  ];
});

// ── Metadata cache provider (raw JSON map from SharedPreferences) ─────────────
// This is a simple Provider that reads from prefs once. The library provider
// refreshes it by invalidating when the cache is updated.
final _metadataCacheProvider = Provider<Map<String, dynamic>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final str = prefs.getString(_kMetadataCacheKey);
  if (str == null) return {};
  try {
    return jsonDecode(str) as Map<String, dynamic>;
  } catch (_) {
    return {};
  }
});

// ── Main synchronous library provider ────────────────────────────────────────
//
// KEY FIX: This is now a regular synchronous `Provider` (not FutureProvider),
// so it re-evaluates reactively whenever `webAppNotifierProvider` or the cache
// changes. The UI is NEVER blocked — fallback metadata is used immediately while
// background fetches populate the cache via `_BackgroundFetcher`.
final defaultLibraryProvider = Provider<List<LibraryAppRuntime>>((ref) {
  final apps       = ref.watch(defaultLibraryAppsProvider);
  final cache      = ref.watch(_metadataCacheProvider);
  final appState   = ref.watch(webAppNotifierProvider);

  // Fast-lookup sets for installed apps
  final installedUrls = appState.apps.map((a) => _norm(a.url)).toSet();
  final installedIds  = appState.apps.map((a) => a.id).toSet();

  final results = <LibraryAppRuntime>[];

  for (final app in apps) {
    // Skip apps already installed in My Apps (real-time filtering)
    final appUrlSet = {app.primaryUrl, ...app.mirrors}.map(_norm).toSet();
    if (installedIds.contains(app.id) ||
        installedUrls.intersection(appUrlSet).isNotEmpty) {
      continue;
    }

    // Use cached metadata if available
    if (cache.containsKey(app.id)) {
      final meta = LibraryAppMetadata.fromJson(
          cache[app.id] as Map<String, dynamic>);
      results.add(LibraryAppRuntime(config: app, metadata: meta));
      continue;
    }

    // Instant fallback: show immediately with Google favicon + name from URL
    final host         = Uri.tryParse(app.primaryUrl)?.host ?? app.primaryUrl;
    final displayHost  = host.replaceFirst(RegExp(r'^www\.'), '');
    final fallbackName = app.nameOverride ?? displayHost;
    final fallbackFav  = app.faviconOverride ?? 'https://www.google.com/s2/favicons?domain=$host&sz=64';

    results.add(LibraryAppRuntime(
      config: app,
      metadata: LibraryAppMetadata(
        resolvedUrl: app.primaryUrl,
        title: fallbackName,
        faviconUrl: fallbackFav,
        themeColorHex: '#6366F1',
      ),
    ));

    // Trigger a one-shot background fetch (fire and forget)
    // This will update the SharedPreferences cache and cause the provider
    // to refresh via `ref.invalidate(_metadataCacheProvider)` inside the fetcher.
    _triggerBackgroundFetch(ref, app);
  }

  return results;
});

// ── Background fetch registry — prevents duplicate concurrent fetches ─────────
final _fetchingIds = <String>{};

void _triggerBackgroundFetch(Ref ref, LibraryAppConfig app) {
  if (_fetchingIds.contains(app.id)) return; // already fetching
  _fetchingIds.add(app.id);

  () async {
    final prefs = ref.read(sharedPreferencesProvider);
    final urlsToTry = [app.primaryUrl, ...app.mirrors];

    for (final url in urlsToTry) {
      try {
        final meta       = await MetadataFetcher.fetch(url);
        final host       = Uri.tryParse(meta.resolvedUrl)?.host ?? url;
        final hostClean  = host.replaceFirst(RegExp(r'^www\.'), '');
        final title      = app.nameOverride ??
            (meta.title.isNotEmpty ? meta.title : hostClean);
        final favicon = app.faviconOverride ?? (meta.faviconUrl.isNotEmpty
            ? meta.faviconUrl
            : 'https://www.google.com/s2/favicons?domain=$host&sz=64');

        final metadata = LibraryAppMetadata(
          resolvedUrl: meta.resolvedUrl,
          title: title,
          faviconUrl: favicon,
          themeColorHex:
              meta.themeColorHex.isNotEmpty ? meta.themeColorHex : '#6366F1',
        );

        // Load existing cache, merge, save
        final existingStr = prefs.getString(_kMetadataCacheKey);
        final existing    = existingStr != null
            ? (jsonDecode(existingStr) as Map<String, dynamic>)
            : <String, dynamic>{};
        existing[app.id] = metadata.toJson();
        await prefs.setString(_kMetadataCacheKey, jsonEncode(existing));

        // Invalidate the cache provider so the library provider re-runs
        ref.invalidate(_metadataCacheProvider);
        break; // success — stop trying mirrors
      } catch (_) {
        // try next mirror
      }
    }

    _fetchingIds.remove(app.id);
  }();
}

// ── Helpers ───────────────────────────────────────────────────────────────────
String _norm(String url) =>
    url.trim().toLowerCase().replaceFirst(RegExp(r'/$'), '');

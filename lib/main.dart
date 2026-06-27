import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/website_app/presentation/web_app_provider.dart';
import 'features/website_library/presentation/website_library_screen.dart';
import 'features/website_onboarding/presentation/add_website_screen.dart';
import 'features/web_engine/presentation/web_session_screen.dart';
import 'features/settings/presentation/app_settings_provider.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/shield/data/filter_list_manager.dart';
import 'features/shield/data/filter_list_urls.dart';
import 'platform/shield_channel.dart';
import 'platform/shortcut_channel.dart';
import 'package:flutter/services.dart';

final initialAppIdProvider = Provider<String?>((ref) => null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable Edge-to-Edge mode for Android 14/15+
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  final results = await Future.wait([
    SharedPreferences.getInstance(),
    ShortcutChannel.getInitialAppId(),
  ]);
  final prefs = results[0] as SharedPreferences;
  final initialAppId = results[1] as String?;

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialAppIdProvider.overrideWithValue(initialAppId),
      ],
      child: const WebFuseXApp(),
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final initialAppId = ref.read(initialAppIdProvider);
  return GoRouter(
    initialLocation: initialAppId != null ? '/session/$initialAppId' : '/splash',
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      // Home — Website Library
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => const NoTransitionPage(child: WebsiteLibraryScreen()),
      ),
      // Add Website flow
      GoRoute(
        path: '/add',
        pageBuilder: (context, state) => const NoTransitionPage(child: AddWebsiteScreen()),
      ),
      // Catch native deep links (streamnest://app/...)
      GoRoute(
        path: '/app/:appId',
        redirect: (context, state) {
          final appId = state.pathParameters['appId'];
          return '/session/$appId';
        },
      ),
      // Launch a website as an app — passes directly to the session screen
      GoRoute(
        path: '/session/:appId',
        pageBuilder: (context, state) {
          final appId = state.pathParameters['appId'] ?? '';
          return NoTransitionPage(child: WebSessionScreen(appId: appId));
        },
      ),
    ],
  );
});

class BouncingScrollBehavior extends ScrollBehavior {
  const BouncingScrollBehavior();
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

class WebFuseXApp extends ConsumerStatefulWidget {
  const WebFuseXApp({super.key});

  @override
  ConsumerState<WebFuseXApp> createState() => _WebFuseXAppState();
}

class _WebFuseXAppState extends ConsumerState<WebFuseXApp> {
  @override
  void initState() {
    super.initState();

    // Listen for shortcut launches while the app is already in memory
    ShortcutChannel.setLaunchListener((appId) {
      if (mounted) {
        ref.read(routerProvider).go('/session/$appId');
      }
    });

    // Download and load filter lists in the background after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFilterLists();
    });
  }

  Future<void> _initFilterLists() async {
    final settings = ref.read(appSettingsProvider);
    if (!settings.adBlockerEnabled) return;

    try {
      // Use cached lists first for immediate protection
      final cachedPaths = await FilterListManager.getCachedListPaths(
        FilterListUrls.defaults,
      );
      if (cachedPaths.isNotEmpty) {
        await ShieldChannel.loadFilterLists(cachedPaths);
      }

      // Then download updates (max once per 24h)
      final updatedPaths = await FilterListManager.updateEnabledLists(
        FilterListUrls.defaults,
      );
      if (updatedPaths.isNotEmpty) {
        await ShieldChannel.clearRules();
        await ShieldChannel.loadFilterLists(updatedPaths);
        await ref.read(appSettingsProvider.notifier).markFilterListsUpdated();
      }
    } catch (_) {
      // Filter list errors should never crash the app
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      builder: (context, child) => ScrollConfiguration(
        behavior: const BouncingScrollBehavior(),
        child: child!,
      ),
      title: 'WebFuseX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? const Color(0xFF6366F1)
                : Colors.white38,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                : Colors.white12,
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}

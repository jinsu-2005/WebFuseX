
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../website_app/domain/web_app.dart';
import '../../website_app/presentation/web_app_provider.dart';
import '../../web_engine/presentation/web_engine_view.dart';
import '../../../platform/shortcut_channel.dart';
import '../../../platform/web_engine_channel.dart';
import '../../website_app/presentation/app_settings_sheet.dart';
import '../../settings/presentation/app_settings_provider.dart';
import '../../settings/presentation/permissions_provider.dart';
import '../../website_onboarding/presentation/edit_website_screen.dart';

/// The Web Session Screen ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â renders a website as if it were a native app.
///
/// DESIGN PRINCIPLES:
///   - NO permanent address bar (the website IS the app)
///   - NO browser tabs
///   - NO omnibox as primary UI
///   - Minimal status row at top (favicon + app name only)
///   - Browser controls are HIDDEN and revealed only by sliding the top bar down
class WebSessionScreen extends ConsumerStatefulWidget {
  final String appId;

  const WebSessionScreen({super.key, required this.appId});

  @override
  ConsumerState<WebSessionScreen> createState() => _WebSessionScreenState();
}

class _WebSessionScreenState extends ConsumerState<WebSessionScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {

  String _currentSettingsHash = '';
  GlobalKey _webViewKey = GlobalKey();

  GlobalKey _getWebViewKey(String settingsHash) {
    if (settingsHash != _currentSettingsHash) {
      _currentSettingsHash = settingsHash;
      _webViewKey = GlobalKey();
    }
    return _webViewKey;
  }

  late AnimationController _drawerCtrl;
  late Animation<double> _drawerAnim;

  bool _controlsVisible = false;
  String? _currentUrl;
  final _urlController = TextEditingController();

  bool _isLoading = true;
  double _splashOpacity = 1.0;
  int _blockedCount = 0;
  bool _isFullscreen = false;

  Timer? _refreshTimer;
  WebEngineChannel? _channel;

  static const _platformChannel = MethodChannel('com.webnest/pip');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _drawerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _drawerAnim = CurvedAnimation(
      parent: _drawerCtrl,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = ref.read(webAppNotifierProvider);
      final app = appState.apps.firstWhere(
        (a) => a.id == widget.appId,
        orElse: () => const WebApp(id: '', url: '', name: ''),
      );
      if (app.id.isNotEmpty) {
        _urlController.text = app.url;
        _updateTaskDescription(app);
      }
      _startTimer();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    _resetTaskDescription();
    _drawerCtrl.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  void _startTimer() {
    _stopTimer();
    final appState = ref.read(webAppNotifierProvider);
    final settings = ref.read(appSettingsProvider);
    final app = appState.apps.firstWhere(
      (a) => a.id == widget.appId,
      orElse: () => const WebApp(id: '', url: '', name: ''),
    );
    if (app.id.isEmpty) return;

    final autoRefreshEnabled = app.autoRefreshEnabledOverride ?? settings.autoRefreshEnabled;
    final interval = app.autoRefreshIntervalOverride ?? settings.autoRefreshInterval;

    if (autoRefreshEnabled && interval > 0) {
      _refreshTimer = Timer.periodic(Duration(seconds: interval), (timer) {
        if (mounted && !_isLoading) {
          _channel?.reload();
        }
      });
    }
  }

  void _stopTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void _updateTaskDescription(WebApp app) {
    _platformChannel.invokeMethod('updateTaskDescription', {
      'label': app.name,
      'themeColor': app.themeColorHex,
      'faviconUrl': app.faviconUrl,
    });
  }

  void _resetTaskDescription() {
    _platformChannel.invokeMethod('updateTaskDescription', {
      'label': 'WebFuseX',
      'themeColor': '#6366F1',
      'faviconUrl': '',
    });
  }

  void _toggleControls() {
    if (_controlsVisible) {
      _drawerCtrl.reverse().then((_) {
        setState(() => _controlsVisible = false);
      });
    } else {
      setState(() => _controlsVisible = true);
      _drawerCtrl.forward();
    }
  }

  void _hideControls() {
    if (_controlsVisible) {
      _drawerCtrl.reverse().then((_) {
        setState(() => _controlsVisible = false);
      });
    }
  }

  void _navigateTo(String rawUrl) {
    String url = rawUrl.trim();
    if (url.isEmpty) return;

    final isUrl =
        url.contains('.') &&
        !url.contains(' ') &&
        (url.startsWith('http') || Uri.tryParse(url)?.hasAuthority == true);

    if (!isUrl) {
      url = 'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
    } else if (!url.startsWith('http')) {
      url = 'https://$url';
    }

    setState(() {
      _currentUrl = url;
      _urlController.text = url;
    });
    _hideControls();
    FocusScope.of(context).unfocus();
  }

  void _enterPip() {
    _platformChannel.invokeMethod('enterPiP');
  }

  void _toggleShield(WebApp app) {
    final updated = app.copyWith(shieldEnabled: !app.shieldEnabled);
    ref.read(webAppNotifierProvider.notifier).updateApp(updated);
  }

  void _toggleDesktopMode(WebApp app) {
    final updated = app.copyWith(desktopMode: !app.desktopMode);
    ref.read(webAppNotifierProvider.notifier).updateApp(updated);
  }

  void _sharePage(WebApp app, String currentUrl) {
    _platformChannel.invokeMethod('shareUrl', {
      'url': currentUrl,
      'title': app.name,
    });
  }

  void _showAppSettings(BuildContext context, WebApp app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AppSettingsSheet(
        app: app,
        onUpdateApp: (updated) {
          ref.read(webAppNotifierProvider.notifier).updateApp(updated);
          if (updated.name != app.name) {
            _updateTaskDescription(updated);
          }
          // Restart timer if auto refresh interval or enabled overrides changed
          _startTimer();
        },
        onPinShortcut: () async {
          Navigator.pop(ctx);
          final status = await ShortcutChannel.pinShortcut(
            appId: app.id,
            appName: app.name,
            themeColor: app.themeColorHex,
            faviconUrl: app.faviconUrl,
          );
          if (status == 'SUCCESS') {
            ref
                .read(webAppNotifierProvider.notifier)
                .markShortcutInstalled(app.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Pin request sent for "${app.name}". Check your launcher.',
                  ),
                  backgroundColor: const Color(0xFF6366F1),
                ),
              );
            }
          } else {
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (dCtx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Shortcut Pinning Failed',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Text(
                    _getShortcutErrorExplanation(status, app.name),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dCtx),
                      child: const Text(
                        'OK',
                        style: TextStyle(color: Color(0xFF6366F1)),
                      ),
                    ),
                  ],
                ),
              );
            }
          }
        },
        onClearData: () {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Website storage and cookies have been cleared.'),
              backgroundColor: Color(0xFF6366F1),
            ),
          );
        },
        onUninstall: () {
          Navigator.pop(ctx);
          _confirmUninstall(context, app);
        },
        onCustomize: () {
          Navigator.pop(ctx);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EditWebsiteScreen(app: app),
            ),
          );
        },
      ),
    );
  }

  void _confirmUninstall(BuildContext context, WebApp app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Uninstall App',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Uninstall "${app.name}" and remove it from WebFuseX? '
          'This will delete its shortcuts and permanently clear all its isolated storage.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(webAppNotifierProvider.notifier).removeApp(app.id);
              GoRouter.of(context).go('/');
            },
            child: const Text(
              'Uninstall',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  String _getShortcutErrorExplanation(String status, String appName) {
    if (status == 'NOT_SUPPORTED') {
      return 'Your launcher or device does not support pinning home screen shortcuts. '
          'You can still launch "$appName" directly from the WebFuseX Library.';
    } else if (status == 'FAILED') {
      return 'The system launcher rejected the pinning request. '
          'Please verify launcher permissions or retry later from app settings.';
    } else if (status.startsWith('ERROR_')) {
      final errorDetail = status.replaceFirst('ERROR_', '');
      return 'An unexpected error occurred during shortcut creation: $errorDetail\n\n'
          'You can retry later from the app settings.';
    }
    return 'Could not create home screen shortcut (Status: $status). '
        'You can retry pinning it later from app settings.';
  }

  Future<bool> _showPermissionDialog(String origin, String resource) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$resource Permission', style: const TextStyle(color: Colors.white)),
        content: Text('"$origin" wants to use your $resource.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Deny', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Allow', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(webAppNotifierProvider);
    final settings = ref.watch(appSettingsProvider);
    final app = appState.apps.firstWhere(
      (a) => a.id == widget.appId,
      orElse: () => const WebApp(id: '', url: '', name: 'Unknown'),
    );

    if (app.id.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Text('App not found', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    final themeColor = _parseColor(app.themeColorHex);
    final sessionUrl = _currentUrl ?? app.url;
    final isShortcutMode = !Navigator.of(context).canPop();

    // Fullscreen: bare scaffold with no system UI
    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _controlsVisible ? _hideControls : null,
                child: WebEngineView(
                  key: _getWebViewKey(
                    '${sessionUrl}_'
                    '${app.shieldEnabledOverride ?? app.shieldEnabled}_'
                    '${app.desktopModeOverride ?? app.desktopMode}_'
                    '${app.jsEnabledOverride ?? settings.javascriptEnabled}_'
                    '${app.cookiesEnabledOverride ?? settings.cookiesEnabled}_'
                    '${app.thirdPartyCookiesEnabledOverride ?? settings.thirdPartyCookiesEnabled}_'
                    '${app.pinchToZoomEnabledOverride ?? settings.pinchToZoomEnabled}_'
                    '${app.openLinksExternallyOverride ?? settings.openLinksExternally}_'
                    '${app.loadImagesEnabledOverride ?? settings.loadImagesEnabled}_'
                    '${settings.hardwareAccelerationEnabled}'
                  ),
                  initialUrl: sessionUrl,
                  profileId: app.id,
                  shieldEnabled: app.shieldEnabledOverride ?? app.shieldEnabled,
                  desktopMode: app.desktopModeOverride ?? (app.desktopMode || settings.defaultMode.name == 'desktop'),
                  jsEnabled: app.jsEnabledOverride ?? settings.javascriptEnabled,
                  cookiesEnabled: app.cookiesEnabledOverride ?? settings.cookiesEnabled,
                  thirdPartyCookiesEnabled: app.thirdPartyCookiesEnabledOverride ?? settings.thirdPartyCookiesEnabled,
                  hardwareAccelerationEnabled: settings.hardwareAccelerationEnabled,
                  forceDarkMode: settings.forceDarkModeForWebsites,
                  popupBlockingEnabled: settings.popupBlockingEnabled,
                  backgroundPlaybackEnabled: settings.backgroundPlaybackEnabled,
                  customUserAgent: settings.userAgentMode.name == 'custom' ? settings.customUserAgent : '',
                  pinchToZoomEnabled: app.pinchToZoomEnabledOverride ?? settings.pinchToZoomEnabled,
                  openLinksExternally: app.openLinksExternallyOverride ?? settings.openLinksExternally,
                  loadImagesEnabled: app.loadImagesEnabledOverride ?? settings.loadImagesEnabled,
                  twoFingerReloadEnabled: settings.twoFingerReloadEnabled,
                  onEnterFullscreen: () {
                    setState(() => _isFullscreen = true);
                    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
                  },
                  onExitFullscreen: () {
                    setState(() => _isFullscreen = false);
                    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
                      statusBarColor: Colors.black,
                      statusBarIconBrightness: Brightness.light,
                      systemNavigationBarColor: Colors.black,
                      systemNavigationBarIconBrightness: Brightness.light,
                    ));
                  },
                  onChannelCreated: (ch) => _channel = ch,
                  onPermissionRequest: (origin, resources) async {
                    final perms = ref.read(permissionsProvider.notifier);
                    String resourceType = 'Camera';
                    if (resources.contains('android.webkit.resource.AUDIO_CAPTURE')) {
                      resourceType = 'Microphone';
                    } else if (resources.contains('android.webkit.resource.VIDEO_CAPTURE')) {
                      resourceType = 'Camera';
                    }
                    final state = perms.getPermission(origin, resourceType);
                    if (state == PermissionState.granted) return true;
                    if (state == PermissionState.denied) return false;
                    final granted = await _showPermissionDialog(origin, resourceType);
                    perms.setSitePermission(origin, resourceType, granted ? PermissionState.granted : PermissionState.denied);
                    return granted;
                  },
                  onGeolocationPermission: (origin) async {
                    final perms = ref.read(permissionsProvider.notifier);
                    final state = perms.getPermission(origin, 'Location');
                    if (state == PermissionState.granted) return true;
                    if (state == PermissionState.denied) return false;
                    final granted = await _showPermissionDialog(origin, 'Location');
                    perms.setSitePermission(origin, 'Location', granted ? PermissionState.granted : PermissionState.denied);
                    return granted;
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _controlsVisible ? _hideControls : null,
                  child: WebEngineView(
                    key: _getWebViewKey(
                    '${sessionUrl}_'
                    '${app.shieldEnabledOverride ?? app.shieldEnabled}_'
                    '${app.desktopModeOverride ?? app.desktopMode}_'
                    '${app.jsEnabledOverride ?? settings.javascriptEnabled}_'
                    '${app.cookiesEnabledOverride ?? settings.cookiesEnabled}_'
                    '${app.thirdPartyCookiesEnabledOverride ?? settings.thirdPartyCookiesEnabled}_'
                    '${app.pinchToZoomEnabledOverride ?? settings.pinchToZoomEnabled}_'
                    '${app.openLinksExternallyOverride ?? settings.openLinksExternally}_'
                    '${app.loadImagesEnabledOverride ?? settings.loadImagesEnabled}_'
                    '${settings.hardwareAccelerationEnabled}'
                  ),
                    initialUrl: sessionUrl,
                    profileId: app.id,
                    shieldEnabled: app.shieldEnabledOverride ?? app.shieldEnabled,
                    desktopMode: app.desktopModeOverride ?? (app.desktopMode || settings.defaultMode.name == 'desktop'),
                    jsEnabled: app.jsEnabledOverride ?? settings.javascriptEnabled,
                    cookiesEnabled: app.cookiesEnabledOverride ?? settings.cookiesEnabled,
                    thirdPartyCookiesEnabled: app.thirdPartyCookiesEnabledOverride ?? settings.thirdPartyCookiesEnabled,
                    hardwareAccelerationEnabled: settings.hardwareAccelerationEnabled,
                    forceDarkMode: settings.forceDarkModeForWebsites,
                    popupBlockingEnabled: settings.popupBlockingEnabled,
                    backgroundPlaybackEnabled: settings.backgroundPlaybackEnabled,
                    customUserAgent: settings.userAgentMode.name == 'custom' ? settings.customUserAgent : '',
                    pinchToZoomEnabled: app.pinchToZoomEnabledOverride ?? settings.pinchToZoomEnabled,
                    openLinksExternally: app.openLinksExternallyOverride ?? settings.openLinksExternally,
                    loadImagesEnabled: app.loadImagesEnabledOverride ?? settings.loadImagesEnabled,
                    twoFingerReloadEnabled: settings.twoFingerReloadEnabled,
                    onProgressChanged: (progress) {
                      if (progress >= 100 && _isLoading) {
                        setState(() => _isLoading = false);
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) setState(() => _splashOpacity = 0.0);
                        });
                      }
                    },
                    onPageStarted: (url) {
                      setState(() {
                        _currentUrl = url;
                        _urlController.text = url;
                      });
                    },
                    onPageFinished: (url) {
                      setState(() {
                        _currentUrl = url;
                        _urlController.text = url;
                        _isLoading = false;
                      });
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (mounted) setState(() => _splashOpacity = 0.0);
                      });
                      _startTimer();
                    },
                    onResourceBlocked: (count) {
                      setState(() => _blockedCount = count);
                    },
                    onEnterFullscreen: () {
                      setState(() => _isFullscreen = true);
                      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
                    },
                    onExitFullscreen: () {
                      setState(() => _isFullscreen = false);
                      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
                        statusBarColor: Colors.black,
                        statusBarIconBrightness: Brightness.light,
                        systemNavigationBarColor: Colors.black,
                        systemNavigationBarIconBrightness: Brightness.light,
                      ));
                    },
                    onPermissionRequest: (origin, resources) async {
                      final perms = ref.read(permissionsProvider.notifier);
                      String resourceType = 'Camera';
                      if (resources.contains('android.webkit.resource.AUDIO_CAPTURE')) {
                        resourceType = 'Microphone';
                      } else if (resources.contains('android.webkit.resource.VIDEO_CAPTURE')) {
                        resourceType = 'Camera';
                      } else if (resources.contains('android.webkit.resource.PROTECTED_MEDIA_ID')) {
                        resourceType = 'Storage';
                      }
                      final state = perms.getPermission(origin, resourceType);
                      if (state == PermissionState.granted) return true;
                      if (state == PermissionState.denied) return false;
                      final granted = await _showPermissionDialog(origin, resourceType);
                      perms.setSitePermission(origin, resourceType, granted ? PermissionState.granted : PermissionState.denied);
                      return granted;
                    },
                    onGeolocationPermission: (origin) async {
                      final perms = ref.read(permissionsProvider.notifier);
                      final state = perms.getPermission(origin, 'Location');
                      if (state == PermissionState.granted) return true;
                      if (state == PermissionState.denied) return false;
                      final granted = await _showPermissionDialog(origin, 'Location');
                      perms.setSitePermission(origin, 'Location', granted ? PermissionState.granted : PermissionState.denied);
                      return granted;
                    },
                    onChannelCreated: (ch) => _channel = ch,
                  ),
                ),
              ),

              // Top Notch / Trigger Area
              if (!_isFullscreen && !_controlsVisible && !settings.hideNotch)
                Positioned(
                  top: settings.notchAppearance == 'dot' ? 8 : 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _toggleControls,
                      child: Container(
                        width: settings.notchAppearance == 'dot' ? 32 : settings.notchAppearance == 'bar' ? 240 : 140,
                        height: settings.notchAppearance == 'dot' ? 32 : settings.notchAppearance == 'bar' ? 12 : 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withValues(alpha: settings.notchTransparency),
                          borderRadius: settings.notchAppearance == 'dot'
                              ? BorderRadius.circular(16)
                              : settings.notchAppearance == 'bar'
                                  ? const BorderRadius.vertical(bottom: Radius.circular(4))
                                  : const BorderRadius.vertical(bottom: Radius.circular(12)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3 * settings.notchTransparency),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: settings.notchAppearance != 'bar'
                            ? Icon(
                                settings.notchAppearance == 'dot' ? Icons.circle : Icons.keyboard_arrow_down_rounded,
                                color: Colors.white.withValues(alpha: settings.notchTransparency),
                                size: settings.notchAppearance == 'dot' ? 12 : 16,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

              // Collapsible Control Drawer â€” hidden during fullscreen
              if (_controlsVisible && !_isFullscreen)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SizeTransition(
                    sizeFactor: _drawerAnim,
                    axisAlignment: -1,
                    child: _ControlDrawer(
                      app: app,
                      themeColor: themeColor,
                      urlController: _urlController,
                      currentUrl: sessionUrl,
                      blockedCount: _blockedCount,
                      onNavigate: _navigateTo,
                      onBack: () => context.pop(),
                      onPip: _enterPip,
                      onToggleShield: () => _toggleShield(app),
                      onToggleDesktopMode: () => _toggleDesktopMode(app),
                      onShare: () => _sharePage(app, sessionUrl),
                      onShowSettings: () => _showAppSettings(context, app),
                      onClose: _hideControls,
                      showBackButton: !isShortcutMode,
                    ),
                  ),
                ),

              // Splash Screen â€” fades out when content is ready
              if (_splashOpacity > 0)
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: _splashOpacity,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    child: Container(
                      color: Colors.black,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),
                          // App icon â€” full display, no crop
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: themeColor.withValues(alpha: 0.35),
                                  blurRadius: 28,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(10),
                            child: app.faviconUrl.isNotEmpty
                                ? Image.network(
                                    app.faviconUrl,
                                    width: 76,
                                    height: 76,
                                    fit: BoxFit.contain, // Full icon, no crop
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.language, color: Colors.white70, size: 48),
                                  )
                                : const Icon(Icons.language, color: Colors.white70, size: 48),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            app.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 48),
                            child: SizedBox(
                              width: 48,
                              height: 3,
                              child: LinearProgressIndicator(
                                value: null,
                                backgroundColor: Colors.white12,
                                color: themeColor,
                                borderRadius: BorderRadius.circular(2),
                                minHeight: 3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
/// Hidden by default. Slides down from the top when the status bar is tapped.
/// Contains navigation controls and URL bar.
class _ControlDrawer extends StatelessWidget {
  final WebApp app;
  final Color themeColor;
  final TextEditingController urlController;
  final String currentUrl;
  final int blockedCount;
  final ValueChanged<String> onNavigate;
  final VoidCallback onBack;
  final VoidCallback onPip;
  final VoidCallback onToggleShield;
  final VoidCallback onToggleDesktopMode;
  final VoidCallback onShare;
  final VoidCallback onShowSettings;
  final VoidCallback onClose;
  final bool showBackButton;

  const _ControlDrawer({
    required this.app,
    required this.themeColor,
    required this.urlController,
    required this.currentUrl,
    required this.blockedCount,
    required this.onNavigate,
    required this.onBack,
    required this.onPip,
    required this.onToggleShield,
    required this.onToggleDesktopMode,
    required this.onShare,
    required this.onShowSettings,
    required this.onClose,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App identity row
          Row(
            children: [
              if (showBackButton) ...[
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onBack,
                ),
                const SizedBox(width: 10),
              ],
              if (app.faviconUrl.isNotEmpty)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      app.faviconUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.language, color: themeColor, size: 14),
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              Text(
                app.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.white54,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // URL bar
          _UrlBar(
            controller: urlController,
            currentUrl: currentUrl,
            themeColor: themeColor,
            onNavigate: onNavigate,
          ),
          const SizedBox(height: 10),

          // Navigation controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavButton(
                icon: Icons.picture_in_picture_alt,
                label: 'PiP',
                onTap: onPip,
              ),
              _NavButton(icon: Icons.share, label: 'Share', onTap: onShare),
              _NavButton(
                icon: app.shieldEnabled
                    ? Icons.security
                    : Icons.security_outlined,
                label: app.shieldEnabled
                    ? 'Shield ($blockedCount)'
                    : 'Shield Off',
                color: app.shieldEnabled ? Colors.greenAccent : Colors.white38,
                onTap: onToggleShield,
              ),
              _NavButton(
                icon: app.desktopMode
                    ? Icons.desktop_windows
                    : Icons.desktop_windows_outlined,
                label: 'Desktop',
                color: app.desktopMode
                    ? const Color(0xFF818CF8)
                    : Colors.white38,
                onTap: onToggleDesktopMode,
              ),
              _NavButton(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () {
                  onClose();
                  onShowSettings();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”
class _UrlBar extends StatelessWidget {
  final TextEditingController controller;
  final String currentUrl;
  final Color themeColor;
  final ValueChanged<String> onNavigate;

  const _UrlBar({
    required this.controller,
    required this.currentUrl,
    required this.themeColor,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final isSecure = currentUrl.startsWith('https');

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(
            isSecure ? Icons.lock : Icons.lock_open,
            size: 13,
            color: isSecure ? Colors.greenAccent : Colors.orangeAccent,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              textInputAction: TextInputAction.go,
              keyboardType: TextInputType.url,
              onTap: () => controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: controller.text.length,
              ),
              onSubmitted: onNavigate,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”

Color _parseColor(String hex) {
  try {
    final buffer = StringBuffer();
    final clean = hex.replaceFirst('#', '');
    if (clean.length == 6) buffer.write('ff');
    buffer.write(clean);
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (_) {
    return const Color(0xFF6366F1);
  }
}

class _OverrideOptionDropdown extends StatelessWidget {
  final String label;
  final bool? currentValue;
  final bool globalValue;
  final ValueChanged<bool?> onChanged;

  const _OverrideOptionDropdown({
    required this.label,
    required this.currentValue,
    required this.globalValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          DropdownButton<bool?>(
            value: currentValue,
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            underline: const SizedBox(),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text('Inherit (${globalValue ? "On" : "Off"})', style: const TextStyle(color: Colors.white54)),
              ),
              const DropdownMenuItem(
                value: true,
                child: Text('Always On'),
              ),
              const DropdownMenuItem(
                value: false,
                child: Text('Always Off'),
              ),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}


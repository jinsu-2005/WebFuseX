import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../platform/web_engine_channel.dart';

/// Embeds the native Android WebView via a PlatformView.
///
/// Each instance is bound to a [profileId] which maps to an isolated
/// WebKit profile â€” meaning cookies, storage, and cache are completely
/// separate from all other WebApp sessions.
///
/// Advanced settings (JS, cookies, hardware acceleration, etc.) are passed
/// as creation params to the native layer and applied at WebView init time.
class WebEngineView extends StatefulWidget {
  final String initialUrl;
  final String profileId;
  final bool shieldEnabled;
  final bool desktopMode;

  // â”€â”€ Global settings forwarded to native â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final bool jsEnabled;
  final bool cookiesEnabled;
  final bool thirdPartyCookiesEnabled;
  final bool hardwareAccelerationEnabled;
  final bool forceDarkMode;
  final bool popupBlockingEnabled;
  final String customUserAgent;
  final bool pinchToZoomEnabled;
  final bool openLinksExternally;
  final bool loadImagesEnabled;

  // ── Two-finger reload ───────────────────────────────────────────────────────
  final bool twoFingerReloadEnabled;

  // ── Background playback ─────────────────────────────────────────────────────
  final bool backgroundPlaybackEnabled;

  // ── Callbacks ───────────────────────────────────────────────────────────────
  final ValueChanged<int>? onProgressChanged;
  final ValueChanged<String>? onPageStarted;
  final ValueChanged<String>? onPageFinished;
  final ValueChanged<int>? onResourceBlocked;
  final VoidCallback? onEnterFullscreen;
  final VoidCallback? onExitFullscreen;
  final Future<bool> Function(String origin, List<String> resources)? onPermissionRequest;
  final Future<bool> Function(String origin)? onGeolocationPermission;
  final ValueChanged<WebEngineChannel>? onChannelCreated;
  final void Function(bool canGoBack, bool canGoForward)? onHistoryChanged;
  final VoidCallback? onRenderProcessCrash;

  const WebEngineView({
    super.key,
    required this.initialUrl,
    required this.profileId,
    this.shieldEnabled = true,
    this.desktopMode = false,
    this.jsEnabled = true,
    this.cookiesEnabled = true,
    this.thirdPartyCookiesEnabled = true,
    this.hardwareAccelerationEnabled = true,
    this.forceDarkMode = false,
    this.popupBlockingEnabled = true,
    this.customUserAgent = '',
    this.pinchToZoomEnabled = true,
    this.openLinksExternally = false,
    this.loadImagesEnabled = true,
    this.twoFingerReloadEnabled = false,
    this.backgroundPlaybackEnabled = false,
    this.onProgressChanged,
    this.onPageStarted,
    this.onPageFinished,
    this.onResourceBlocked,
    this.onEnterFullscreen,
    this.onExitFullscreen,
    this.onPermissionRequest,
    this.onGeolocationPermission,
    this.onChannelCreated,
    this.onHistoryChanged,
    this.onRenderProcessCrash,
  });

  @override
  State<WebEngineView> createState() => _WebEngineViewState();
}

class _WebEngineViewState extends State<WebEngineView> {
  WebEngineChannel? _channel;

  // Two-finger swipe tracking
  int _activePointers = 0;
  double _twoFingerStartY = 0;
  bool _twoFingerReloaded = false;
  static const double _reloadThreshold = 80.0; // pixels down

  void _onPlatformViewCreated(int id) {
    final channel = WebEngineChannel(id);
    _channel = channel;

    channel.onProgressChanged = widget.onProgressChanged;
    channel.onPageStarted = widget.onPageStarted;
    channel.onPageFinished = widget.onPageFinished;
    channel.onResourceBlocked = widget.onResourceBlocked;
    channel.onEnterFullscreen = widget.onEnterFullscreen;
    channel.onExitFullscreen = widget.onExitFullscreen;
    channel.onPermissionRequest = widget.onPermissionRequest;
    channel.onGeolocationPermission = widget.onGeolocationPermission;
    channel.onHistoryChanged = widget.onHistoryChanged;
    channel.onRenderProcessCrash = widget.onRenderProcessCrash;

    widget.onChannelCreated?.call(channel);
  }

  // â”€â”€ Two-finger swipe gesture detection â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _onPointerDown(PointerDownEvent event) {
    _activePointers++;
    if (_activePointers == 2) {
      _twoFingerStartY = event.position.dy;
      _twoFingerReloaded = false;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!widget.twoFingerReloadEnabled) return;
    if (_activePointers == 2 && !_twoFingerReloaded) {
      final deltaY = event.position.dy - _twoFingerStartY;
      if (deltaY > _reloadThreshold) {
        _twoFingerReloaded = true;
        _channel?.reload();
        HapticFeedback.mediumImpact();
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 10);
    if (_activePointers < 2) {
      _twoFingerReloaded = false;
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 10);
  }

  @override
  Widget build(BuildContext context) {
    const String viewType = 'webnest_webview';
    final Map<String, dynamic> creationParams = <String, dynamic>{
      'initialUrl': widget.initialUrl,
      'profileId': widget.profileId,
      'shieldEnabled': widget.shieldEnabled,
      'desktopMode': widget.desktopMode,
      'jsEnabled': widget.jsEnabled,
      'cookiesEnabled': widget.cookiesEnabled,
      'thirdPartyCookiesEnabled': widget.thirdPartyCookiesEnabled,
      'hardwareAccelerationEnabled': widget.hardwareAccelerationEnabled,
      'forceDarkMode': widget.forceDarkMode,
      'popupBlockingEnabled': widget.popupBlockingEnabled,
      'customUserAgent': widget.customUserAgent,
      'pinchToZoomEnabled': widget.pinchToZoomEnabled,
      'openLinksExternally': widget.openLinksExternally,
      'loadImagesEnabled': widget.loadImagesEnabled,
      'backgroundPlaybackEnabled': widget.backgroundPlaybackEnabled,
    };

    if (defaultTargetPlatform == TargetPlatform.android) {
      return Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: AndroidView(
          viewType: viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<VerticalDragGestureRecognizer>(
              () => VerticalDragGestureRecognizer(),
            ),
            Factory<HorizontalDragGestureRecognizer>(
              () => HorizontalDragGestureRecognizer(),
            ),
          },
        ),
      );
    }

    return const Center(
      child: Text(
        'WebView is only supported on Android.',
        style: TextStyle(color: Colors.white54),
      ),
    );
  }
}


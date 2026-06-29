import 'package:flutter/services.dart';

class WebEngineChannel {
  final int viewId;
  late final MethodChannel _channel;

  // Callbacks from native WebView
  void Function(int)? onProgressChanged;
  void Function(String)? onPageStarted;
  void Function(String)? onPageFinished;
  void Function(int)? onResourceBlocked;
  void Function()? onEnterFullscreen;
  void Function()? onExitFullscreen;
  Future<bool> Function(String origin, List<String> resources)? onPermissionRequest;
  Future<bool> Function(String origin)? onGeolocationPermission;
  void Function(bool canGoBack, bool canGoForward)? onHistoryChanged;
  void Function()? onRenderProcessCrash;

  WebEngineChannel(this.viewId) {
    _channel = MethodChannel('com.webnest/engine_$viewId');
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onHistoryChanged':
        final canGoBack = call.arguments['canGoBack'] as bool?;
        final canGoForward = call.arguments['canGoForward'] as bool?;
        if (canGoBack != null && canGoForward != null) {
          onHistoryChanged?.call(canGoBack, canGoForward);
        }
        break;
      case 'onRenderProcessGone':
        onRenderProcessCrash?.call();
        break;
      case 'onProgressChanged':
        final progress = call.arguments['progress'] as int?;
        if (progress != null) {
          onProgressChanged?.call(progress);
        }
        break;
      case 'onPageStarted':
        final url = call.arguments['url'] as String?;
        if (url != null) {
          onPageStarted?.call(url);
        }
        break;
      case 'onPageFinished':
        final url = call.arguments['url'] as String?;
        if (url != null) {
          onPageFinished?.call(url);
        }
        break;
      case 'onResourceBlocked':
        final blockedCount = call.arguments['blockedCount'] as int?;
        if (blockedCount != null) {
          onResourceBlocked?.call(blockedCount);
        }
        break;
      case 'onEnterFullscreen':
        onEnterFullscreen?.call();
        return null;
      case 'onExitFullscreen':
        onExitFullscreen?.call();
        return null;
      case 'onPermissionRequest':
        final origin = call.arguments['origin'] as String?;
        final resources = (call.arguments['resources'] as List?)?.cast<String>();
        if (origin != null && resources != null && onPermissionRequest != null) {
          return await onPermissionRequest!(origin, resources);
        }
        return false;
      case 'onGeolocationPermission':
        final origin = call.arguments['origin'] as String?;
        if (origin != null && onGeolocationPermission != null) {
          return await onGeolocationPermission!(origin);
        }
        return false;
      default:
        return null;
    }
  }

  Future<void> loadUrl(String url) async {
    await _channel.invokeMethod('loadUrl', {'url': url});
  }

  Future<bool> goBack() async {
    final result = await _channel.invokeMethod<bool>('goBack');
    return result ?? false;
  }

  Future<bool> goForward() async {
    final result = await _channel.invokeMethod<bool>('goForward');
    return result ?? false;
  }

  Future<void> reload() async {
    await _channel.invokeMethod('reload');
  }

  Future<void> pause() async {
    await _channel.invokeMethod('onPause');
  }

  Future<void> resume() async {
    await _channel.invokeMethod('onResume');
  }

  static Future<void> clearData(String id) async {
    // Stub
  }

  Future<void> updateSettings({bool? shieldEnabled}) async {
    final Map<String, dynamic> args = {};
    if (shieldEnabled != null) args['shieldEnabled'] = shieldEnabled;
    if (args.isNotEmpty) {
      await _channel.invokeMethod('updateSettings', args);
    }
  }
}


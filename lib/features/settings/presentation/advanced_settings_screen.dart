import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/presentation/app_settings_provider.dart';
import 'website_permissions_screen.dart';
import '../../shield/data/filter_list_manager.dart';
import '../../shield/data/filter_list_urls.dart';
import '../../../platform/shield_channel.dart';

/// Advanced Settings â€” a full-page settings screen with all browser options.
class AdvancedSettingsScreen extends ConsumerStatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  ConsumerState<AdvancedSettingsScreen> createState() =>
      _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState
    extends ConsumerState<AdvancedSettingsScreen> {
  static const _nativeChannel = MethodChannel('com.webnest/settings');

  bool _isUpdatingLists = false;

  // â”€â”€â”€ Native helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _clearCache() async {
    try {
      await _nativeChannel.invokeMethod('clearCache');
    } catch (_) {}
    if (mounted) {
      _showSnack('Cache cleared.');
    }
  }

  Future<void> _clearCookies() async {
    try {
      await _nativeChannel.invokeMethod('clearCookies');
    } catch (_) {}
    if (mounted) {
      _showSnack('Cookies cleared.');
    }
  }

  Future<void> _clearAllData() async {
    try {
      await _nativeChannel.invokeMethod('clearAllData');
    } catch (_) {}
    if (mounted) {
      _showSnack('All browsing data cleared.');
    }
  }

  Future<void> _clearWebStorage() async {
    try {
      await _nativeChannel.invokeMethod('clearWebStorage');
    } catch (_) {}
    if (mounted) {
      _showSnack('Website storage cleared.');
    }
  }

  Future<void> _updateFilterLists() async {
    if (_isUpdatingLists) return;
    setState(() => _isUpdatingLists = true);
    try {
      final paths = await FilterListManager.updateEnabledLists(
        FilterListUrls.defaults,
      );
      await ShieldChannel.loadFilterLists(paths);
      await ref.read(appSettingsProvider.notifier).markFilterListsUpdated();
      if (mounted)
        _showSnack('Filter lists updated (${paths.length} lists loaded).');
    } catch (_) {
      if (mounted)
        _showSnack('Could not update filter lists. Check your connection.');
    } finally {
      if (mounted) setState(() => _isUpdatingLists = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showJsWarning(bool newValue, AppSettings settings) {
    if (!newValue) {
      // Disabling JS â€” show warning
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'âš ï¸ Disable JavaScript?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Disabling JavaScript will break most modern websites. '
            'Features like login forms, video playback, and dynamic content will stop working.\n\n'
            'Only proceed if you understand the impact.',
            style: TextStyle(color: Colors.white70),
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
                ref
                    .read(appSettingsProvider.notifier)
                    .setJavascriptEnabled(false);
              },
              child: const Text(
                'Disable Anyway',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );
    } else {
      ref.read(appSettingsProvider.notifier).setJavascriptEnabled(true);
    }
  }

  void _showHwAccelWarning(bool newValue) {
    if (!newValue) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'âš ï¸ Disable Hardware Acceleration?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Software rendering significantly impacts scrolling and video performance. '
            'Only disable this if you experience rendering glitches on your device.',
            style: TextStyle(color: Colors.white70),
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
                ref
                    .read(appSettingsProvider.notifier)
                    .setHardwareAcceleration(false);
              },
              child: const Text(
                'Disable Anyway',
                style: TextStyle(color: Colors.orangeAccent),
              ),
            ),
          ],
        ),
      );
    } else {
      ref.read(appSettingsProvider.notifier).setHardwareAcceleration(true);
    }
  }

  void _showDnsDialog(AppSettings settings) {
    final customDnsCtrl = TextEditingController(text: settings.customDnsServer);
    DnsMode selected = settings.dnsMode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'DNS Selection',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<DnsMode>(
                  title: const Text(
                    'System DNS',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Use device default',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  value: DnsMode.system,
                  groupValue: selected,
                  activeColor: const Color(0xFF818CF8),
                  onChanged: (v) => setDialogState(() => selected = v!),
                ),
                RadioListTile<DnsMode>(
                  title: const Text(
                    'Custom DNS',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Enter custom DNS server address',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  value: DnsMode.custom,
                  groupValue: selected,
                  activeColor: const Color(0xFF818CF8),
                  onChanged: (v) => setDialogState(() => selected = v!),
                ),
                if (selected == DnsMode.custom)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                    child: TextField(
                      controller: customDnsCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g. 1.1.1.1',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amberAccent,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Android WebView Limitation',
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Android WebView does not support changing DNS servers inside a single app. '
                        'To use custom or AdGuard DNS, configure it in Android System Settings:\n\n'
                        '1. Open Settings -> Network & Internet\n'
                        '2. Tap Private DNS\n'
                        '3. Select Private DNS provider hostname\n'
                        '4. Enter: dns.adguard.com (or your provider)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                ref.read(appSettingsProvider.notifier).setDnsMode(selected);
                if (selected == DnsMode.custom) {
                  ref
                      .read(appSettingsProvider.notifier)
                      .setCustomDns(customDnsCtrl.text.trim());
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Color(0xFF818CF8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserAgentDialog(AppSettings settings) {
    final customUaCtrl = TextEditingController(text: settings.customUserAgent);
    UserAgentMode selected = settings.userAgentMode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'User-Agent',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<UserAgentMode>(
                title: const Text(
                  'Default (Android)',
                  style: TextStyle(color: Colors.white),
                ),
                value: UserAgentMode.defaultAgent,
                groupValue: selected,
                activeColor: const Color(0xFF818CF8),
                onChanged: (v) => setDialogState(() => selected = v!),
              ),
              RadioListTile<UserAgentMode>(
                title: const Text(
                  'Desktop (Chrome)',
                  style: TextStyle(color: Colors.white),
                ),
                value: UserAgentMode.desktop,
                groupValue: selected,
                activeColor: const Color(0xFF818CF8),
                onChanged: (v) => setDialogState(() => selected = v!),
              ),
              RadioListTile<UserAgentMode>(
                title: const Text(
                  'Custom',
                  style: TextStyle(color: Colors.white),
                ),
                value: UserAgentMode.custom,
                groupValue: selected,
                activeColor: const Color(0xFF818CF8),
                onChanged: (v) => setDialogState(() => selected = v!),
              ),
              if (selected == UserAgentMode.custom)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                  child: TextField(
                    controller: customUaCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Paste a custom User-Agent stringâ€¦',
                      hintStyle: const TextStyle(
                        color: Colors.white30,
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
            ],
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
                ref
                    .read(appSettingsProvider.notifier)
                    .setUserAgentMode(selected);
                if (selected == UserAgentMode.custom) {
                  ref
                      .read(appSettingsProvider.notifier)
                      .setCustomUserAgent(customUaCtrl.text.trim());
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Color(0xFF818CF8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Advanced Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // â”€â”€ Gestures â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SectionHeader('Gestures'),
          _SettingsTile(
            icon: Icons.touch_app_outlined,
            iconColor: const Color(0xFF818CF8),
            title: 'Two-Finger Swipe to Reload',
            subtitle: 'Swipe down with two fingers to reload the current page',
            trailing: Switch(
              value: settings.twoFingerReloadEnabled,
              onChanged: (v) =>
                  ref.read(appSettingsProvider.notifier).setTwoFingerReload(v),
              activeThumbColor: const Color(0xFF818CF8),
            ),
          ),

          // â”€â”€ General Web Options â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SectionHeader('General Web Options'),
          _SettingsTile(
            icon: Icons.zoom_in_rounded,
            iconColor: Colors.blueAccent,
            title: 'Pinch-to-Zoom',
            subtitle: 'Allow pinching to zoom web pages',
            trailing: Switch(
              value: settings.pinchToZoomEnabled,
              onChanged: (v) => ref
                  .read(appSettingsProvider.notifier)
                  .setPinchToZoomEnabled(v),
              activeThumbColor: const Color(0xFF818CF8),
            ),
          ),
          _SettingsTile(
            icon: Icons.image_outlined,
            iconColor: Colors.greenAccent,
            title: 'Load Images',
            subtitle: 'Load images on web pages',
            trailing: Switch(
              value: settings.loadImagesEnabled,
              onChanged: (v) => ref
                  .read(appSettingsProvider.notifier)
                  .setLoadImagesEnabled(v),
              activeThumbColor: const Color(0xFF818CF8),
            ),
          ),
          _SettingsTile(
            icon: Icons.open_in_browser_rounded,
            iconColor: Colors.tealAccent,
            title: 'Open Links Externally',
            subtitle: 'Launch links in default external browser',
            trailing: Switch(
              value: settings.openLinksExternally,
              onChanged: (v) => ref
                  .read(appSettingsProvider.notifier)
                  .setOpenLinksExternally(v),
              activeThumbColor: const Color(0xFF818CF8),
            ),
          ),
          _SettingsTile(
            icon: Icons.refresh_rounded,
            iconColor: Colors.purpleAccent,
            title: 'Auto Refresh Default',
            subtitle: 'Enable periodic auto refresh by default',
            trailing: Switch(
              value: settings.autoRefreshEnabled,
              onChanged: (v) => ref
                  .read(appSettingsProvider.notifier)
                  .setAutoRefreshEnabled(v),
              activeThumbColor: const Color(0xFF818CF8),
            ),
          ),
          _SettingsTile(
            icon: Icons.timer_outlined,
            iconColor: Colors.purpleAccent,
            title: 'Auto Refresh Interval',
            subtitle: 'Default: ${settings.autoRefreshInterval} seconds',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.remove,
                    color: Colors.white60,
                    size: 16,
                  ),
                  onPressed: settings.autoRefreshInterval > 5
                      ? () => ref
                            .read(appSettingsProvider.notifier)
                            .setAutoRefreshInterval(
                              settings.autoRefreshInterval - 5,
                            )
                      : null,
                ),
                Text(
                  '${settings.autoRefreshInterval}s',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white60, size: 16),
                  onPressed: () => ref
                      .read(appSettingsProvider.notifier)
                      .setAutoRefreshInterval(settings.autoRefreshInterval + 5),
                ),
              ],
            ),
          ),

          // â”€â”€ Privacy & Security â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SectionHeader('Privacy & Security'),
          _SettingsTile(
            icon: Icons.code_rounded,
            iconColor: Colors.amberAccent,
            title: 'JavaScript',
            subtitle: 'Enable JavaScript on all websites',
            trailing: Switch(
              value: settings.javascriptEnabled,
              onChanged: (v) => _showJsWarning(v, settings),
              activeThumbColor: const Color(0xFF818CF8),
            ),
          ),
          _SettingsTile(
            icon: Icons.cookie_outlined,
            iconColor: Colors.orangeAccent,
            title: 'Cookies',
            subtitle: 'Allow websites to set cookies',
            trailing: Switch(
              value: settings.cookiesEnabled,
              onChanged: (v) =>
                  ref.read(appSettingsProvider.notifier).setCookiesEnabled(v),
              activeThumbColor: const Color(0xFF818CF8),
            ),
          ),
          _SettingsTile(
            icon: Icons.share_rounded,
            iconColor: Colors.deepOrangeAccent,
            title: 'Third-Party Cookies',
            subtitle: 'Allow cookies from external domains',
            trailing: Switch(
              value: settings.thirdPartyCookiesEnabled,
              onChanged: settings.cookiesEnabled
                  ? (v) => ref
                        .read(appSettingsProvider.notifier)
                        .setThirdPartyCookiesEnabled(v)
                  : null,
              activeThumbColor: const Color(0xFF818CF8),
            ),
          ),
          _SettingsTile(
            icon: Icons.open_in_new_off_rounded,
            iconColor: Colors.blueAccent,
            title: 'Block Pop-ups',
            subtitle: 'Prevent websites from opening pop-up windows',
            trailing: Switch(
              value: settings.popupBlockingEnabled,
              onChanged: (v) => ref
                  .read(appSettingsProvider.notifier)
                  .setPopupBlockingEnabled(v),
              activeThumbColor: const Color(0xFF818CF8),
            ),
          ),
          _SettingsTile(
            icon: Icons.track_changes_rounded,
            iconColor: Colors.tealAccent,
            title: 'Tracker Blocking',
            subtitle: 'Block cross-site tracking requests',
            trailing: Switch(
              value: settings.trackerBlockingEnabled,
              onChanged: (v) => ref
                  .read(appSettingsProvider.notifier)
                  .setTrackerBlockingEnabled(v),
              activeThumbColor: const Color(0xFF818CF8),
            ),
          ),

          // â”€â”€ Ad Blocking â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SectionHeader('Ad Blocking'),
          _SettingsTile(
            icon: Icons.security_rounded,
            iconColor: Colors.greenAccent,
            title: 'WebFuseX Shield',
            subtitle:
                'Block ads and trackers using uBlock-compatible filter lists',
            trailing: Switch(
              value: settings.adBlockerEnabled,
              onChanged: (v) =>
                  ref.read(appSettingsProvider.notifier).setAdBlockerEnabled(v),
              activeThumbColor: Colors.greenAccent,
            ),
          ),
          _SettingsTile(
            icon: Icons.update_rounded,
            iconColor: Colors.greenAccent,
            title: 'Update Filter Lists',
            subtitle: settings.filterListsLastUpdated != null
                ? 'Last updated: ${_formatDate(settings.filterListsLastUpdated!)}'
                : 'Never updated — tap to download now',
            trailing: _isUpdatingLists
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.greenAccent,
                    ),
                  )
                : const Icon(Icons.chevron_right, color: Colors.white38),
            onTap: _updateFilterLists,
          ),
          _SettingsTile(
            icon: Icons.list_alt_rounded,
            iconColor: Colors.greenAccent,
            title: 'Manage Filter Lists',
            subtitle: 'Enable or disable individual filter lists',
            trailing: const Icon(Icons.chevron_right, color: Colors.white38),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FilterListsScreen()),
            ),
          ),

          // â”€â”€ Appearance â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SectionHeader('Appearance'),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            iconColor: const Color(0xFF818CF8),
            title: 'Force Dark Mode for Websites',
            subtitle: 'Apply dark mode to all web content (experimental)',
            trailing: Switch(
              value: settings.forceDarkModeForWebsites,
              onChanged: (v) =>
                  ref.read(appSettingsProvider.notifier).setForceDarkMode(v),
              activeThumbColor: const Color(0xFF818CF8),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.devices_rounded,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Default Mode',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Choose site layout for all apps',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: SegmentedButton<AppDefaultMode>(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (s) => s.contains(WidgetState.selected)
                            ? const Color(0xFF818CF8)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith<Color>(
                        (s) => s.contains(WidgetState.selected)
                            ? Colors.white
                            : Colors.white54,
                      ),
                      side: WidgetStateProperty.all(
                        const BorderSide(color: Colors.white12),
                      ),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: AppDefaultMode.mobile,
                        icon: Icon(Icons.smartphone_rounded, size: 16),
                        label: Text('Mobile'),
                      ),
                      ButtonSegment(
                        value: AppDefaultMode.desktop,
                        icon: Icon(Icons.desktop_windows_rounded, size: 16),
                        label: Text('Desktop'),
                      ),
                    ],
                    selected: {settings.defaultMode},
                    onSelectionChanged: (Set<AppDefaultMode> sel) {
                      if (sel.isNotEmpty)
                        ref
                            .read(appSettingsProvider.notifier)
                            .setDefaultMode(sel.first);
                    },
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // â”€â”€ Performance â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SectionHeader('Performance'),
          _SettingsTile(
            icon: Icons.memory_rounded,
            iconColor: Colors.cyanAccent,
            title: 'Hardware Acceleration',
            subtitle: 'GPU rendering for smoother performance (recommended)',
            trailing: Switch(
              value: settings.hardwareAccelerationEnabled,
              onChanged: _showHwAccelWarning,
              activeThumbColor: const Color(0xFF818CF8),
            ),
          ),
          _SettingsTile(
            icon: Icons.headphones_rounded,
            iconColor: Colors.purpleAccent,
            title: 'Background Playback',
            subtitle: 'Continue audio/video when switching apps',
            trailing: Switch(
              value: settings.backgroundPlaybackEnabled,
              onChanged: (v) => ref
                  .read(appSettingsProvider.notifier)
                  .setBackgroundPlayback(v),
              activeThumbColor: const Color(0xFF818CF8),
            ),
          ),

          // â”€â”€ Network â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SectionHeader('Network'),
          _SettingsTile(
            icon: Icons.dns_rounded,
            iconColor: Colors.lightBlueAccent,
            title: 'DNS Selection',
            subtitle: settings.dnsMode == DnsMode.custom
                ? 'Custom: ${settings.customDnsServer}'
                : 'System DNS',
            trailing: const Icon(Icons.chevron_right, color: Colors.white38),
            onTap: () => _showDnsDialog(settings),
          ),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            iconColor: Colors.amberAccent,
            title: 'User-Agent',
            subtitle: _userAgentLabel(settings),
            trailing: const Icon(Icons.chevron_right, color: Colors.white38),
            onTap: () => _showUserAgentDialog(settings),
          ),

          // â”€â”€ Session â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SectionHeader('Session'),
          _SettingsTile(
            icon: Icons.history_rounded,
            iconColor: Colors.white54,
            title: 'Restore Previous Session',
            subtitle: 'Reopen last website on app launch',
            trailing: Switch(
              value: settings.restorePreviousSession,
              onChanged: (v) => ref
                  .read(appSettingsProvider.notifier)
                  .setRestorePreviousSession(v),
              activeThumbColor: const Color(0xFF818CF8),
            ),
          ),
          _SettingsTile(
            icon: Icons.swipe_down_rounded,
            iconColor: Colors.pinkAccent,
            title: 'Two-Finger Reload',
            subtitle: 'Swipe down with two fingers to reload page',
            trailing: Switch(
              value: settings.twoFingerReloadEnabled,
              onChanged: (v) => ref
                  .read(appSettingsProvider.notifier)
                  .setTwoFingerReloadEnabled(v),
              activeThumbColor: const Color(0xFF818CF8),
            ),
          ),

          // â”€â”€ Storage â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SectionHeader('Storage'),
          _SettingsTile(
            icon: Icons.delete_sweep_outlined,
            iconColor: Colors.redAccent,
            title: 'Clear Cache',
            subtitle: 'Free up space by deleting cached web data',
            onTap: () => _confirmAction(
              title: 'Clear Cache?',
              message:
                  'This will clear cached images and files from all websites.',
              onConfirm: _clearCache,
            ),
          ),
          _SettingsTile(
            icon: Icons.cookie_outlined,
            iconColor: Colors.redAccent,
            title: 'Clear Cookies',
            subtitle:
                'Remove all cookies â€” you will be logged out everywhere',
            onTap: () => _confirmAction(
              title: 'Clear All Cookies?',
              message:
                  'You will be signed out of all websites. This cannot be undone.',
              onConfirm: _clearCookies,
            ),
          ),
          _SettingsTile(
            icon: Icons.cleaning_services_outlined,
            iconColor: Colors.redAccent,
            title: 'Clear Browsing Data',
            subtitle: 'Clear cache, cookies, and browsing history',
            onTap: () => _confirmAction(
              title: 'Clear All Browsing Data?',
              message:
                  'Cache, cookies, and history will be deleted. You will be signed out of all websites.',
              onConfirm: _clearAllData,
            ),
          ),
          _SettingsTile(
            icon: Icons.storage_rounded,
            iconColor: Colors.redAccent,
            title: 'Clear Website Storage',
            subtitle: 'Remove local storage, IndexedDB, and service workers',
            onTap: () => _confirmAction(
              title: 'Clear Website Storage?',
              message:
                  'Local data stored by websites will be permanently deleted.',
              onConfirm: _clearWebStorage,
            ),
          ),

          // â”€â”€ Permissions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SectionHeader('Permissions'),
          _SettingsTile(
            icon: Icons.manage_accounts_rounded,
            iconColor: const Color(0xFF818CF8),
            title: 'Website Permissions Manager',
            subtitle:
                'Manage camera, microphone, location, and notification access',
            trailing: const Icon(Icons.chevron_right, color: Colors.white38),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const WebsitePermissionsScreen(),
              ),
            ),
          ),

          // ── Notch ────────────────────────────────────────────────────────
          _SectionHeader('WebFuseX Navigation Notch'),
          Consumer(
            builder: (context, ref, child) {
              final settings = ref.watch(appSettingsProvider);
              return Column(
                children: [
                  _ToggleTile(
                    icon: Icons.visibility_off_outlined,
                    iconColor: Colors.tealAccent,
                    title: 'Hide Drop-down',
                    subtitle: 'Hide the top notch trigger completely',
                    value: settings.hideNotch,
                    onChanged: (v) => ref
                        .read(appSettingsProvider.notifier)
                        .updateSettings(settings.copyWith(hideNotch: v)),
                    activeColor: Colors.tealAccent,
                  ),
                  if (!settings.hideNotch) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notch Transparency',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          Slider(
                            value: settings.notchTransparency,
                            min: 0.1,
                            max: 1.0,
                            activeColor: Colors.tealAccent,
                            inactiveColor: Colors.tealAccent.withValues(
                              alpha: 0.2,
                            ),
                            onChanged: (v) => ref
                                .read(appSettingsProvider.notifier)
                                .updateSettings(
                                  settings.copyWith(notchTransparency: v),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Notch Appearance',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          DropdownButton<String>(
                            value: settings.notchAppearance,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(
                                value: 'pill',
                                child: Text('Pill'),
                              ),
                              DropdownMenuItem(
                                value: 'bar',
                                child: Text('Flat Bar'),
                              ),
                              DropdownMenuItem(
                                value: 'dot',
                                child: Text('Dot'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                ref
                                    .read(appSettingsProvider.notifier)
                                    .updateSettings(
                                      settings.copyWith(notchAppearance: v),
                                    );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),

          // ── Developer ────────────────────────────────────────────────────
          _SectionHeader('Developer'),
          _SettingsTile(
            icon: Icons.person_rounded,
            iconColor: Colors.blueAccent,
            title: 'Developer',
            subtitle: 'Jinsu J',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _socialButton(
                  FontAwesomeIcons.linkedin,
                  'LinkedIn',
                  'https://linkedin.com',
                ),
                _socialButton(
                  FontAwesomeIcons.instagram,
                  'Instagram',
                  'https://instagram.com',
                ),
                _socialButton(
                  FontAwesomeIcons.github,
                  'GitHub',
                  'https://github.com',
                ),
                _socialButton(
                  FontAwesomeIcons.youtube,
                  'YouTube',
                  'https://youtube.com',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton.icon(
              onPressed: () {
                _nativeChannel.invokeMethod('openUrl', {
                  'url': 'https://buymeacoffee.com/jinsuj',
                });
              },
              icon: const Icon(Icons.coffee, color: Colors.black87),
              label: const Text(
                'Buy Me a Coffee',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFDD00),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _confirmAction({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
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
              onConfirm();
            },
            child: const Text(
              'Confirm',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _userAgentLabel(AppSettings s) {
    switch (s.userAgentMode) {
      case UserAgentMode.defaultAgent:
        return 'Default (Android WebView)';
      case UserAgentMode.desktop:
        return 'Desktop (Chrome on Linux)';
      case UserAgentMode.custom:
        return s.customUserAgent.isNotEmpty
            ? s.customUserAgent.substring(
                0,
                s.customUserAgent.length.clamp(0, 40),
              )
            : 'Custom (not set)';
    }
  }

  Widget _socialButton(dynamic icon, String label, String url) {
    return InkWell(
      onTap: () {
        _nativeChannel.invokeMethod('openUrl', {'url': url});
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            FaIcon(icon, color: const Color(0xFF818CF8), size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Lists Management Screen ──────────────────────────────────

class FilterListsScreen extends ConsumerStatefulWidget {
  const FilterListsScreen({super.key});

  @override
  ConsumerState<FilterListsScreen> createState() => _FilterListsScreenState();
}

class _FilterListsScreenState extends ConsumerState<FilterListsScreen> {
  late List<FilterList> _lists;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider);
    // Resolve enabled state: persisted settings take priority over hardcoded defaults.
    // This fixes the bug where ublock_privacy (default: false) reverts after toggling on.
    _lists = FilterListUrls.defaults.map((list) {
      if (settings.enabledFilterLists.contains(list.id)) {
        return list.copyWith(enabled: true);
      } else if (settings.disabledFilterLists.contains(list.id)) {
        return list.copyWith(enabled: false);
      }
      // Fall through to hardcoded default
      return list;
    }).toList();
  }

  Future<void> _updateSelected() async {
    setState(() => _isLoading = true);
    try {
      final paths = await FilterListManager.updateEnabledLists(_lists);
      await ShieldChannel.loadFilterLists(paths);
      await ref.read(appSettingsProvider.notifier).markFilterListsUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${paths.length} filter list(s) updated.'),
            backgroundColor: const Color(0xFF1E293B),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Filter Lists',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _updateSelected,
            icon: _isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.greenAccent,
                    ),
                  )
                : const Icon(Icons.update, size: 18, color: Colors.greenAccent),
            label: const Text(
              'Update',
              style: TextStyle(color: Colors.greenAccent, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Filter lists are downloaded at runtime — they are not bundled in the app. '
              'Licenses apply to the content of the lists.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                // Default lists section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text(
                    'BUILT-IN LISTS',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                ...List.generate(_lists.length, (i) {
                  final list = _lists[i];
                  return Column(
                    children: [
                      _FilterListTile(
                        list: list,
                        onToggle: (v) => _onToggle(i, v),
                      ),
                      if (i < _lists.length - 1)
                        Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                    ],
                  );
                }),

                // Custom lists section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Row(
                    children: [
                      Text(
                        'CUSTOM LISTS',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _showAddCustomListDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF818CF8,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(
                                0xFF818CF8,
                              ).withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add,
                                size: 14,
                                color: Color(0xFF818CF8),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Add List',
                                style: TextStyle(
                                  color: Color(0xFF818CF8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Consumer(
                  builder: (context, ref, _) {
                    final settings = ref.watch(appSettingsProvider);
                    final customLists = settings.customFilterLists;
                    if (customLists.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        child: Text(
                          'No custom lists. Tap "Add List" to add a custom filter list URL (EasyList, AdGuard, etc.)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: List.generate(customLists.length, (i) {
                        final cl = customLists[i];
                        final asList = FilterList(
                          id: 'custom_$i',
                          name: cl['name'] ?? 'Custom List ${i + 1}',
                          url: cl['url'] ?? '',
                          description: cl['url'] ?? '',
                          license: 'Custom',
                          enabled: cl['enabled'] == true,
                        );
                        return Column(
                          children: [
                            _FilterListTile(
                              list: asList,
                              onToggle: (v) => _onToggleCustom(i, v),
                              onDelete: () => _deleteCustomList(i),
                            ),
                            if (i < customLists.length - 1)
                              Divider(
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                          ],
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onToggle(int i, bool v) {
    setState(() {
      _lists[i] = _lists[i].copyWith(enabled: v);
    });
    final disabled = _lists.where((l) => !l.enabled).map((l) => l.id).toList();
    final enabled = _lists.where((l) => l.enabled).map((l) => l.id).toList();
    ref
        .read(appSettingsProvider.notifier)
        .updateSettings(
          ref
              .read(appSettingsProvider)
              .copyWith(
                disabledFilterLists: disabled,
                enabledFilterLists: enabled,
              ),
        );
  }

  void _onToggleCustom(int i, bool v) {
    final settings = ref.read(appSettingsProvider);
    final customLists = List<Map<String, dynamic>>.from(
      settings.customFilterLists,
    );
    customLists[i] = {...customLists[i], 'enabled': v};
    ref
        .read(appSettingsProvider.notifier)
        .updateSettings(settings.copyWith(customFilterLists: customLists));
  }

  void _deleteCustomList(int i) {
    final settings = ref.read(appSettingsProvider);
    final customLists = List<Map<String, dynamic>>.from(
      settings.customFilterLists,
    );
    customLists.removeAt(i);
    ref
        .read(appSettingsProvider.notifier)
        .updateSettings(settings.copyWith(customFilterLists: customLists));
  }

  void _showAddCustomListDialog() {
    final urlController = TextEditingController();
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add Custom Filter List',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'List name (e.g. AdGuard Base)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'https://example.com/list.txt',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
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
              final url = urlController.text.trim();
              final name = nameController.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(ctx);
                final settings = ref.read(appSettingsProvider);
                final customLists = List<Map<String, dynamic>>.from(
                  settings.customFilterLists,
                );
                customLists.add({
                  'name': name.isNotEmpty ? name : url,
                  'url': url,
                  'enabled': true,
                });
                ref
                    .read(appSettingsProvider.notifier)
                    .updateSettings(
                      settings.copyWith(customFilterLists: customLists),
                    );
              }
            },
            child: const Text(
              'Add',
              style: TextStyle(
                color: Color(0xFF818CF8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterListTile extends StatelessWidget {
  final FilterList list;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onDelete;

  const _FilterListTile({
    required this.list,
    required this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(
              list.name,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          if (onDelete != null)
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close, color: Colors.white30, size: 18),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            list.description,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            'License: ${list.license}',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
      value: list.enabled,
      onChanged: onToggle,
      activeThumbColor: Colors.greenAccent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF818CF8),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: activeColor,
      ),
    );
  }
}

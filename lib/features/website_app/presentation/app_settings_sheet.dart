import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../domain/web_app.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/presentation/app_settings_provider.dart';

class AppSettingsSheet extends ConsumerStatefulWidget {
  final WebApp app;
  final ValueChanged<WebApp> onUpdateApp;
  final VoidCallback onPinShortcut;
  final VoidCallback onClearData;
  final VoidCallback onUninstall;
  final VoidCallback onCustomize;

  const AppSettingsSheet({
    super.key,
    required this.app,
    required this.onUpdateApp,
    required this.onPinShortcut,
    required this.onClearData,
    required this.onUninstall,
    required this.onCustomize,
  });

  @override
  ConsumerState<AppSettingsSheet> createState() => _AppSettingsSheetState();
}

class _AppSettingsSheetState extends ConsumerState<AppSettingsSheet> {
  late TextEditingController _nameController;
  late WebApp _app;

  @override
  void initState() {
    super.initState();
    _app = widget.app;
    _nameController = TextEditingController(text: _app.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _update(WebApp updated) {
    setState(() {
      _app = updated;
    });
    widget.onUpdateApp(updated);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);

    final isJsActive = _app.jsEnabledOverride ?? settings.javascriptEnabled;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            const Text(
              'WebApp Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // App Name Textfield
            const Text(
              'App Name',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  hintText: 'Enter app name',
                  hintStyle: TextStyle(color: Colors.white30),
                ),
                onChanged: (v) {
                  _update(_app.copyWith(name: v));
                },
              ),
            ),
            const SizedBox(height: 20),

            // Settings toggles card
            const Text(
              'Local Configuration Overrides',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  _OverrideOptionSegmented(
                    label: '🛡️ WebFuseX Shield',
                    currentValue: _app.shieldEnabledOverride,
                    globalValue: settings.adBlockerEnabled,
                    onChanged: (v) => _update(_app.copyWith(shieldEnabledOverride: v)),
                  ),
                  const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
                  _OverrideOptionSegmented(
                    label: '🖥️ Desktop Mode',
                    currentValue: _app.desktopModeOverride,
                    globalValue: settings.defaultMode == AppDefaultMode.desktop,
                    onChanged: (v) => _update(_app.copyWith(desktopModeOverride: v)),
                  ),
                  const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
                  _OverrideOptionSegmented(
                    label: '⚡ JavaScript',
                    currentValue: _app.jsEnabledOverride,
                    globalValue: settings.javascriptEnabled,
                    onChanged: (v) => _update(_app.copyWith(jsEnabledOverride: v)),
                  ),
                  if (!isJsActive)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Warning: Disabling JavaScript may break websites, logins, and interactive features.',
                              style: TextStyle(color: Colors.orangeAccent.withValues(alpha: 0.8), fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
                  _OverrideOptionSegmented(
                    label: '🍪 Accept Cookies',
                    currentValue: _app.cookiesEnabledOverride,
                    globalValue: settings.cookiesEnabled,
                    onChanged: (v) => _update(_app.copyWith(cookiesEnabledOverride: v)),
                  ),
                  const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
                  _OverrideOptionSegmented(
                    label: '🍪 3rd-Party Cookies',
                    currentValue: _app.thirdPartyCookiesEnabledOverride,
                    globalValue: settings.thirdPartyCookiesEnabled,
                    onChanged: (v) => _update(_app.copyWith(thirdPartyCookiesEnabledOverride: v)),
                  ),
                  const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
                  _OverrideOptionSegmented(
                    label: '🔍 Pinch-to-Zoom',
                    currentValue: _app.pinchToZoomEnabledOverride,
                    globalValue: settings.pinchToZoomEnabled,
                    onChanged: (v) => _update(_app.copyWith(pinchToZoomEnabledOverride: v)),
                  ),
                  const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
                  _OverrideOptionSegmented(
                    label: '🖼️ Load Images',
                    currentValue: _app.loadImagesEnabledOverride,
                    globalValue: settings.loadImagesEnabled,
                    onChanged: (v) => _update(_app.copyWith(loadImagesEnabledOverride: v)),
                  ),
                  const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
                  _OverrideOptionSegmented(
                    label: '🔗 Open Links Externally',
                    currentValue: _app.openLinksExternallyOverride,
                    globalValue: settings.openLinksExternally,
                    onChanged: (v) => _update(_app.copyWith(openLinksExternallyOverride: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Restore to Default button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _update(_app.copyWith(
                    jsEnabledOverride: null,
                    cookiesEnabledOverride: null,
                    thirdPartyCookiesEnabledOverride: null,
                    desktopModeOverride: null,
                    shieldEnabledOverride: null,
                    autoRefreshEnabledOverride: null,
                    autoRefreshIntervalOverride: null,
                    pinchToZoomEnabledOverride: null,
                    openLinksExternallyOverride: null,
                    loadImagesEnabledOverride: null,
                  ));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All overrides restored to global defaults')),
                    );
                  }
                },
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: const Text('Restore to Default'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orangeAccent,
                  side: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Auto Refresh Overrides Card
            const Text(
              'Auto Refresh Override',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  _OverrideOptionSegmented(
                    label: '🔄 Auto Refresh',
                    currentValue: _app.autoRefreshEnabledOverride,
                    globalValue: settings.autoRefreshEnabled,
                    onChanged: (v) => _update(_app.copyWith(autoRefreshEnabledOverride: v)),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Refresh Interval', style: TextStyle(color: Colors.white, fontSize: 14)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 60,
                              height: 36,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: '${_app.autoRefreshIntervalOverride ?? settings.autoRefreshInterval}',
                                  hintStyle: const TextStyle(color: Colors.white30),
                                  contentPadding: EdgeInsets.zero,
                                  border: const OutlineInputBorder(),
                                ),
                                onSubmitted: (v) {
                                  final interval = int.tryParse(v);
                                  _update(_app.copyWith(autoRefreshIntervalOverride: interval));
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('seconds', style: TextStyle(color: Colors.white38, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            const Text(
              'Actions',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Share
            ListTile(
              leading: const Icon(
                Icons.share_rounded,
                color: Color(0xFF34D399),
              ),
              title: const Text(
                'Share App URL',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: Text(
                _app.url,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Share.share(_app.url, subject: _app.name);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF818CF8),
              ),
              title: const Text(
                'Customize App Identity',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: const Text(
                'Change name, short name, or icon',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              onTap: widget.onCustomize,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.add_to_home_screen,
                color: Colors.amberAccent,
              ),
              title: const Text(
                'Pin Shortcut to Home Screen',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: const Text(
                'Add launcher icon shortcut',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              onTap: widget.onPinShortcut,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.cleaning_services,
                color: Colors.blueAccent,
              ),
              title: const Text(
                'Clear Storage & Cookies',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: const Text(
                'Clear isolated cache data',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              onTap: widget.onClearData,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Uninstall App',
                style: TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
              subtitle: const Text(
                'Remove completely from library',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              onTap: widget.onUninstall,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _OverrideOptionSegmented extends StatelessWidget {
  final String label;
  final bool? currentValue;
  final bool globalValue;
  final ValueChanged<bool?> onChanged;

  const _OverrideOptionSegmented({
    required this.label,
    required this.currentValue,
    required this.globalValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool?>(
              style: SegmentedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white54,
                selectedForegroundColor: Colors.white,
                selectedBackgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              segments: [
                ButtonSegment<bool?>(
                  value: null,
                  label: FittedBox(child: Text('Inherit (${globalValue ? "On" : "Off"})')),
                ),
                const ButtonSegment<bool?>(
                  value: true,
                  label: FittedBox(child: Text('On')),
                ),
                const ButtonSegment<bool?>(
                  value: false,
                  label: FittedBox(child: Text('Off')),
                ),
              ],
              selected: {currentValue},
              onSelectionChanged: (set) {
                if (set.isNotEmpty) {
                  onChanged(set.first);
                }
              },
              showSelectedIcon: false,
            ),
          ),
        ],
      ),
    );
  }
}

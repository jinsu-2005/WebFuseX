import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../platform/metadata_fetcher.dart';
import '../../../platform/shortcut_channel.dart';
import '../../website_app/domain/web_app.dart';
import '../../website_app/presentation/web_app_provider.dart';
import 'package:go_router/go_router.dart';

// ─── State Machine ─────────────────────────────────────────────────────────────

enum _OnboardingStep { enterUrl, fetching, review, done }

// ─── Screen ────────────────────────────────────────────────────────────────────

/// The "Add Website" flow. Guides the user through:
///   1. Entering a URL
///   2. Fetching site metadata (title, favicon, theme color)
///   3. Reviewing + customizing the WebApp
///   4. Confirming installation
class AddWebsiteScreen extends ConsumerStatefulWidget {
  const AddWebsiteScreen({super.key});

  @override
  ConsumerState<AddWebsiteScreen> createState() => _AddWebsiteScreenState();
}

class _AddWebsiteScreenState extends ConsumerState<AddWebsiteScreen>
    with TickerProviderStateMixin {
  _OnboardingStep _step = _OnboardingStep.enterUrl;

  final _urlController = TextEditingController();
  final _urlFocusNode = FocusNode();

  WebsiteMetadata? _metadata;
  String? _fetchError;

  // Review form state
  late TextEditingController _nameController;
  bool _shieldEnabled = true;
  bool _desktopMode = false;
  bool _isIncognito = false;
  bool _pinShortcut = true;
  String _selectedCategory = '';
  
  String? _pendingIconPath;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    _nameController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─── Logic ───────────────────────────────────────────────────────────────────

  Future<void> _startFetch() async {
    final raw = _urlController.text.trim();
    if (raw.isEmpty) return;

    setState(() {
      _step = _OnboardingStep.fetching;
      _fetchError = null;
    });

    try {
      final meta = await MetadataFetcher.fetch(raw);
      setState(() {
        _metadata = meta;
        _nameController.text = meta.title.isNotEmpty ? meta.title : _hostLabel(meta.resolvedUrl);
        _step = _OnboardingStep.review;
      });
      _fadeCtrl
        ..reset()
        ..forward();
    } catch (e) {
      setState(() {
        _fetchError = 'Could not reach that website. Check the URL and try again.';
        _step = _OnboardingStep.enterUrl;
      });
    }
  }

  String _hostLabel(String url) {
    final host = Uri.tryParse(url)?.host ?? url;
    return host.replaceFirst(RegExp(r'^www\.'), '');
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 90,
    );
    if (xFile == null || !mounted) return;

    final docs = await getApplicationDocumentsDirectory();
    final iconsDir = Directory('${docs.path}/custom_icons');
    if (!await iconsDir.exists()) await iconsDir.create(recursive: true);
    final fileName = 'new_app_${DateTime.now().millisecondsSinceEpoch}.png';
    final dest = File('${iconsDir.path}/$fileName');
    await File(xFile.path).copy(dest.path);

    setState(() {
      _pendingIconPath = dest.path;
    });
  }

  void _resetIcon() {
    setState(() {
      _pendingIconPath = null;
    });
  }

  Future<void> _installApp() async {
    final meta = _metadata;
    if (meta == null) return;

    final app = WebApp(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: meta.resolvedUrl,
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : _hostLabel(meta.resolvedUrl),
      faviconUrl: meta.faviconUrl,
      customIconPath: _pendingIconPath ?? '',
      themeColorHex: meta.themeColorHex.isNotEmpty
          ? meta.themeColorHex
          : '#6366F1',
      shieldEnabled: _shieldEnabled,
      desktopMode: _desktopMode,
      isIncognito: _isIncognito,
      shortcutInstalled: _pinShortcut,
      category: _selectedCategory,
      lastUsed: DateTime.now(),
    );

    await ref.read(webAppNotifierProvider.notifier).addApp(app);

    if (_pinShortcut) {
      final status = await ShortcutChannel.pinShortcut(
        appId: app.id,
        appName: app.name,
        themeColor: app.themeColorHex,
        faviconUrl: app.faviconUrl,
      );

      if (status != 'SUCCESS') {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Shortcut Pinning Failed', style: TextStyle(color: Colors.white)),
              content: Text(
                _getShortcutErrorExplanation(status, app.name),
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK', style: TextStyle(color: Color(0xFF6366F1))),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pin request sent for "${app.name}". Check your launcher.'),
              backgroundColor: const Color(0xFF6366F1),
            ),
          );
        }
      }
    }

    if (mounted) {
      context.go('/');
    }
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

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _stepTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: _buildBody(),
        ),
      ),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case _OnboardingStep.enterUrl:
        return 'Add Website';
      case _OnboardingStep.fetching:
        return 'Fetching…';
      case _OnboardingStep.review:
        return 'Customize';
      case _OnboardingStep.done:
        return 'Done';
    }
  }

  Widget _buildBody() {
    switch (_step) {
      case _OnboardingStep.enterUrl:
      case _OnboardingStep.fetching:
        return _buildUrlStep();
      case _OnboardingStep.review:
        return _buildReviewStep();
      case _OnboardingStep.done:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 1: Enter URL ───────────────────────────────────────────────────────

  Widget _buildUrlStep() {
    final isFetching = _step == _OnboardingStep.fetching;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Enter the website address',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'WebFuseX will fetch the name, icon, and theme automatically.',
            style: TextStyle(color: Colors.white54, fontSize: 15),
          ),
          const SizedBox(height: 32),
          _UrlInputField(
            controller: _urlController,
            focusNode: _urlFocusNode,
            enabled: !isFetching,
            error: _fetchError,
            onSubmitted: _startFetch,
          ),
          const SizedBox(height: 16),
          if (_fetchError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _fetchError!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isFetching ? null : _startFetch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.5),
              ),
              child: isFetching
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Continue',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── Step 2: Review ──────────────────────────────────────────────────────────

  Widget _buildReviewStep() {
    final meta = _metadata!;
    final themeColor = _parseColor(meta.themeColorHex);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Identity Card
          _AppIdentityCard(
            metadata: meta,
            nameController: _nameController,
            themeColor: themeColor,
            pendingIconPath: _pendingIconPath,
            onPickIcon: _pickFromGallery,
            onResetIcon: _pendingIconPath != null ? _resetIcon : null,
          ),
          const SizedBox(height: 24),

          // Category selection
          const Text(
            'Category',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          _CategorySelector(
            selectedCategory: _selectedCategory,
            onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
          ),
          const SizedBox(height: 24),

          // Settings
          const Text(
            'App Settings',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            shieldEnabled: _shieldEnabled,
            desktopMode: _desktopMode,
            isIncognito: _isIncognito,
            pinShortcut: _pinShortcut,
            themeColor: themeColor,
            onShieldChanged: (v) => setState(() => _shieldEnabled = v),
            onDesktopModeChanged: (v) => setState(() => _desktopMode = v),
            onIncognitoChanged: (v) => setState(() => _isIncognito = v),
            onPinShortcutChanged: (v) => setState(() => _pinShortcut = v),
          ),
          const SizedBox(height: 32),

          // Install button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _installApp,
              icon: const Icon(Icons.add_to_home_screen),
              label: const Text(
                'Add to WebFuseX',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _UrlInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final String? error;
  final VoidCallback onSubmitted;

  const _UrlInputField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.error,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: error != null
              ? Colors.redAccent.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        autofocus: true,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.go,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'e.g. hianime.to or youtube.com',
          hintStyle: const TextStyle(color: Colors.white30, fontSize: 15),
          prefixIcon: const Icon(Icons.language, color: Colors.white38, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onSubmitted: (_) => onSubmitted(),
      ),
    );
  }
}

class _AppIdentityCard extends StatelessWidget {
  final WebsiteMetadata metadata;
  final TextEditingController nameController;
  final Color themeColor;
  final String? pendingIconPath;
  final VoidCallback onPickIcon;
  final VoidCallback? onResetIcon;

  const _AppIdentityCard({
    required this.metadata,
    required this.nameController,
    required this.themeColor,
    required this.pendingIconPath,
    required this.onPickIcon,
    this.onResetIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Favicon & Icon Controls
          Column(
            children: [
              _FaviconWidget(
                faviconUrl: metadata.faviconUrl,
                iconPath: pendingIconPath,
                themeColor: themeColor,
                size: 64,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onPickIcon,
                child: const Text('Change Icon', style: TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              if (onResetIcon != null) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onResetIcon,
                  child: const Text('Reset', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ),
              ],
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Editable name field
                TextField(
                  controller: nameController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: 'App Name',
                    hintStyle: TextStyle(color: Colors.white38),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metadata.resolvedUrl,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaviconWidget extends StatelessWidget {
  final String faviconUrl;
  final String? iconPath;
  final Color themeColor;
  final double size;

  const _FaviconWidget({
    required this.faviconUrl,
    this.iconPath,
    required this.themeColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _buildImage(),
      ),
    );
  }
  
  Widget _buildImage() {
    if (iconPath != null && iconPath!.isNotEmpty) {
      return Image.file(
        File(iconPath!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackIcon(size, themeColor),
      );
    }
    if (faviconUrl.isNotEmpty) {
      return Image.network(
        faviconUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackIcon(size, themeColor),
      );
    }
    return _fallbackIcon(size, themeColor);
  }

  Widget _fallbackIcon(double size, Color color) {
    return Icon(Icons.language, color: color, size: size * 0.5);
  }
}

class _SettingsCard extends StatelessWidget {
  final bool shieldEnabled;
  final bool desktopMode;
  final bool isIncognito;
  final bool pinShortcut;
  final Color themeColor;
  final ValueChanged<bool> onShieldChanged;
  final ValueChanged<bool> onDesktopModeChanged;
  final ValueChanged<bool> onIncognitoChanged;
  final ValueChanged<bool> onPinShortcutChanged;

  const _SettingsCard({
    required this.shieldEnabled,
    required this.desktopMode,
    required this.isIncognito,
    required this.pinShortcut,
    required this.themeColor,
    required this.onShieldChanged,
    required this.onDesktopModeChanged,
    required this.onIncognitoChanged,
    required this.onPinShortcutChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.security,
            iconColor: Colors.greenAccent,
            title: 'WebFuseX Shield',
            subtitle: 'Block ads and trackers',
            value: shieldEnabled,
            onChanged: onShieldChanged,
            activeColor: Colors.greenAccent,
            isFirst: true,
          ),
          _SettingsDivider(),
          _SettingsTile(
            icon: Icons.desktop_windows_outlined,
            iconColor: Colors.blueAccent,
            title: 'Desktop Mode',
            subtitle: 'Request the desktop version',
            value: desktopMode,
            onChanged: onDesktopModeChanged,
            activeColor: themeColor,
          ),
          _SettingsDivider(),
          _SettingsTile(
            icon: Icons.visibility_off_outlined,
            iconColor: Colors.purpleAccent,
            title: 'Incognito',
            subtitle: 'Clear storage when closed',
            value: isIncognito,
            onChanged: onIncognitoChanged,
            activeColor: Colors.purpleAccent,
          ),
          _SettingsDivider(),
          _SettingsTile(
            icon: Icons.add_to_home_screen_outlined,
            iconColor: Colors.amberAccent,
            title: 'Pin to Home Screen',
            subtitle: 'Add application icon to launcher',
            value: pinShortcut,
            onChanged: onPinShortcutChanged,
            activeColor: Colors.amberAccent,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final bool isFirst;
  final bool isLast;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.activeColor,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? 4 : 0,
        bottom: isLast ? 4 : 0,
      ),
      child: SwitchListTile(
        secondary: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
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
        value: value,
        onChanged: onChanged,
        activeThumbColor: activeColor,
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 64,
      endIndent: 16,
      color: Colors.white.withValues(alpha: 0.06),
    );
  }
}

// ─── Utilities ───────────────────────────────────────────────────────────────

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

class _CategorySelector extends ConsumerWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const _CategorySelector({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(webAppNotifierProvider).sortedCategories;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCategory.isEmpty ? null : selectedCategory,
          hint: const Text('Select a Category (Optional)', style: TextStyle(color: Colors.white54)),
          isExpanded: true,
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text('None', style: TextStyle(color: Colors.white)),
            ),
            ...categories.map((cat) {
              return DropdownMenuItem<String>(
                value: cat.name,
                child: Text('${cat.emoji} ${cat.name}', style: const TextStyle(color: Colors.white)),
              );
            }),
          ],
          onChanged: (val) {
            if (val != null) onCategorySelected(val);
          },
        ),
      ),
    );
  }
}

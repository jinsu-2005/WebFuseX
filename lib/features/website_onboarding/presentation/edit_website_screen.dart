import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../website_app/domain/web_app.dart';
import '../../website_app/presentation/web_app_provider.dart';

/// Full-page screen for customizing a website app's display properties:
/// - Custom display name (shown in session header and settings)
/// - Custom short name (shown on library app cards)
/// - Custom icon (picked from gallery or reset to original favicon)
class EditWebsiteScreen extends ConsumerStatefulWidget {
  final WebApp app;

  const EditWebsiteScreen({super.key, required this.app});

  @override
  ConsumerState<EditWebsiteScreen> createState() => _EditWebsiteScreenState();
}

class _EditWebsiteScreenState extends ConsumerState<EditWebsiteScreen> {
  late final TextEditingController _displayNameCtrl;

  String? _pendingIconPath; // newly picked, not yet saved
  bool _iconRemoved = false; // user pressed "Reset to original"
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final app = widget.app;
    _displayNameCtrl = TextEditingController(
      text: app.customDisplayName.isNotEmpty ? app.customDisplayName : app.name,
    );
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    super.dispose();
  }

  String get _effectiveIconPath {
    if (_iconRemoved) return '';
    return _pendingIconPath ?? widget.app.customIconPath;
  }

  String get _effectiveFaviconUrl => widget.app.faviconUrl;

  // â”€â”€â”€ Icon picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 90,
    );
    if (xFile == null || !mounted) return;

    // Copy to app private storage so the path remains stable
    final destPath = await _copyToPrivate(xFile.path);
    setState(() {
      _pendingIconPath = destPath;
      _iconRemoved = false;
    });
  }

  Future<String> _copyToPrivate(String sourcePath) async {
    final docs = await getApplicationDocumentsDirectory();
    final iconsDir = Directory('${docs.path}/custom_icons');
    if (!await iconsDir.exists()) await iconsDir.create(recursive: true);
    final fileName =
        '${widget.app.id}_${DateTime.now().millisecondsSinceEpoch}.png';
    final dest = File('${iconsDir.path}/$fileName');
    await File(sourcePath).copy(dest.path);
    return dest.path;
  }

  void _resetIcon() {
    setState(() {
      _pendingIconPath = null;
      _iconRemoved = true;
    });
  }

  // â”€â”€â”€ Save â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final displayName = _displayNameCtrl.text.trim();

    final updated = widget.app.copyWith(
      customDisplayName: displayName == widget.app.name ? '' : displayName,
      customIconPath: _effectiveIconPath,
    );

    await ref.read(webAppNotifierProvider.notifier).updateApp(updated);

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop(updated);
    }
  }

  // â”€â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final themeColor = _parseColor(widget.app.themeColorHex);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Customize App',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF818CF8),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Color(0xFF818CF8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // â”€â”€ Icon preview & picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Center(
              child: Column(
                children: [
                  _IconPreview(
                    iconPath: _effectiveIconPath,
                    faviconUrl: _effectiveFaviconUrl,
                    themeColor: themeColor,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _OutlineChip(
                        icon: Icons.photo_library_outlined,
                        label: 'Choose from Gallery',
                        onTap: _pickFromGallery,
                      ),
                      const SizedBox(width: 12),
                      if (widget.app.customIconPath.isNotEmpty ||
                          _pendingIconPath != null)
                        _OutlineChip(
                          icon: Icons.refresh_rounded,
                          label: 'Reset',
                          onTap: _resetIcon,
                          color: Colors.white38,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // â”€â”€ Display Name â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _FieldLabel('Display Name'),
            const SizedBox(height: 8),
            _StyledTextField(
              controller: _displayNameCtrl,
              hint: 'e.g. My YouTube',
              helperText: 'Shown in the session toolbar and settings.',
            ),
            const SizedBox(height: 24),

            // ——— Original info —————————————————————————————————————————
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.white38,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Original name: ${widget.app.name}\n${widget.app.url}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconPreview extends StatelessWidget {
  final String iconPath;
  final String faviconUrl;
  final Color themeColor;

  const _IconPreview({
    required this.iconPath,
    required this.faviconUrl,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeColor.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    // Custom file icon takes priority
    if (iconPath.isNotEmpty) {
      return Image.file(
        File(iconPath),
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }
    // Favicon URL
    if (faviconUrl.isNotEmpty) {
      return Image.network(
        faviconUrl,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Center(child: Icon(Icons.language, color: themeColor, size: 48));
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? helperText;
  final int? maxLength;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.helperText,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30),
          helperText: helperText,
          helperStyle: const TextStyle(color: Colors.white38, fontSize: 11),
          helperMaxLines: 2,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          counterStyle: const TextStyle(color: Colors.white38),
        ),
      ),
    );
  }
}

class _OutlineChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _OutlineChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF818CF8),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

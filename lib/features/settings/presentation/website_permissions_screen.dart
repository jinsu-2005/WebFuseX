import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'permissions_provider.dart';

class WebsitePermissionsScreen extends ConsumerWidget {
  const WebsitePermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionsProvider);
    final notifier = ref.read(permissionsProvider.notifier);

    final defaultSettings = permissions.defaultPermissions;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text('Website Permissions',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Manage default permissions and site-specific exceptions for camera, microphone, and location.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
              ),
            ),
            
            _SectionHeader('Default Permissions'),
            _PermissionListTile(
              icon: Icons.camera_alt_rounded,
              label: 'Camera',
              value: defaultSettings['Camera'] ?? PermissionState.prompt,
              onChanged: (v) => notifier.setDefaultPermission('Camera', v),
            ),
            _PermissionListTile(
              icon: Icons.mic_rounded,
              label: 'Microphone',
              value: defaultSettings['Microphone'] ?? PermissionState.prompt,
              onChanged: (v) => notifier.setDefaultPermission('Microphone', v),
            ),
            _PermissionListTile(
              icon: Icons.location_on_rounded,
              label: 'Location',
              value: defaultSettings['Location'] ?? PermissionState.prompt,
              onChanged: (v) => notifier.setDefaultPermission('Location', v),
            ),
            _PermissionListTile(
              icon: Icons.notifications_rounded,
              label: 'Notifications',
              value: defaultSettings['Notifications'] ?? PermissionState.prompt,
              onChanged: (v) => notifier.setDefaultPermission('Notifications', v),
            ),
            _PermissionListTile(
              icon: Icons.storage_rounded,
              label: 'Storage',
              value: defaultSettings['Storage'] ?? PermissionState.prompt,
              onChanged: (v) => notifier.setDefaultPermission('Storage', v),
            ),

            if (permissions.sitePermissions.isNotEmpty) ...[
              _SectionHeader('Site Exceptions'),
              ...permissions.sitePermissions.entries.map((siteEntry) {
                final origin = siteEntry.key;
                final perms = siteEntry.value;
                return Column(
                  children: perms.entries.map((permEntry) {
                    final resource = permEntry.key;
                    final state = permEntry.value;
                    return ListTile(
                      leading: Icon(_getIcon(resource), color: const Color(0xFF818CF8)),
                      title: Text(origin, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: Text(resource, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      trailing: DropdownButton<PermissionState>(
                        value: state,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: PermissionState.granted, child: Text('Allow')),
                          DropdownMenuItem(value: PermissionState.denied, child: Text('Deny')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            notifier.setSitePermission(origin, resource, v);
                          }
                        },
                      ),
                      onLongPress: () {
                        // Option to clear the specific site exception
                        notifier.removeSitePermission(origin, resource);
                      },
                    );
                  }).toList(),
                );
              }),
            ]
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String resource) {
    switch (resource) {
      case 'Camera': return Icons.camera_alt_rounded;
      case 'Microphone': return Icons.mic_rounded;
      case 'Location': return Icons.location_on_rounded;
      case 'Notifications': return Icons.notifications_rounded;
      case 'Storage': return Icons.storage_rounded;
      default: return Icons.security;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF818CF8),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _PermissionListTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final PermissionState value;
  final ValueChanged<PermissionState> onChanged;

  const _PermissionListTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF818CF8).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF818CF8), size: 20),
      ),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: DropdownButton<PermissionState>(
        value: value,
        dropdownColor: const Color(0xFF1E293B),
        style: const TextStyle(color: Colors.white70, fontSize: 13),
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: PermissionState.prompt, child: Text('Ask First')),
          DropdownMenuItem(value: PermissionState.granted, child: Text('Allow All')),
          DropdownMenuItem(value: PermissionState.denied, child: Text('Block All')),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

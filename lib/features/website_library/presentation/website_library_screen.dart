import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../website_app/domain/web_app.dart';
import '../../website_app/presentation/web_app_provider.dart';
import '../../website_library/domain/web_app_folder.dart';
import '../../website_library/domain/web_app_category.dart';
import '../../../platform/shortcut_channel.dart';
import '../../website_onboarding/presentation/edit_website_screen.dart';
import '../../settings/presentation/advanced_settings_screen.dart';
import '../../website_app/presentation/app_settings_sheet.dart';
import 'default_library_provider.dart';
import '../domain/library_models.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../platform/web_engine_channel.dart';

/// The WebFuseX home screen -- a Website Library.
///
/// Features:
///   - "Add Website" button at the TOP of the My Apps section
///   - Drag-and-drop reordering within sections
///   - Folder grouping with drag-to-folder support
///   - Category labels on apps
///   - Custom short name on app cards
///   - Custom icon from user gallery
///   - Settings icon in header
class WebsiteLibraryScreen extends ConsumerStatefulWidget {
  const WebsiteLibraryScreen({super.key});

  @override
  ConsumerState<WebsiteLibraryScreen> createState() =>
      _WebsiteLibraryScreenState();
}

class _WebsiteLibraryScreenState extends ConsumerState<WebsiteLibraryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryName;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Launch ---

  void _launchApp(WebApp app) {
    ref.read(webAppNotifierProvider.notifier).recordLaunch(app.id);
    context.push('/session/${app.id}');
  }

  // --- Long-press context menu ---

  void _showContextMenu(BuildContext context, WebApp app) {
    final folders = ref.read(webAppNotifierProvider).sortedFolders;
    final categories = ref.read(webAppNotifierProvider).sortedCategories;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AppContextMenu(
        app: app,
        folders: folders,
        categories: categories,
        onLaunch: () {
          Navigator.pop(context);
          _launchApp(app);
        },
        onToggleFavorite: () {
          Navigator.pop(context);
          ref.read(webAppNotifierProvider.notifier).toggleFavorite(app.id);
        },
        onEdit: () {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => EditWebsiteScreen(app: app)),
          );
        },
        onPinShortcut: () async {
          Navigator.pop(context);
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
                      'Pin request sent for "${app.name}". Check your launcher.'),
                  backgroundColor: const Color(0xFF6366F1),
                ),
              );
            }
          } else {
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text('Shortcut Pinning Failed',
                      style: TextStyle(color: Colors.white)),
                  content: Text(
                    _getShortcutErrorExplanation(status, app.name),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('OK',
                          style: TextStyle(color: Color(0xFF6366F1))),
                    ),
                  ],
                ),
              );
            }
          }
        },
        onMoveToFolder: (folderId) {
          Navigator.pop(context);
          if (folderId != null) {
            ref
                .read(webAppNotifierProvider.notifier)
                .moveAppToFolder(app.id, folderId);
          }
        },
        onSetCategory: (category) {
          Navigator.pop(context);
          if (category != null) {
            ref
                .read(webAppNotifierProvider.notifier)
                .setCategory(app.id, category);
          }
        },
        onLocalConfiguration: () {
          Navigator.pop(context);
          showModalBottomSheet(
            context: context,
            backgroundColor: const Color(0xFF0F172A),
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (ctx) => AppSettingsSheet(
              app: app,
              onUpdateApp: (updated) {
                ref.read(webAppNotifierProvider.notifier).updateApp(updated);
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
                  ref.read(webAppNotifierProvider.notifier).markShortcutInstalled(app.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Pin request sent for "${app.name}". Check your launcher.'),
                        backgroundColor: const Color(0xFF6366F1),
                      ),
                    );
                  }
                }
              },
              onClearData: () {
                Navigator.pop(ctx);
                WebEngineChannel.clearData(app.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Storage and cookies cleared for ${app.name}'),
                      backgroundColor: Colors.blueAccent,
                    ),
                  );
                }
              },
              onUninstall: () {
                Navigator.pop(ctx);
                _confirmDelete(app);
              },
              onCustomize: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => EditWebsiteScreen(app: app)),
                );
              },
            ),
          );
        },
        onShare: () {
          Navigator.pop(context);
          Share.share(app.url, subject: app.name);
        },
        onCopyUrl: () {
          Navigator.pop(context);
          Clipboard.setData(ClipboardData(text: app.url));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('URL copied to clipboard')),
            );
          }
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(app);
        },
      ),
    );
  }

  int _crossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 5;
    if (width > 700) return 4;
    return 3;
  }

  void _onCategorySelected(String? id) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return const _CategoryManagerSheet();
      },
    );
  }

  void _showCategoryManagerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return const _CategoryManagerSheet();
      },
    );
  }

  void _confirmDelete(WebApp app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove App', style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove "${app.name}" from WebFuseX? '
          'This will clear all its cookies and data.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(webAppNotifierProvider.notifier).removeApp(app.id);
            },
            child:
                const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // --- Folder management ---

  void _showCreateFolderDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Folder', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Folder name',
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                ref.read(webAppNotifierProvider.notifier).addFolder(name);
              }
            },
            child: const Text('Create',
                style: TextStyle(color: Color(0xFF818CF8))),
          ),
        ],
      ),
    );
  }

  void _showRenameFolderDialog(WebAppFolder folder) {
    final ctrl = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rename Folder',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                ref
                    .read(webAppNotifierProvider.notifier)
                    .renameFolder(folder.id, name);
              }
            },
            child: const Text('Save',
                style: TextStyle(color: Color(0xFF818CF8))),
          ),
        ],
      ),
    );
  }

  // --- Featured app install ---

  Future<void> _installFeaturedApp(WebApp app) async {
    final newApp = app.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      shortcutInstalled: true,
    );

    await ref.read(webAppNotifierProvider.notifier).addApp(newApp);

    final status = await ShortcutChannel.pinShortcut(
      appId: newApp.id,
      appName: newApp.name,
      themeColor: newApp.themeColorHex,
      faviconUrl: newApp.faviconUrl,
    );

    if (mounted) {
      if (status == 'SUCCESS') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Installed "${newApp.name}" and pinned to home screen.'),
            backgroundColor: const Color(0xFF6366F1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Installed "${newApp.name}", but shortcut pinning failed.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    }
  }

  // --- Helper: build default library slivers ---
  List<Widget> _buildDefaultLibrarySlivers(
    List<LibraryAppRuntime> libraryApps,
    List<LibraryCategoryConfig> defaultCategories,
  ) {
    final slivers = <Widget>[];

    for (final category in defaultCategories) {
      final appsInCategory = libraryApps
          .where((app) => app.config.categoryId == category.id)
          .toList();

      if (appsInCategory.isNotEmpty) {
        // Category header — a SliverToBoxAdapter
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                category.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );

        // Grid of apps — a SliverPadding wrapping a SliverGrid
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _crossAxisCount(context),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final appRuntime = appsInCategory[i];
                  return _LibraryAppCard(
                    appRuntime: appRuntime,
                    onInstall: () async {
                      final name = appRuntime.config.nameOverride ?? appRuntime.metadata.title;
                      final favicon = appRuntime.config.faviconOverride ?? appRuntime.metadata.faviconUrl;
                      final newApp = WebApp(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        url: appRuntime.metadata.resolvedUrl,
                        name: name,
                        faviconUrl: favicon,
                        themeColorHex: appRuntime.metadata.themeColorHex,
                        shortcutInstalled: true,
                        lastUsed: DateTime.now(),
                        category: appRuntime.config.categoryId,
                      );
                      await ref.read(webAppNotifierProvider.notifier).addApp(newApp);
                      
                      final status = await ShortcutChannel.pinShortcut(
                        appId: newApp.id,
                        appName: newApp.name,
                        themeColor: newApp.themeColorHex,
                        faviconUrl: newApp.faviconUrl,
                      );
                      
                      if (context.mounted) {
                        if (status == 'SUCCESS') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              elevation: 0,
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.transparent,
                              content: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                    ),
                                    child: Text(
                                      'Installed "${newApp.name}" and pinned to home screen.',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              elevation: 0,
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.transparent,
                              content: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      'Installed "${newApp.name}", but shortcut pinning failed.',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    onLaunch: () {
                      context.push('/session/temp_${appRuntime.config.id}', extra: appRuntime.metadata.resolvedUrl);
                    },
                  );
                },
                childCount: appsInCategory.length,
              ),
            ),
          ),
        );
      }
    }

    return slivers;
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(webAppNotifierProvider);
    final defaultLibraryAsync = ref.watch(defaultLibraryProvider);
    final defaultCategories = ref.watch(defaultLibraryCategoriesProvider);

    final allApps = libraryState.apps;
    final favorites = _selectedCategoryName == null ? libraryState.favorites : <WebApp>[];
    final recentlyUsed = _selectedCategoryName == null ? libraryState.recentlyUsed : <WebApp>[];
    final folders = _selectedCategoryName == null ? libraryState.sortedFolders : <WebAppFolder>[];
    final rootApps = _selectedCategoryName == null
        ? libraryState.rootApps
        : libraryState.apps.where((a) => a.category == _selectedCategoryName).toList();

    final displayedApps = _searchQuery.isEmpty
        ? allApps
        : allApps
            .where((a) =>
                (a.customDisplayName.isNotEmpty
                        ? a.customDisplayName
                        : a.name)
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                a.url
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF13111E),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // -- Header --
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'AppIcon.png',
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WebFuseX',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Your website apps',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Settings button
                          _IconBtn(
                            icon: Icons.tune_rounded,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AdvancedSettingsScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Add button (header)
                          _AddButton(
                            onTap: () => context.push('/add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SearchBar(
                        controller: _searchController,
                        onChanged: (q) =>
                            setState(() => _searchQuery = q),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Category Tab Bar Filter
              if (_searchQuery.isEmpty)
                SliverToBoxAdapter(
                  child: _CategoryTabBar(
                    categories: libraryState.sortedCategories,
                    selectedCategoryName: _selectedCategoryName,
                    onCategorySelected: (cat) => setState(() => _selectedCategoryName = cat),
                    onManageCategories: _showCategoryManagerDialog,
                  ),
                ),

              // -- Search mode --
              if (_searchQuery.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Text(
                      '${displayedApps.length} result${displayedApps.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: _AppGrid(
                    apps: displayedApps,
                    onTap: _launchApp,
                    onLongPress: (app) => _showContextMenu(context, app),
                  ),
                ),
              ]

              // -- Normal mode --
              else ...[
                // Empty state
                if (allApps.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: _EmptyState(onAdd: () => context.push('/add')),
                    ),
                  )
                else ...[
                  // Favorites
                  if (favorites.isNotEmpty) ...[
                    _SectionHeader(
                      icon: Icons.star_rounded,
                      label: 'Favorites',
                      iconColor: const Color(0xFFFBBF24),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 104,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: favorites.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, i) => _AppChip(
                            app: favorites[i],
                            onTap: () => _launchApp(favorites[i]),
                            onLongPress: () =>
                                _showContextMenu(context, favorites[i]),
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                        child: SizedBox(height: 8)),
                  ],

                  // Recently Used
                  if (recentlyUsed.isNotEmpty) ...[
                    _SectionHeader(
                      icon: Icons.history_rounded,
                      label: 'Recently Used',
                      iconColor: Colors.white38,
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: recentlyUsed.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, i) => _RecentChip(
                            app: recentlyUsed[i],
                            onTap: () => _launchApp(recentlyUsed[i]),
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                        child: SizedBox(height: 8)),
                  ],

                  // -- Folders --
                  ...folders.expand((folder) {
                    final folderApps =
                        libraryState.appsInFolder(folder.id);
                    return [
                      SliverToBoxAdapter(
                        child: _FolderHeader(
                          folder: folder,
                          appCount: folderApps.length,
                          onToggleExpand: () => ref
                              .read(webAppNotifierProvider.notifier)
                              .toggleFolderExpanded(folder.id),
                          onRename: () =>
                              _showRenameFolderDialog(folder),
                          onDelete: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E293B),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                title: const Text('Delete Folder?',
                                    style: TextStyle(color: Colors.white)),
                                content: const Text(
                                  'Apps inside this folder will be moved back to the main list.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel',
                                        style: TextStyle(
                                            color: Colors.white54)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      ref
                                          .read(webAppNotifierProvider
                                              .notifier)
                                          .removeFolder(folder.id);
                                    },
                                    child: const Text('Delete',
                                        style: TextStyle(
                                            color: Colors.redAccent)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      if (folder.isExpanded && folderApps.isNotEmpty)
                        SliverPadding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          sliver: _AppGrid(
                            apps: folderApps,
                            onTap: _launchApp,
                            onLongPress: (app) =>
                                _showContextMenu(context, app),
                          ),
                        ),
                    ];
                  }),

                  // My Apps section header with "Add" and "New Folder" at top
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(24, 20, 16, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.apps_rounded,
                              color: Color(0xFF818CF8), size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'MY APPS',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const Spacer(),
                          // New Folder button
                          TextButton.icon(
                            onPressed: _showCreateFolderDialog,
                            icon: const Icon(Icons.create_new_folder_outlined,
                                size: 16, color: Colors.white38),
                            label: const Text('New Folder',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 12)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // "Add Website" card at the top of the grid
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _AddWebsiteCard(
                          onTap: () => context.push('/add')),
                    ),
                  ),

                  // Root apps grid (drag-and-drop)
                  SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: _DraggableAppGrid(
                      apps: rootApps,
                      onTap: _launchApp,
                      onLongPress: (app) =>
                          _showContextMenu(context, app),
                      onReorder: (newOrder) => ref
                          .read(webAppNotifierProvider.notifier)
                          .reorderApps(newOrder),
                    ),
                  ),
                ],

                // Default Website Library Section
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  _SectionHeader(
                    icon: Icons.explore_rounded,
                    label: 'Default Library',
                    iconColor: const Color(0xFF34D399),
                  ),

                  // Categories render immediately
                  ..._buildDefaultLibrarySlivers(
                    defaultLibraryAsync, 
                    _selectedCategoryName == null
                      ? defaultCategories
                      : defaultCategories.where((dc) {
                          final selectedCatObj = libraryState.sortedCategories.firstWhere(
                            (c) => c.name == _selectedCategoryName, 
                            orElse: () => const WebAppCategory(id: '', name: '', emoji: '', sortOrder: 0)
                          );
                          return dc.id == selectedCatObj.id;
                        }).toList(),
                  ),

                  const SliverToBoxAdapter(
                      child: SizedBox(height: 80)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// --- Add Website Card (top of grid) ---

class _AddWebsiteCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddWebsiteCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Color(0xFF818CF8), size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Add Website',
              style: TextStyle(
                color: Color(0xFF818CF8),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Folder Header ---

class _FolderHeader extends StatelessWidget {
  final WebAppFolder folder;
  final int appCount;
  final VoidCallback onToggleExpand;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _FolderHeader({
    required this.folder,
    required this.appCount,
    required this.onToggleExpand,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: GestureDetector(
        onTap: onToggleExpand,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Icon(
                folder.isExpanded
                    ? Icons.folder_open_rounded
                    : Icons.folder_rounded,
                color: const Color(0xFFFBBF24),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  folder.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$appCount app${appCount == 1 ? '' : 's'}',
                style:
                    const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Icon(
                folder.isExpanded
                    ? Icons.expand_less
                    : Icons.expand_more,
                color: Colors.white38,
                size: 20,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz,
                    color: Colors.white38, size: 18),
                color: const Color(0xFF1E293B),
                onSelected: (value) {
                  if (value == 'rename') onRename();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Text('Rename',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Section Header ---

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Draggable App Grid ---

class _DraggableAppGrid extends StatelessWidget {
  final List<WebApp> apps;
  final ValueChanged<WebApp> onTap;
  final ValueChanged<WebApp> onLongPress;
  final ValueChanged<List<String>> onReorder;

  const _DraggableAppGrid({
    required this.apps,
    required this.onTap,
    required this.onLongPress,
    required this.onReorder,
  });

  int _crossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 5;
    if (width > 700) return 4;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final count = _crossAxisCount(context);
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.88,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) => LongPressDraggable<String>(
          data: apps[i].id,
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.85,
              child: SizedBox(
                width: (MediaQuery.of(context).size.width - 32 - (count - 1) * 12) / count,
                child: _AppCard(
                  app: apps[i],
                  onTap: () {},
                  onLongPress: () {},
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _AppCard(
              app: apps[i],
              onTap: () {},
              onLongPress: () {},
            ),
          ),
          onDragEnd: (_) {},
          child: DragTarget<String>(
            onAcceptWithDetails: (details) {
              final draggedId = details.data;
              if (draggedId == apps[i].id) return;
              final ids = apps.map((a) => a.id).toList();
              final fromIdx = ids.indexOf(draggedId);
              final toIdx = i;
              if (fromIdx == -1) return;
              ids.removeAt(fromIdx);
              ids.insert(toIdx, draggedId);
              onReorder(ids);
            },
            builder: (context, candidateData, rejectedData) {
              final isTarget = candidateData.isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: isTarget
                      ? Border.all(
                          color: const Color(0xFF818CF8),
                          width: 2,
                        )
                      : null,
                ),
                child: _AppCard(
                  app: apps[i],
                  onTap: () => onTap(apps[i]),
                  onLongPress: () => onLongPress(apps[i]),
                ),
              );
            },
          ),
        ),
        childCount: apps.length,
      ),
    );
  }
}

// --- (Non-draggable) App Grid -- used for search results ---

class _AppGrid extends StatelessWidget {
  final List<WebApp> apps;
  final ValueChanged<WebApp> onTap;
  final ValueChanged<WebApp> onLongPress;

  const _AppGrid({
    required this.apps,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount(context),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.88,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) => _AppCard(
          app: apps[i],
          onTap: () => onTap(apps[i]),
          onLongPress: () => onLongPress(apps[i]),
        ),
        childCount: apps.length,
      ),
    );
  }

  int _crossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 5;
    if (width > 700) return 4;
    return 3;
  }
}

// --- Featured App Tile ---

class _FeaturedAppTile extends StatelessWidget {
  final WebApp app;
  final VoidCallback onInstall;

  const _FeaturedAppTile({
    required this.app,
    required this.onInstall,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = _parseColor(app.themeColorHex);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: app.faviconUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      app.faviconUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.language, color: themeColor, size: 24),
                    ),
                  )
                : Icon(Icons.language, color: themeColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  Uri.tryParse(app.url)?.host.replaceFirst('www.', '') ??
                      app.url,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onInstall,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Install',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// --- App Card (My Apps) with three-dot menu ---

class _AppCard extends StatefulWidget {
  final WebApp app;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AppCard({
    required this.app,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<_AppCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final themeColor = _parseColor(widget.app.themeColorHex);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: widget.app.faviconUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              widget.app.faviconUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.language, color: themeColor, size: 24),
                            ),
                          )
                        : Icon(Icons.language, color: themeColor, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.app.customDisplayName.isNotEmpty
                        ? widget.app.customDisplayName
                        : (widget.app.customShortName.isNotEmpty
                            ? widget.app.customShortName
                            : widget.app.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              // Three-dot overflow menu button
              Positioned(
                top: -4,
                right: -4,
                child: GestureDetector(
                  onTap: widget.onLongPress,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.more_vert_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.3),
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

Color _parseColor(String? hexString) {
  if (hexString == null || hexString.isEmpty) return const Color(0xFF6366F1);
  try {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (e) {
    return const Color(0xFF6366F1);
  }
}

// --- Library App Card (Default Library) ---

class _LibraryAppCard extends StatelessWidget {
  final LibraryAppRuntime appRuntime;
  final VoidCallback onInstall;
  final VoidCallback onLaunch;

  const _LibraryAppCard({
    super.key,
    required this.appRuntime,
    required this.onInstall,
    required this.onLaunch,
  });

  void _promptInstall(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Install ${appRuntime.metadata.title}?', style: const TextStyle(color: Colors.white)),
        content: const Text('Do you want to install and pin this app to your home screen?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onInstall();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Install & Pin'),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new, color: Colors.white),
              title: const Text('Open', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                onLaunch();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_rounded, color: Colors.white),
              title: const Text('Install & Pin', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                onInstall();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('Share', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                Share.share(appRuntime.metadata.resolvedUrl, subject: appRuntime.metadata.title);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.white),
              title: const Text('Copy URL', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: appRuntime.metadata.resolvedUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL copied to clipboard')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_to_home_screen, color: Colors.white),
              title: const Text('Create Home Screen Shortcut', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                ShortcutChannel.pinShortcut(
                  appId: appRuntime.config.id,
                  appName: appRuntime.metadata.title,
                  themeColor: appRuntime.metadata.themeColorHex,
                  faviconUrl: appRuntime.metadata.faviconUrl,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _parseColor(appRuntime.metadata.themeColorHex);

    return GestureDetector(
      onTap: () => _promptInstall(context),
      onLongPress: () => _showContextMenu(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: appRuntime.config.isFeatured ? const Color(0xFFFBBF24).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.07),
                width: appRuntime.config.isFeatured ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: appRuntime.metadata.faviconUrl.isNotEmpty
                        ? Image.network(
                            appRuntime.metadata.faviconUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.language, color: themeColor, size: 24),
                          )
                        : Icon(Icons.language, color: themeColor, size: 24),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    appRuntime.metadata.title,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                if (appRuntime.config.badges.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: appRuntime.config.badges.map((badge) {
                      final isSubDub = badge.toLowerCase().contains('sub') || badge.toLowerCase().contains('dub');
                      final badgeColor = isSubDub ? Colors.blueAccent : themeColor;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          if (appRuntime.config.isFeatured)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFBBF24),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'FEATURED',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: appRuntime.config.isFeatured ? const SizedBox() : GestureDetector(
              onTap: () => _showContextMenu(context),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.more_vert_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- App Context Menu (My Apps -- full actions) ---

class _AppContextMenu extends StatelessWidget {
  final WebApp app;
  final List<WebAppFolder> folders;
  final List<WebAppCategory>? categories;
  final VoidCallback? onLaunch;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onEdit;
  final VoidCallback? onPinShortcut;
  final ValueChanged<String?>? onMoveToFolder;
  final ValueChanged<String?>? onSetCategory;
  final VoidCallback? onLocalConfiguration;
  final VoidCallback? onShare;
  final VoidCallback? onCopyUrl;
  final VoidCallback? onDelete;

  const _AppContextMenu({
    required this.app,
    required this.folders,
    this.categories,
    this.onLaunch,
    this.onToggleFavorite,
    this.onEdit,
    this.onPinShortcut,
    this.onMoveToFolder,
    this.onSetCategory,
    this.onLocalConfiguration,
    this.onShare,
    this.onCopyUrl,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // App info header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _parseColor(app.themeColorHex).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: app.faviconUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              app.faviconUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Icon(Icons.language, color: _parseColor(app.themeColorHex), size: 20),
                            ),
                          )
                        : Icon(Icons.language, color: _parseColor(app.themeColorHex), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.customDisplayName.isNotEmpty ? app.customDisplayName : app.name,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          Uri.tryParse(app.url)?.host ?? app.url,
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            // Open
            ListTile(
              leading: const Icon(Icons.open_in_new, color: Colors.white70),
              title: const Text('Open', style: TextStyle(color: Colors.white)),
              onTap: onLaunch,
            ),
            // Favorite / Unfavorite
            ListTile(
              leading: Icon(
                app.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                color: app.isFavorite ? const Color(0xFFFBBF24) : Colors.white70,
              ),
              title: Text(
                app.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: onToggleFavorite,
            ),
            const Divider(color: Colors.white12, height: 1, indent: 56),
            // Share
            ListTile(
              leading: const Icon(Icons.share_rounded, color: Colors.white70),
              title: const Text('Share', style: TextStyle(color: Colors.white)),
              onTap: onShare,
            ),
            // Copy URL
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: Colors.white70),
              title: const Text('Copy URL', style: TextStyle(color: Colors.white)),
              onTap: onCopyUrl,
            ),
            const Divider(color: Colors.white12, height: 1, indent: 56),
            // WebApp Settings (Local Configuration)
            ListTile(
              leading: const Icon(Icons.settings_rounded, color: Color(0xFF818CF8)),
              title: const Text('WebApp Settings', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Local overrides, auto-refresh, actions', style: TextStyle(color: Colors.white38, fontSize: 11)),
              onTap: onLocalConfiguration,
            ),
            // Customize
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.white70),
              title: const Text('Customize', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Change name, icon, short name', style: TextStyle(color: Colors.white38, fontSize: 11)),
              onTap: onEdit,
            ),
            // Pin Shortcut
            ListTile(
              leading: const Icon(Icons.add_to_home_screen, color: Colors.amberAccent),
              title: const Text('Pin to Home Screen', style: TextStyle(color: Colors.white)),
              onTap: onPinShortcut,
            ),
            const Divider(color: Colors.white12, height: 1, indent: 56),
            // Move to Folder
            if (folders.isNotEmpty)
              ExpansionTile(
                leading: const Icon(Icons.folder_rounded, color: Colors.white70),
                title: const Text('Move to Folder', style: TextStyle(color: Colors.white)),
                iconColor: Colors.white38,
                collapsedIconColor: Colors.white38,
                children: [
                  ListTile(
                    leading: const SizedBox(width: 24),
                    title: const Text('(No Folder / Root)', style: TextStyle(color: Colors.white54)),
                    onTap: () => onMoveToFolder?.call(''),
                  ),
                  ...folders.map((f) => ListTile(
                        leading: const SizedBox(width: 24),
                        title: Text(f.name, style: const TextStyle(color: Colors.white)),
                        trailing: app.folderId == f.id
                            ? const Icon(Icons.check, color: Color(0xFF818CF8), size: 18)
                            : null,
                        onTap: () => onMoveToFolder?.call(f.id),
                      )),
                ],
              ),
            // Set Category
            if (categories != null && categories!.isNotEmpty)
              ExpansionTile(
                leading: const Icon(Icons.label_rounded, color: Colors.white70),
                title: const Text('Set Category', style: TextStyle(color: Colors.white)),
                iconColor: Colors.white38,
                collapsedIconColor: Colors.white38,
                children: [
                  ListTile(
                    leading: const SizedBox(width: 24),
                    title: const Text('(No Category)', style: TextStyle(color: Colors.white54)),
                    onTap: () => onSetCategory?.call(''),
                  ),
                  ...categories!.map((c) => ListTile(
                        leading: SizedBox(width: 24, child: Text(c.emoji, style: const TextStyle(fontSize: 16))),
                        title: Text(c.name, style: const TextStyle(color: Colors.white)),
                        trailing: app.category == c.name
                            ? const Icon(Icons.check, color: Color(0xFF818CF8), size: 18)
                            : null,
                        onTap: () => onSetCategory?.call(c.name),
                      )),
                ],
              ),
            const Divider(color: Colors.white12, height: 1, indent: 56),
            // Delete
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Remove App', style: TextStyle(color: Colors.redAccent)),
              onTap: onDelete,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// --- Category Manager Sheet ---

class _CategoryManagerSheet extends StatelessWidget {
  const _CategoryManagerSheet();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Text('Category Manager'),
      ),
    );
  }
}

// --- Icon Button ---

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.white70),
      onPressed: onTap,
    );
  }
}

// --- Add Button ---

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add),
      label: const Text('Add'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF6366F1),
      ),
    );
  }
}

// --- Search Bar ---

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search...',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// --- Category Tab Bar ---

class _CategoryTabBar extends StatelessWidget {
  final List<WebAppCategory> categories;
  final String? selectedCategoryName;
  final ValueChanged<String?> onCategorySelected;
  final VoidCallback onManageCategories;

  const _CategoryTabBar({
    required this.categories,
    required this.selectedCategoryName,
    required this.onCategorySelected,
    required this.onManageCategories,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: selectedCategoryName == null,
            onSelected: (_) => onCategorySelected(null),
          ),
          ...categories.map((c) => Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: FilterChip(
              label: Text(c.name),
              selected: selectedCategoryName == c.name,
              onSelected: (_) => onCategorySelected(c.name),
            ),
          )),
        ],
      ),
    );
  }
}

// --- Empty State ---

class _EmptyState extends StatelessWidget {
  final VoidCallback? onAdd;

  const _EmptyState({this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 64, color: Colors.white38),
          const SizedBox(height: 16),
          const Text('No apps found', style: TextStyle(color: Colors.white70)),
          if (onAdd != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAdd,
              child: const Text('Add App'),
            ),
          ],
        ],
      ),
    );
  }
}

// --- App Chip (Favorites) ---

class _AppChip extends StatelessWidget {
  final WebApp app;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _AppChip({required this.app, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: ActionChip(
        onPressed: onTap ?? () {},
        label: Text(app.name, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
      ),
    );
  }
}

// --- Recent Chip ---

class _RecentChip extends StatelessWidget {
  final WebApp app;
  final VoidCallback? onTap;

  const _RecentChip({required this.app, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap ?? () {},
      label: Text(app.name, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.teal.withValues(alpha: 0.2),
    );
  }
}

String _getShortcutErrorExplanation(String status, String appName) {
  return 'Failed to pin $appName: $status';
}

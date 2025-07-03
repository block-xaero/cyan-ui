import 'package:cyan/theme/cyan_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './side_menu_item.dart';
import 'package:go_router/go_router.dart';

class CyanSideMenu extends ConsumerWidget {
  final String currentRoute;

  const CyanSideMenu({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Make side menu responsive to screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final sideMenuWidth =
        screenWidth > 1200 ? 280.0 : (screenWidth > 800 ? 240.0 : 200.0);

    return Container(
      width: sideMenuWidth,
      decoration: const BoxDecoration(
        color: CyanTheme.surface,
        border:
            Border(right: BorderSide(color: CyanTheme.background, width: 1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.hub_outlined,
                  size: 24,
                  color: CyanTheme.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'CYAN',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: CyanTheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontSize: 18,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: CyanTheme.background),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                SideMenuItem(
                  icon: Icons.home,
                  label: 'Home',
                  isActive: currentRoute.contains('/groups'),
                  onTap: () => context.go('/groups'),
                ),
                const SizedBox(height: 6),
                SideMenuItem(
                  icon: Icons.groups,
                  label: 'Groups',
                  isActive: currentRoute.contains('/groups'),
                  onTap: () => context.go('/groups'),
                ),
                const SizedBox(height: 6),
                SideMenuItem(
                  icon: Icons.chat_bubble_outline,
                  label: 'Recent Chats',
                  isActive: currentRoute.contains('/chat'),
                  onTap: () => context.go('/chat/ws_1'),
                ),
                const SizedBox(height: 6),
                SideMenuItem(
                  icon: Icons.camera_alt,
                  label: 'AI Digitize',
                  isActive: currentRoute.contains('/digitize'),
                  onTap: () => context.go('/digitize'),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'RECENT WORKSPACES',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: CyanTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          fontSize: 10,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                SideMenuItem(
                  icon: Icons.dashboard,
                  label: 'Q3 Sprint Planning',
                  isActive: false,
                  onTap: () => context.go('/workspace/ws_1/objects'),
                ),
                const SizedBox(height: 4),
                SideMenuItem(
                  icon: Icons.architecture,
                  label: 'System Architecture',
                  isActive: false,
                  onTap: () => context.go('/workspace/ws_2/objects'),
                ),
                const SizedBox(height: 4),
                SideMenuItem(
                  icon: Icons.people,
                  label: 'User Research Findings',
                  isActive: false,
                  onTap: () => context.go('/workspace/ws_3/objects'),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Divider(color: CyanTheme.background),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: CyanTheme.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Flexible(
                      child: Text(
                        'P2P Connected',
                        style: TextStyle(
                          color: CyanTheme.secondary,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.security,
                        size: 10, color: CyanTheme.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Offline-first • Zero-knowledge',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: CyanTheme.textSecondary,
                              fontSize: 9,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cyan/notifiers/auth_notifier.dart';
import 'package:cyan/notifiers/groups_notifier.dart';
import 'package:cyan/theme/cyan_theme.dart';
import 'package:cyan/widgets/cyan_side_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GroupsPage extends ConsumerWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsUIProvider);
    final authState = ref.watch(authUIProvider);

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Conditional side menu for larger screens
            if (MediaQuery.of(context).size.width > 600)
              CyanSideMenu(currentRoute: '/groups'),

            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: CyanTheme.surface,
                      border: Border(
                          bottom: BorderSide(
                              color: CyanTheme.background, width: 1)),
                    ),
                    child: Row(
                      children: [
                        // Menu button for smaller screens
                        if (MediaQuery.of(context).size.width <= 600)
                          IconButton(
                            onPressed: () => Scaffold.of(context).openDrawer(),
                            icon: const Icon(Icons.menu),
                          ),
                        IconButton(
                          onPressed: () => context.go('/groups'),
                          icon: const Icon(Icons.home),
                          tooltip: 'Home',
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Groups',
                            style: Theme.of(context).textTheme.headlineSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.go('/digitize'),
                          icon: const Icon(Icons.camera_alt),
                          tooltip: 'AI Digitize',
                        ),
                        IconButton(
                          onPressed: () => context.go('/profile'),
                          icon: const Icon(Icons.account_circle),
                          tooltip: 'Profile & ZK Wallet',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, ${authState.user?.did.split(':').last ?? 'User'}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select a group to start collaborating with your team',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: CyanTheme.textSecondary,
                                    ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount =
                                  (constraints.maxWidth / 280)
                                      .floor()
                                      .clamp(1, 6);
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.85,
                                ),
                                itemCount: groups.length,
                                itemBuilder: (context, index) {
                                  final group = groups[index];
                                  return Card(
                                    elevation: 2,
                                    child: InkWell(
                                      onTap: () => context
                                          .go('/group/${group.id}/workspaces'),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: group.isPrivate
                                                        ? CyanTheme.warning
                                                            .withOpacity(0.2)
                                                        : CyanTheme.secondary
                                                            .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Icon(
                                                    group.isPrivate
                                                        ? Icons.lock
                                                        : Icons.public,
                                                    color: group.isPrivate
                                                        ? CyanTheme.warning
                                                        : CyanTheme.secondary,
                                                    size: 20,
                                                  ),
                                                ),
                                                const Spacer(),
                                                if (group.isAdmin)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: CyanTheme.primary
                                                          .withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: const Text(
                                                      'ADMIN',
                                                      style: TextStyle(
                                                        color:
                                                            CyanTheme.primary,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              group.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Expanded(
                                              child: Text(
                                                group.description,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: CyanTheme
                                                          .textSecondary,
                                                    ),
                                                maxLines: 4,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                const Icon(Icons.people,
                                                    size: 16,
                                                    color: CyanTheme
                                                        .textSecondary),
                                                const SizedBox(width: 4),
                                                const Text(
                                                  'P2P Team',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        CyanTheme.textSecondary,
                                                  ),
                                                ),
                                                const Spacer(),
                                                const Icon(Icons.chevron_right,
                                                    color: CyanTheme.primary),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Add drawer for mobile
      drawer: MediaQuery.of(context).size.width <= 600
          ? Drawer(
              child: CyanSideMenu(currentRoute: '/groups'),
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGroupDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Group'),
        backgroundColor: CyanTheme.primary,
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isPrivate = true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Group'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Group Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Private Group'),
                subtitle: const Text('Requires ZK proof for access'),
                value: isPrivate,
                onChanged: (value) => setState(() => isPrivate = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref.read(groupsUIProvider.notifier).createGroup(
                      nameController.text,
                      descController.text,
                      isPrivate,
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

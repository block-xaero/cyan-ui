import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../notifiers/workspaces_notifier.dart';
import '../widgets/cyan_side_menu.dart';
import '../theme/cyan_theme.dart';

class WorkspacesPage extends ConsumerWidget {
  final String groupId;

  const WorkspacesPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaces = ref.watch(workspacesUIProvider);

    ref.listen(workspacesUIProvider, (_, __) {
      ref.read(workspacesUIProvider.notifier).loadWorkspaces(groupId);
    });

    return Scaffold(
      body: Row(
        children: [
          CyanSideMenu(currentRoute: '/group/$groupId/workspaces'),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: CyanTheme.surface,
                    border: Border(
                        bottom:
                            BorderSide(color: CyanTheme.background, width: 1)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/groups'),
                        icon: const Icon(Icons.home),
                        tooltip: 'Home',
                      ),
                      IconButton(
                        onPressed: () => context.go('/groups'),
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Back to Groups',
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Workspaces',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => context.go('/digitize'),
                        icon: const Icon(Icons.camera_alt),
                        tooltip: 'AI Digitize',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Team Workspaces',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Collaborative spaces for your projects and initiatives',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: CyanTheme.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: 32),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = (constraints.maxWidth / 280)
                                .floor()
                                .clamp(2, 5);
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.9,
                              ),
                              itemCount: workspaces.length,
                              itemBuilder: (context, index) {
                                final workspace = workspaces[index];
                                return Card(
                                  elevation: 2,
                                  child: InkWell(
                                    onTap: () => context.go(
                                        '/workspace/${workspace.id}/objects'),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: CyanTheme.primary
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.dashboard,
                                                  color: CyanTheme.primary,
                                                  size: 24,
                                                ),
                                              ),
                                              const Spacer(),
                                              IconButton(
                                                onPressed: () => context.go(
                                                    '/chat/${workspace.id}'),
                                                icon: const Icon(Icons.chat,
                                                    size: 20),
                                                tooltip: 'Open Chat',
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            workspace.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Expanded(
                                            child: Text(
                                              workspace.description,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        CyanTheme.textSecondary,
                                                  ),
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time,
                                                  size: 14,
                                                  color:
                                                      CyanTheme.textSecondary),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Updated ${workspace.lastActivity}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      CyanTheme.textSecondary,
                                                ),
                                              ),
                                              const Spacer(),
                                              const Icon(Icons.chevron_right,
                                                  color: CyanTheme.primary,
                                                  size: 16),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateWorkspaceDialog(context, ref, groupId),
        icon: const Icon(Icons.add),
        label: const Text('New Workspace'),
        backgroundColor: CyanTheme.primary,
      ),
    );
  }

  void _showCreateWorkspaceDialog(
      BuildContext context, WidgetRef ref, String groupId) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Workspace'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Workspace Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref.read(workspacesUIProvider.notifier).createWorkspace(
                      groupId,
                      nameController.text,
                      descController.text,
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

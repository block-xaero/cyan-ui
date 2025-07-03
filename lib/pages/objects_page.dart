import 'dart:typed_data';

import 'package:cyan/events/cyan_event.dart';
import 'package:cyan/notifiers/objects_notifier.dart';
import 'package:cyan/services/cyan_event_bus.dart';
import 'package:cyan/theme/cyan_theme.dart';
import 'package:cyan/widgets/cyan_side_menu.dart';
import 'package:cyan/widgets/whiteboard_preview_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ObjectsPage extends ConsumerWidget {
  final String workspaceId;

  const ObjectsPage({super.key, required this.workspaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final objects = ref.watch(objectsUIProvider);

    ref.listen(objectsUIProvider, (_, __) {
      ref.read(objectsUIProvider.notifier).loadObjects(workspaceId);
    });

    return Scaffold(
      body: Row(
        children: [
          CyanSideMenu(currentRoute: '/workspace/$workspaceId/objects'),
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
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/groups');
                          }
                        },
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Whiteboards',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _createNewWhiteboard(context, ref, workspaceId),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New Whiteboard'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CyanTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => context.go('/digitize'),
                        icon: const Icon(Icons.camera_alt),
                        tooltip: 'AI Digitize',
                      ),
                      IconButton(
                        onPressed: () => context.go('/chat/$workspaceId'),
                        icon: const Icon(Icons.chat),
                        tooltip: 'Open Chat',
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
                        Row(
                          children: [
                            const Icon(Icons.dashboard,
                                size: 28, color: CyanTheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              'Collaborative Whiteboards',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Real-time collaborative whiteboards with UML shapes, drawing tools, and team chat',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: CyanTheme.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: 32),

                        // Quick action buttons
                        Row(
                          children: [
                            Expanded(
                              child: Card(
                                child: InkWell(
                                  onTap: () => _createNewWhiteboard(
                                      context, ref, workspaceId),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: CyanTheme.primary
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.add,
                                              size: 32,
                                              color: CyanTheme.primary),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Create New Whiteboard',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Card(
                                child: InkWell(
                                  onTap: () => context.go('/digitize'),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: CyanTheme.secondary
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.camera_alt,
                                              size: 32,
                                              color: CyanTheme.secondary),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Digitize Photo',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        Text(
                          'Recent Whiteboards (${objects.length})',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),

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
                                childAspectRatio: 0.75,
                              ),
                              itemCount: objects.length,
                              itemBuilder: (context, index) {
                                final object = objects[index];
                                return Card(
                                  elevation: 3,
                                  child: InkWell(
                                    onTap: () =>
                                        context.go('/canvas/${object.id}'),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Whiteboard preview
                                          Container(
                                            width: double.infinity,
                                            height: 140,
                                            decoration: BoxDecoration(
                                              color: CyanTheme.background,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: CyanTheme.primary
                                                    .withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Stack(
                                              children: [
                                                // Whiteboard preview with mock content
                                                CustomPaint(
                                                  painter:
                                                      WhiteboardPreviewPainter(),
                                                  size: Size.infinite,
                                                ),
                                                // Overlay with whiteboard icon
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: CyanTheme
                                                          .background
                                                          .withOpacity(0.9),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: const Icon(
                                                      Icons.dashboard,
                                                      size: 16,
                                                      color: CyanTheme.primary,
                                                    ),
                                                  ),
                                                ),
                                                // Play/Open indicator
                                                Center(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    decoration: BoxDecoration(
                                                      color: CyanTheme.primary
                                                          .withOpacity(0.9),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: const Icon(
                                                      Icons.play_arrow,
                                                      size: 24,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 12),

                                          // Whiteboard info
                                          Text(
                                            object.name,
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

                                          // Collaboration indicators
                                          Row(
                                            children: [
                                              // Online users indicator
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: CyanTheme.secondary
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.people,
                                                        size: 12,
                                                        color: CyanTheme
                                                            .secondary),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${(index % 4) + 1}',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color:
                                                            CyanTheme.secondary,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Live indicator
                                              if (index < 3)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: CyanTheme.accent
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 6,
                                                        height: 6,
                                                        decoration:
                                                            const BoxDecoration(
                                                          color:
                                                              CyanTheme.accent,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      const Text(
                                                        'LIVE',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          color:
                                                              CyanTheme.accent,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),

                                          const Spacer(),
                                          const SizedBox(height: 12),

                                          // Last modified
                                          Row(
                                            children: [
                                              const Icon(Icons.schedule,
                                                  size: 14,
                                                  color:
                                                      CyanTheme.textSecondary),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  object.lastModified,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        CyanTheme.textSecondary,
                                                  ),
                                                ),
                                              ),
                                              const Icon(Icons.arrow_forward,
                                                  size: 14,
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
    );
  }

  void _createNewWhiteboard(
      BuildContext context, WidgetRef ref, String workspaceId) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.dashboard, color: CyanTheme.primary),
            const SizedBox(width: 8),
            const Text('Create New Whiteboard'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Whiteboard Name',
                hintText: 'e.g., System Architecture, Sprint Planning...',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CyanTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: CyanTheme.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your whiteboard will include drawing tools, UML shapes, real-time chat, and P2P collaboration.',
                      style: TextStyle(fontSize: 12, color: CyanTheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                // Create new whiteboard
                final whiteboardId =
                    'whiteboard_${DateTime.now().millisecondsSinceEpoch}';

                final payload = Uint8List.fromList([
                  ...workspaceId.codeUnits,
                  0,
                  ...name.codeUnits,
                ]);

                CyanEventBus().dispatch(CyanEvent(
                  type: CyanEventType.objectCreate,
                  id: 'create_whiteboard_$whiteboardId',
                  payload: payload,
                ));

                Navigator.pop(context);

                // Navigate directly to the new whiteboard
                context.go('/canvas/$whiteboardId');
              }
            },
            icon: const Icon(Icons.create, size: 18),
            label: const Text('Create & Open'),
          ),
        ],
      ),
    );
  }
}

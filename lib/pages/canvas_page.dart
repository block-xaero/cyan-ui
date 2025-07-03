import 'dart:math';
import 'dart:typed_data';

import 'package:cyan/events/cyan_event.dart';
import 'package:cyan/models/canvas_models.dart';
import 'package:cyan/services/cyan_event_bus.dart';
import 'package:cyan/theme/cyan_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../notifiers/canvas_notifier.dart';

class CanvasPage extends ConsumerStatefulWidget {
  final String objectId;

  const CanvasPage({super.key, required this.objectId});

  @override
  ConsumerState<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends ConsumerState<CanvasPage> {
  Offset? _lastPanPoint;
  List<Offset> _currentPath = [];
  Offset? _dragStart;
  Offset? _dragCurrent;

  @override
  Widget build(BuildContext context) {
    final canvasState = ref.watch(canvasProvider(widget.objectId));
    final canvasNotifier = ref.read(canvasProvider(widget.objectId).notifier);

    return Scaffold(
      body: Column(
        children: [
          // Top Toolbar with Drawing Tools
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: CyanTheme.surface,
              border: Border(
                  bottom: BorderSide(color: CyanTheme.background, width: 1)),
            ),
            child: Row(
              children: [
                // Navigation
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
                  'Whiteboard',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 32),

                // Drawing Tools in Toolbar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _ToolbarButton(
                        icon: Icons.near_me,
                        isSelected:
                            canvasState.selectedTool == CanvasTool.select,
                        onPressed: () =>
                            canvasNotifier.selectTool(CanvasTool.select),
                        tooltip: 'Select',
                      ),
                      _ToolbarButton(
                        icon: Icons.edit,
                        isSelected: canvasState.selectedTool == CanvasTool.pen,
                        onPressed: () =>
                            canvasNotifier.selectTool(CanvasTool.pen),
                        tooltip: 'Pen',
                      ),
                      _ToolbarButton(
                        icon: Icons.crop_square,
                        isSelected:
                            canvasState.selectedTool == CanvasTool.rectangle,
                        onPressed: () =>
                            canvasNotifier.selectTool(CanvasTool.rectangle),
                        tooltip: 'Rectangle',
                      ),
                      _ToolbarButton(
                        icon: Icons.circle_outlined,
                        isSelected:
                            canvasState.selectedTool == CanvasTool.circle,
                        onPressed: () =>
                            canvasNotifier.selectTool(CanvasTool.circle),
                        tooltip: 'Circle',
                      ),
                      _ToolbarButton(
                        icon: Icons.arrow_forward,
                        isSelected:
                            canvasState.selectedTool == CanvasTool.arrow,
                        onPressed: () =>
                            canvasNotifier.selectTool(CanvasTool.arrow),
                        tooltip: 'Arrow',
                      ),
                      _ToolbarButton(
                        icon: Icons.text_fields,
                        isSelected: canvasState.selectedTool == CanvasTool.text,
                        onPressed: () =>
                            canvasNotifier.selectTool(CanvasTool.text),
                        tooltip: 'Text',
                      ),
                      _ToolbarButton(
                        icon: Icons.sticky_note_2,
                        isSelected:
                            canvasState.selectedTool == CanvasTool.sticky,
                        onPressed: () =>
                            canvasNotifier.selectTool(CanvasTool.sticky),
                        tooltip: 'Sticky Note',
                      ),

                      const SizedBox(width: 16),
                      Container(
                          width: 1, height: 24, color: CyanTheme.background),
                      const SizedBox(width: 16),

                      // UML Template Dropdown
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.account_tree,
                            color: CyanTheme.warning),
                        tooltip: 'UML Templates',
                        onSelected: (template) =>
                            _insertUMLTemplate(template, canvasNotifier),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'class',
                            child: Row(
                              children: [
                                Icon(Icons.class_,
                                    size: 16, color: CyanTheme.primary),
                                SizedBox(width: 8),
                                Text('Class Diagram'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'interface',
                            child: Row(
                              children: [
                                Icon(Icons.code,
                                    size: 16, color: CyanTheme.secondary),
                                SizedBox(width: 8),
                                Text('Interface'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'component',
                            child: Row(
                              children: [
                                Icon(Icons.widgets,
                                    size: 16, color: CyanTheme.warning),
                                SizedBox(width: 8),
                                Text('Component'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'actor',
                            child: Row(
                              children: [
                                Icon(Icons.person,
                                    size: 16, color: CyanTheme.accent),
                                SizedBox(width: 8),
                                Text('Actor'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'database',
                            child: Row(
                              children: [
                                Icon(Icons.storage,
                                    size: 16, color: CyanTheme.primary),
                                SizedBox(width: 8),
                                Text('Database'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'decision',
                            child: Row(
                              children: [
                                Icon(Icons.change_history,
                                    size: 16, color: CyanTheme.secondary),
                                SizedBox(width: 8),
                                Text('Decision Diamond'),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 16),
                      Container(
                          width: 1, height: 24, color: CyanTheme.background),
                      const SizedBox(width: 16),

                      // Color Palette in Toolbar
                      Row(
                        children: [
                          _ToolbarColorButton(
                            color: CyanTheme.primary,
                            isSelected:
                                canvasState.selectedColor == CyanTheme.primary,
                            onPressed: () =>
                                canvasNotifier.selectColor(CyanTheme.primary),
                          ),
                          _ToolbarColorButton(
                            color: CyanTheme.secondary,
                            isSelected: canvasState.selectedColor ==
                                CyanTheme.secondary,
                            onPressed: () =>
                                canvasNotifier.selectColor(CyanTheme.secondary),
                          ),
                          _ToolbarColorButton(
                            color: CyanTheme.warning,
                            isSelected:
                                canvasState.selectedColor == CyanTheme.warning,
                            onPressed: () =>
                                canvasNotifier.selectColor(CyanTheme.warning),
                          ),
                          _ToolbarColorButton(
                            color: CyanTheme.accent,
                            isSelected:
                                canvasState.selectedColor == CyanTheme.accent,
                            onPressed: () =>
                                canvasNotifier.selectColor(CyanTheme.accent),
                          ),
                          _ToolbarColorButton(
                            color: Colors.white,
                            isSelected:
                                canvasState.selectedColor == Colors.white,
                            onPressed: () =>
                                canvasNotifier.selectColor(Colors.white),
                          ),
                          _ToolbarColorButton(
                            color: Colors.black,
                            isSelected:
                                canvasState.selectedColor == Colors.black,
                            onPressed: () =>
                                canvasNotifier.selectColor(Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Action Buttons
                IconButton(
                  onPressed: () => canvasNotifier.undo(),
                  icon: const Icon(Icons.undo),
                  tooltip: 'Undo',
                ),
                IconButton(
                  onPressed: () => canvasNotifier.deleteSelectedObject(),
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete Selected',
                ),
                IconButton(
                  onPressed: () => canvasNotifier.toggleChat(),
                  icon: Icon(
                    canvasState.showChat
                        ? Icons.chat
                        : Icons.chat_bubble_outline,
                    color: canvasState.showChat ? CyanTheme.secondary : null,
                  ),
                  tooltip: 'Toggle Chat',
                ),
                IconButton(
                  onPressed: () => context.go('/digitize'),
                  icon: const Icon(Icons.camera_alt),
                  tooltip: 'AI Digitize',
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: Row(
              children: [
                // Left File Explorer
                Container(
                  width: 250,
                  decoration: const BoxDecoration(
                    color: CyanTheme.surface,
                    border:
                        Border(right: BorderSide(color: CyanTheme.background)),
                  ),
                  child: WhiteboardFileExplorer(workspaceId: widget.objectId),
                ),

                // Canvas Area
                Expanded(
                  child: Stack(
                    children: [
                      // Main Canvas
                      GestureDetector(
                        onTapDown: (details) =>
                            _handleTapDown(details, canvasNotifier),
                        onPanStart: (details) =>
                            _handlePanStart(details, canvasNotifier),
                        onPanUpdate: (details) =>
                            _handlePanUpdate(details, canvasNotifier),
                        onPanEnd: (details) =>
                            _handlePanEnd(details, canvasNotifier),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: CyanTheme.background,
                          child: CustomPaint(
                            painter: CanvasPainter(
                              objects: canvasState.objects,
                              selectedObject: canvasState.selectedObject,
                              peers: canvasState.peers,
                              zoomLevel: canvasState.zoomLevel,
                              panOffset: canvasState.panOffset,
                              currentPath: _currentPath,
                              currentTool: canvasState.selectedTool,
                              currentColor: canvasState.selectedColor,
                              dragStart: _dragStart,
                              dragCurrent: _dragCurrent,
                            ),
                          ),
                        ),
                      ),

                      // Zoom Controls
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: Card(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => canvasNotifier.zoom(-0.1),
                                icon: const Icon(Icons.zoom_out),
                              ),
                              Text('${(canvasState.zoomLevel * 100).round()}%'),
                              IconButton(
                                onPressed: () => canvasNotifier.zoom(0.1),
                                icon: const Icon(Icons.zoom_in),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Peer Indicators
                      Positioned(
                        top: 16,
                        right: canvasState.showChat ? 316 : 16,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people,
                                    size: 16, color: CyanTheme.secondary),
                                const SizedBox(width: 8),
                                ...canvasState.peers
                                    .take(3)
                                    .map((peer) => Padding(
                                          padding:
                                              const EdgeInsets.only(right: 4),
                                          child: CircleAvatar(
                                            radius: 12,
                                            backgroundColor: peer.color,
                                            child: Text(
                                              peer.name[0],
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        )),
                                if (canvasState.peers.length > 3)
                                  Text(
                                    '+${canvasState.peers.length - 3}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Chat Panel
                if (canvasState.showChat)
                  Container(
                    width: 300,
                    decoration: const BoxDecoration(
                      color: CyanTheme.surface,
                      border:
                          Border(left: BorderSide(color: CyanTheme.background)),
                    ),
                    child: CanvasChatPanel(
                        workspaceId: widget.objectId, peers: canvasState.peers),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleTapDown(TapDownDetails details, CanvasNotifier notifier) {
    final localPosition = details.localPosition;

    switch (notifier.state.selectedTool) {
      case CanvasTool.text:
        _showTextDialog(localPosition, notifier);
        break;
      case CanvasTool.sticky:
        _showStickyDialog(localPosition, notifier);
        break;
      case CanvasTool.select:
        // Find object at position and select it
        final selectedObject =
            _findObjectAtPosition(localPosition, notifier.state.objects);
        notifier.selectObject(selectedObject);
        break;
      default:
        break;
    }
  }

  void _handlePanStart(DragStartDetails details, CanvasNotifier notifier) {
    _lastPanPoint = details.localPosition;

    if (notifier.state.selectedTool == CanvasTool.pen) {
      _currentPath = [details.localPosition];
    } else if (_isShapeTool(notifier.state.selectedTool)) {
      _dragStart = details.localPosition;
      _dragCurrent = details.localPosition;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details, CanvasNotifier notifier) {
    final currentPoint = details.localPosition;

    switch (notifier.state.selectedTool) {
      case CanvasTool.pan:
        if (_lastPanPoint != null) {
          final delta = currentPoint - _lastPanPoint!;
          notifier.pan(delta);
        }
        break;

      case CanvasTool.pen:
        _currentPath.add(currentPoint);
        // Only rebuild when needed for smooth drawing
        if (_currentPath.length % 3 == 0) {
          setState(() {});
        }
        break;

      default:
        if (_isShapeTool(notifier.state.selectedTool)) {
          setState(() {
            _dragCurrent = currentPoint;
          });
        }
        break;
    }

    _lastPanPoint = currentPoint;
  }

  void _handlePanEnd(DragEndDetails details, CanvasNotifier notifier) {
    if (notifier.state.selectedTool == CanvasTool.pen &&
        _currentPath.isNotEmpty) {
      final penObject = CanvasObject(
        id: 'pen_${DateTime.now().millisecondsSinceEpoch}',
        type: CanvasObjectType.pen,
        position: _currentPath.first,
        color: notifier.state.selectedColor,
        strokeWidth: notifier.state.strokeWidth,
        path: List.from(_currentPath),
      );
      notifier.addObject(penObject);
      _currentPath.clear();
    } else if (_isShapeTool(notifier.state.selectedTool) &&
        _dragStart != null &&
        _dragCurrent != null) {
      _createShapeFromDrag(_dragStart!, _dragCurrent!, notifier);
    }

    setState(() {
      _dragStart = null;
      _dragCurrent = null;
    });
    _lastPanPoint = null;
  }

  bool _isShapeTool(CanvasTool tool) {
    return [
      CanvasTool.line,
      CanvasTool.rectangle,
      CanvasTool.circle,
      CanvasTool.arrow,
    ].contains(tool);
  }

  void _createShapeFromDrag(Offset start, Offset end, CanvasNotifier notifier) {
    final size = Size((end.dx - start.dx).abs(), (end.dy - start.dy).abs());
    final position = Offset(
      start.dx < end.dx ? start.dx : end.dx,
      start.dy < end.dy ? start.dy : end.dy,
    );

    switch (notifier.state.selectedTool) {
      case CanvasTool.line:
        notifier.addObject(CanvasObject(
          id: 'line_${DateTime.now().millisecondsSinceEpoch}',
          type: CanvasObjectType.line,
          position: start,
          size: Size(end.dx - start.dx, end.dy - start.dy),
          color: notifier.state.selectedColor,
          strokeWidth: notifier.state.strokeWidth,
        ));
        break;

      case CanvasTool.rectangle:
        notifier.addObject(CanvasObject(
          id: 'rect_${DateTime.now().millisecondsSinceEpoch}',
          type: CanvasObjectType.rectangle,
          position: position,
          size: size,
          color: notifier.state.selectedColor,
          strokeWidth: notifier.state.strokeWidth,
        ));
        break;

      case CanvasTool.circle:
        notifier.addObject(CanvasObject(
          id: 'circle_${DateTime.now().millisecondsSinceEpoch}',
          type: CanvasObjectType.circle,
          position: position,
          size: size,
          color: notifier.state.selectedColor,
          strokeWidth: notifier.state.strokeWidth,
        ));
        break;

      case CanvasTool.arrow:
        notifier.addObject(CanvasObject(
          id: 'arrow_${DateTime.now().millisecondsSinceEpoch}',
          type: CanvasObjectType.arrow,
          position: start,
          size: Size(end.dx - start.dx, end.dy - start.dy),
          color: notifier.state.selectedColor,
          strokeWidth: notifier.state.strokeWidth,
        ));
        break;

      default:
        break;
    }
  }

  void _insertUMLTemplate(String template, CanvasNotifier notifier) {
    final center = Offset(400, 300); // Center of typical canvas view

    switch (template) {
      case 'class':
        notifier.addObject(CanvasObject(
          id: 'class_${DateTime.now().millisecondsSinceEpoch}',
          type: CanvasObjectType.rectangle,
          position: center,
          size: const Size(150, 120),
          color: CyanTheme.primary,
          text: 'ClassName\n────────\n+ field: type\n+ method(): void',
          strokeWidth: 2.0,
        ));
        break;

      case 'interface':
        notifier.addObject(CanvasObject(
          id: 'interface_${DateTime.now().millisecondsSinceEpoch}',
          type: CanvasObjectType.rectangle,
          position: center,
          size: const Size(140, 100),
          color: CyanTheme.secondary,
          text: '<<interface>>\nIInterface\n────────\n+ method(): void',
          strokeWidth: 2.0,
        ));
        break;

      case 'component':
        notifier.addObject(CanvasObject(
          id: 'component_${DateTime.now().millisecondsSinceEpoch}',
          type: CanvasObjectType.rectangle,
          position: center,
          size: const Size(120, 80),
          color: CyanTheme.warning,
          text: '<<component>>\nService',
          strokeWidth: 2.0,
        ));
        break;

      case 'actor':
        notifier.addObject(CanvasObject(
          id: 'actor_${DateTime.now().millisecondsSinceEpoch}',
          type: CanvasObjectType.circle,
          position: center,
          size: const Size(60, 60),
          color: CyanTheme.accent,
          text: 'Actor',
          strokeWidth: 2.0,
        ));
        break;

      case 'database':
        notifier.addObject(CanvasObject(
          id: 'database_${DateTime.now().millisecondsSinceEpoch}',
          type: CanvasObjectType.circle,
          position: center,
          size: const Size(100, 80),
          color: CyanTheme.primary,
          text: 'Database',
          strokeWidth: 2.0,
        ));
        break;

      case 'decision':
        // Create diamond shape using rotated rectangle
        notifier.addObject(CanvasObject(
          id: 'decision_${DateTime.now().millisecondsSinceEpoch}',
          type: CanvasObjectType.rectangle,
          position: center,
          size: const Size(100, 60),
          color: CyanTheme.secondary,
          text: 'Decision?',
          strokeWidth: 2.0,
        ));
        break;
    }
  }

  CanvasObject? _findObjectAtPosition(
      Offset position, List<CanvasObject> objects) {
    // Find object at position (simplified hit testing)
    for (final object in objects.reversed) {
      final rect = Rect.fromLTWH(
        object.position.dx,
        object.position.dy,
        object.size.width,
        object.size.height,
      );
      if (rect.contains(position)) {
        return object;
      }
    }
    return null;
  }

  void _showTextDialog(Offset position, CanvasNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Text'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter text...'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  notifier.addObject(CanvasObject(
                    id: 'text_${DateTime.now().millisecondsSinceEpoch}',
                    type: CanvasObjectType.text,
                    position: position,
                    color: notifier.state.selectedColor,
                    text: controller.text,
                  ));
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showStickyDialog(Offset position, CanvasNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Sticky Note'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter note...'),
            maxLines: 3,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  notifier.addObject(CanvasObject(
                    id: 'sticky_${DateTime.now().millisecondsSinceEpoch}',
                    type: CanvasObjectType.sticky,
                    position: position,
                    size: const Size(120, 100),
                    color: notifier.state.selectedColor,
                    text: controller.text,
                  ));
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

class CanvasChatPanel extends ConsumerStatefulWidget {
  final String workspaceId;
  final List<PeerUser> peers;

  const CanvasChatPanel({
    super.key,
    required this.workspaceId,
    required this.peers,
  });

  @override
  ConsumerState<CanvasChatPanel> createState() => _CanvasChatPanelState();
}

class _CanvasChatPanelState extends ConsumerState<CanvasChatPanel> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'Alice Chen',
      'text': 'Great work on the architecture diagram!',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
      'isOwn': false,
      'color': CyanTheme.secondary,
    },
    {
      'sender': 'Bob Wilson',
      'text': 'Should we add more detail to the database layer?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 3)),
      'isOwn': false,
      'color': CyanTheme.warning,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: CyanTheme.background)),
          ),
          child: Row(
            children: [
              const Icon(Icons.chat, size: 20),
              const SizedBox(width: 8),
              const Text('Live Chat',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                '${widget.peers.where((p) => p.isOnline).length} online',
                style: const TextStyle(
                    fontSize: 12, color: CyanTheme.textSecondary),
              ),
            ],
          ),
        ),

        // Online Peers
        Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Online Now',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.peers.where((p) => p.isOnline).length,
                  itemBuilder: (context, index) {
                    final peer =
                        widget.peers.where((p) => p.isOnline).elementAt(index);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: peer.color,
                            child: Text(
                              peer.name[0],
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            peer.name.split(' ').first,
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: CyanTheme.background),

        // Messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return _CanvasChatMessage(
                sender: message['sender'],
                text: message['text'],
                timestamp: message['timestamp'],
                isOwn: message['isOwn'],
                color: message['color'],
              );
            },
          ),
        ),

        // Message Input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: CyanTheme.background)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onSubmitted: _sendMessage,
                ),
              ),
              IconButton(
                onPressed: () => _sendMessage(_messageController.text),
                icon:
                    const Icon(Icons.send, color: CyanTheme.primary, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final payload = Uint8List.fromList([
      ...widget.workspaceId.codeUnits,
      0,
      ...text.codeUnits,
    ]);

    CyanEventBus().dispatch(CyanEvent(
      type: CyanEventType.chatMessage,
      id: 'canvas_chat_${DateTime.now().millisecondsSinceEpoch}',
      payload: payload,
    ));

    setState(() {
      _messages.add({
        'sender': 'You',
        'text': text,
        'timestamp': DateTime.now(),
        'isOwn': true,
        'color': CyanTheme.primary,
      });
    });

    _messageController.clear();
  }
}

class _CanvasChatMessage extends StatelessWidget {
  final String sender;
  final String text;
  final DateTime timestamp;
  final bool isOwn;
  final Color color;

  const _CanvasChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.isOwn,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isOwn) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: color,
              child: Text(
                sender[0],
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isOwn)
                  Text(
                    sender,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isOwn ? CyanTheme.primary : CyanTheme.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isOwn ? Colors.white : CyanTheme.text,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: CyanTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isOwn) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 12,
              backgroundColor: color,
              child: const Text(
                'Y',
                style: TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// CANVAS HELPER WIDGETS
// ============================================================================

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isSelected;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor:
              isSelected ? CyanTheme.primary.withOpacity(0.2) : null,
          foregroundColor: isSelected ? CyanTheme.primary : CyanTheme.text,
          padding: const EdgeInsets.all(8),
        ),
      ),
    );
  }
}

class _ToolbarColorButton extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ToolbarColorButton({
    required this.color,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? CyanTheme.text : CyanTheme.textSecondary,
              width: isSelected ? 2 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

class WhiteboardFileExplorer extends StatelessWidget {
  final String workspaceId;

  const WhiteboardFileExplorer({super.key, required this.workspaceId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: CyanTheme.background)),
          ),
          child: Row(
            children: [
              const Icon(Icons.folder_open, size: 18, color: CyanTheme.primary),
              const SizedBox(width: 8),
              const Text(
                'Files & Objects',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16),
                tooltip: 'Add File',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              _FileItem(
                icon: Icons.dashboard,
                name: 'Current Whiteboard',
                isActive: true,
                onTap: () {},
              ),
              const SizedBox(height: 4),
              _FileItem(
                icon: Icons.image,
                name: 'Design Assets',
                isFolder: true,
                onTap: () {},
              ),
              _FileItem(
                icon: Icons.photo,
                name: 'logo-draft.png',
                size: '145 KB',
                indent: 16,
                onTap: () {},
              ),
              _FileItem(
                icon: Icons.photo,
                name: 'mockup-v2.jpg',
                size: '892 KB',
                indent: 16,
                onTap: () {},
              ),
              const SizedBox(height: 4),
              _FileItem(
                icon: Icons.description,
                name: 'Documents',
                isFolder: true,
                onTap: () {},
              ),
              _FileItem(
                icon: Icons.description,
                name: 'requirements.md',
                size: '12 KB',
                indent: 16,
                onTap: () {},
              ),
              _FileItem(
                icon: Icons.description,
                name: 'api-spec.json',
                size: '8 KB',
                indent: 16,
                onTap: () {},
              ),
              const SizedBox(height: 4),
              _FileItem(
                icon: Icons.sticky_note_2,
                name: 'Sticky Notes',
                isFolder: true,
                onTap: () {},
              ),
              _FileItem(
                icon: Icons.note,
                name: 'Meeting Notes',
                size: '2 KB',
                indent: 16,
                onTap: () {},
              ),
              _FileItem(
                icon: Icons.note,
                name: 'Action Items',
                size: '1 KB',
                indent: 16,
                onTap: () {},
              ),
              const SizedBox(height: 4),
              _FileItem(
                icon: Icons.link,
                name: 'References',
                isFolder: true,
                onTap: () {},
              ),
              _FileItem(
                icon: Icons.link,
                name: 'API Documentation',
                indent: 16,
                onTap: () {},
              ),
              _FileItem(
                icon: Icons.link,
                name: 'Design System',
                indent: 16,
                onTap: () {},
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: CyanTheme.background)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  const Text(
                    'Auto-saved 30s ago',
                    style: TextStyle(
                      color: CyanTheme.secondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'All changes sync to P2P network',
                style: TextStyle(
                  color: CyanTheme.textSecondary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FileItem extends StatelessWidget {
  final IconData icon;
  final String name;
  final String? size;
  final bool isFolder;
  final bool isActive;
  final double indent;
  final VoidCallback onTap;

  const _FileItem({
    required this.icon,
    required this.name,
    required this.onTap,
    this.size,
    this.isFolder = false,
    this.isActive = false,
    this.indent = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? CyanTheme.primary.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(4),
            border: isActive
                ? Border.all(color: CyanTheme.primary.withOpacity(0.3))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? CyanTheme.primary
                    : (isFolder ? CyanTheme.warning : CyanTheme.textSecondary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? CyanTheme.primary : CyanTheme.text,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (size != null)
                Text(
                  size!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: CyanTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CANVAS PAINTER
// ============================================================================

class CanvasPainter extends CustomPainter {
  final List<CanvasObject> objects;
  final CanvasObject? selectedObject;
  final List<PeerUser> peers;
  final double zoomLevel;
  final Offset panOffset;
  final List<Offset> currentPath;
  final CanvasTool currentTool;
  final Color currentColor;
  final Offset? dragStart;
  final Offset? dragCurrent;

  CanvasPainter({
    required this.objects,
    this.selectedObject,
    required this.peers,
    required this.zoomLevel,
    required this.panOffset,
    this.currentPath = const [],
    required this.currentTool,
    required this.currentColor,
    this.dragStart,
    this.dragCurrent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(zoomLevel);
    canvas.translate(panOffset.dx, panOffset.dy);

    // Draw objects
    for (final object in objects) {
      _drawObject(canvas, object);
    }

    // Draw current path (for live pen drawing)
    if (currentPath.isNotEmpty && currentTool == CanvasTool.pen) {
      _drawCurrentPath(canvas);
    }

    // Draw preview shape while dragging
    if (dragStart != null && dragCurrent != null) {
      _drawPreviewShape(canvas);
    }

    // Draw selection highlight
    if (selectedObject != null) {
      _drawSelection(canvas, selectedObject!);
    }

    // Draw peer cursors
    for (final peer in peers) {
      if (peer.isOnline && peer.cursorPosition != null) {
        _drawPeerCursor(canvas, peer);
      }
    }

    canvas.restore();
  }

  void _drawCurrentPath(Canvas canvas) {
    if (currentPath.length > 1) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      path.moveTo(currentPath.first.dx, currentPath.first.dy);
      for (int i = 1; i < currentPath.length; i++) {
        path.lineTo(currentPath[i].dx, currentPath[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawPreviewShape(Canvas canvas) {
    if (dragStart == null || dragCurrent == null) return;

    final paint = Paint()
      ..color = currentColor.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    switch (currentTool) {
      case CanvasTool.line:
        canvas.drawLine(dragStart!, dragCurrent!, paint);
        break;

      case CanvasTool.rectangle:
        final rect = Rect.fromPoints(dragStart!, dragCurrent!);
        canvas.drawRect(rect, paint);
        break;

      case CanvasTool.circle:
        final rect = Rect.fromPoints(dragStart!, dragCurrent!);
        canvas.drawOval(rect, paint);
        break;

      case CanvasTool.arrow:
        canvas.drawLine(dragStart!, dragCurrent!, paint);
        _drawArrowHead(canvas, dragStart!, dragCurrent!, paint);
        break;

      default:
        break;
    }
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end, Paint paint) {
    const arrowSize = 15.0;
    final direction = (end - start).direction;
    final arrowPath = Path();
    arrowPath.moveTo(end.dx, end.dy);
    arrowPath.lineTo(
      end.dx - arrowSize * cos(direction - 0.5),
      end.dy - arrowSize * sin(direction - 0.5),
    );
    arrowPath.lineTo(
      end.dx - arrowSize * cos(direction + 0.5),
      end.dy - arrowSize * sin(direction + 0.5),
    );
    arrowPath.close();

    canvas.drawPath(arrowPath, paint..style = PaintingStyle.fill);
  }

  void _drawObject(Canvas canvas, CanvasObject object) {
    final paint = Paint()
      ..color = object.color
      ..strokeWidth = object.strokeWidth
      ..style = PaintingStyle.stroke;

    switch (object.type) {
      case CanvasObjectType.pen:
        if (object.path != null && object.path!.length > 1) {
          final path = Path();
          path.moveTo(object.path!.first.dx, object.path!.first.dy);
          for (int i = 1; i < object.path!.length; i++) {
            path.lineTo(object.path![i].dx, object.path![i].dy);
          }
          canvas.drawPath(path, paint);
        }
        break;

      case CanvasObjectType.line:
        canvas.drawLine(
          object.position,
          object.position + Offset(object.size.width, object.size.height),
          paint,
        );
        break;

      case CanvasObjectType.rectangle:
        canvas.drawRect(
          Rect.fromLTWH(object.position.dx, object.position.dy,
              object.size.width, object.size.height),
          paint,
        );
        break;

      case CanvasObjectType.circle:
        canvas.drawOval(
          Rect.fromLTWH(object.position.dx, object.position.dy,
              object.size.width, object.size.height),
          paint,
        );
        break;

      case CanvasObjectType.arrow:
        _drawArrow(canvas, object, paint);
        break;

      case CanvasObjectType.text:
        _drawText(canvas, object);
        break;

      case CanvasObjectType.sticky:
        _drawSticky(canvas, object);
        break;
    }
  }

  void _drawArrow(Canvas canvas, CanvasObject object, Paint paint) {
    final start = object.position;
    final end = object.position + Offset(object.size.width, object.size.height);

    // Draw line
    canvas.drawLine(start, end, paint);

    // Draw arrowhead
    const arrowSize = 15.0;
    final direction = (end - start).direction;
    final arrowPath = Path();
    arrowPath.moveTo(end.dx, end.dy);
    arrowPath.lineTo(
      end.dx - arrowSize * cos(direction - 0.5),
      end.dy - arrowSize * sin(direction - 0.5),
    );
    arrowPath.lineTo(
      end.dx - arrowSize * cos(direction + 0.5),
      end.dy - arrowSize * sin(direction + 0.5),
    );
    arrowPath.close();

    canvas.drawPath(arrowPath, paint..style = PaintingStyle.fill);
  }

  void _drawText(Canvas canvas, CanvasObject object) {
    if (object.text != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: object.text!,
          style: TextStyle(
            color: object.color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
      );
      textPainter.layout(maxWidth: object.size.width - 16);

      // Center text in object bounds
      final textOffset = Offset(
        object.position.dx + (object.size.width - textPainter.width) / 2,
        object.position.dy + (object.size.height - textPainter.height) / 2,
      );
      textPainter.paint(canvas, textOffset);
    }
  }

  void _drawSticky(Canvas canvas, CanvasObject object) {
    // Draw sticky note background
    final rect = Rect.fromLTWH(object.position.dx, object.position.dy,
        object.size.width, object.size.height);
    final stickyPaint = Paint()
      ..color = object.color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      stickyPaint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = object.color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      borderPaint,
    );

    // Draw text
    if (object.text != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: object.text!,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 3,
      );
      textPainter.layout(maxWidth: object.size.width - 16);
      textPainter.paint(canvas, object.position + const Offset(8, 8));
    }
  }

  void _drawSelection(Canvas canvas, CanvasObject object) {
    final selectionPaint = Paint()
      ..color = CyanTheme.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(
      object.position.dx - 5,
      object.position.dy - 5,
      object.size.width + 10,
      object.size.height + 10,
    );

    canvas.drawRect(rect, selectionPaint);

    // Draw resize handles
    const handleSize = 8.0;
    final handlePaint = Paint()
      ..color = CyanTheme.primary
      ..style = PaintingStyle.fill;

    // Corner handles
    canvas.drawRect(
        Rect.fromCenter(
            center: rect.topLeft, width: handleSize, height: handleSize),
        handlePaint);
    canvas.drawRect(
        Rect.fromCenter(
            center: rect.topRight, width: handleSize, height: handleSize),
        handlePaint);
    canvas.drawRect(
        Rect.fromCenter(
            center: rect.bottomLeft, width: handleSize, height: handleSize),
        handlePaint);
    canvas.drawRect(
        Rect.fromCenter(
            center: rect.bottomRight, width: handleSize, height: handleSize),
        handlePaint);
  }

  void _drawPeerCursor(Canvas canvas, PeerUser peer) {
    if (peer.cursorPosition == null) return;

    final cursorPaint = Paint()
      ..color = peer.color
      ..style = PaintingStyle.fill;

    // Draw cursor
    final cursorPath = Path();
    cursorPath.moveTo(peer.cursorPosition!.dx, peer.cursorPosition!.dy);
    cursorPath.lineTo(peer.cursorPosition!.dx, peer.cursorPosition!.dy + 20);
    cursorPath.lineTo(
        peer.cursorPosition!.dx + 6, peer.cursorPosition!.dy + 14);
    cursorPath.lineTo(
        peer.cursorPosition!.dx + 12, peer.cursorPosition!.dy + 18);
    cursorPath.close();

    canvas.drawPath(cursorPath, cursorPaint);

    // Draw name label
    final textPainter = TextPainter(
      text: TextSpan(
        text: peer.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final labelRect = Rect.fromLTWH(
      peer.cursorPosition!.dx + 15,
      peer.cursorPosition!.dy - 5,
      textPainter.width + 8,
      textPainter.height + 4,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
      cursorPaint,
    );

    textPainter.paint(canvas, peer.cursorPosition! + const Offset(19, -3));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

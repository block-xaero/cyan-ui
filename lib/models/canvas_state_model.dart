import 'package:flutter/material.dart';
import '../theme/cyan_theme.dart';
import 'canvas_models.dart';

class CanvasState {
  final List<CanvasObject> objects;
  final CanvasTool selectedTool;
  final Color selectedColor;
  final double strokeWidth;
  final List<PeerUser> peers;
  final bool showChat;
  final double zoomLevel;
  final Offset panOffset;
  final CanvasObject? selectedObject;

  CanvasState({
    this.objects = const [],
    this.selectedTool = CanvasTool.pen,
    this.selectedColor = CyanTheme.primary,
    this.strokeWidth = 2.0,
    this.peers = const [],
    this.showChat = false,
    this.zoomLevel = 1.0,
    this.panOffset = Offset.zero,
    this.selectedObject,
  });

  CanvasState copyWith({
    List<CanvasObject>? objects,
    CanvasTool? selectedTool,
    Color? selectedColor,
    double? strokeWidth,
    List<PeerUser>? peers,
    bool? showChat,
    double? zoomLevel,
    Offset? panOffset,
    CanvasObject? selectedObject,
    bool clearSelection = false,
  }) {
    return CanvasState(
      objects: objects ?? this.objects,
      selectedTool: selectedTool ?? this.selectedTool,
      selectedColor: selectedColor ?? this.selectedColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      peers: peers ?? this.peers,
      showChat: showChat ?? this.showChat,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      panOffset: panOffset ?? this.panOffset,
      selectedObject:
          clearSelection ? null : (selectedObject ?? this.selectedObject),
    );
  }
}

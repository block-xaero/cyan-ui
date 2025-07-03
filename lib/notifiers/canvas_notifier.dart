import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/canvas_state_model.dart';
import '../models/canvas_models.dart';
import '../theme/cyan_theme.dart';
import '../services/cyan_event_bus.dart';
import '../events/cyan_event.dart';

class CanvasNotifier extends StateNotifier<CanvasState> {
  final String objectId;

  CanvasNotifier(this.objectId) : super(CanvasState()) {
    _initializeCanvas();
  }

  void _initializeCanvas() {
    // Mock peers
    state = state.copyWith(
      peers: [
        PeerUser(
          did: 'did:peer:alice123',
          name: 'Alice Chen',
          color: CyanTheme.secondary,
          isOnline: true,
        ),
        PeerUser(
          did: 'did:peer:bob456',
          name: 'Bob Wilson',
          color: CyanTheme.warning,
          isOnline: true,
        ),
        PeerUser(
          did: 'did:peer:carol789',
          name: 'Carol Johnson',
          color: CyanTheme.accent,
          isOnline: false,
        ),
      ],
    );
  }

  void selectTool(CanvasTool tool) {
    state = state.copyWith(selectedTool: tool, clearSelection: true);

    // Send tool selection to XaeroFlux
    CyanEventBus().dispatch(CyanEvent(
      type: CyanEventType.canvasStroke,
      id: 'tool_select_${DateTime.now().millisecondsSinceEpoch}',
      payload: Uint8List.fromList([
        ...objectId.codeUnits,
        0,
        ...tool.name.codeUnits,
      ]),
    ));
  }

  void selectColor(Color color) {
    state = state.copyWith(selectedColor: color);
  }

  void setStrokeWidth(double width) {
    state = state.copyWith(strokeWidth: width);
  }

  void addObject(CanvasObject object) {
    state = state.copyWith(objects: [...state.objects, object]);

    // Send object creation to XaeroFlux
    CyanEventBus().dispatch(CyanEvent(
      type: CyanEventType.objectCreate,
      id: 'canvas_object_${DateTime.now().millisecondsSinceEpoch}',
      payload: Uint8List.fromList([
        ...objectId.codeUnits,
        0,
        ...object.type.name.codeUnits,
        0,
        ...object.position.dx.toInt().toString().codeUnits,
        0,
        ...object.position.dy.toInt().toString().codeUnits,
      ]),
    ));
  }

  void updateObject(String objectId, CanvasObject updatedObject) {
    final objects = state.objects
        .map((obj) => obj.id == objectId ? updatedObject : obj)
        .toList();
    state = state.copyWith(objects: objects);
  }

  void selectObject(CanvasObject? object) {
    state = state.copyWith(selectedObject: object);
  }

  void deleteSelectedObject() {
    if (state.selectedObject != null) {
      final objects = state.objects
          .where((obj) => obj.id != state.selectedObject!.id)
          .toList();
      state = state.copyWith(objects: objects, clearSelection: true);
    }
  }

  void toggleChat() {
    state = state.copyWith(showChat: !state.showChat);
  }

  void zoom(double delta) {
    final newZoom = (state.zoomLevel + delta).clamp(0.1, 5.0);
    state = state.copyWith(zoomLevel: newZoom);
  }

  void pan(Offset delta) {
    state = state.copyWith(panOffset: state.panOffset + delta);
  }

  void undo() {
    if (state.objects.isNotEmpty) {
      final objects = state.objects.sublist(0, state.objects.length - 1);
      state = state.copyWith(objects: objects, clearSelection: true);
    }
  }
}

final canvasProvider =
    StateNotifierProvider.family<CanvasNotifier, CanvasState, String>(
        (ref, objectId) {
  return CanvasNotifier(objectId);
});

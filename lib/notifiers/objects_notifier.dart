import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/object_ui_item.dart';
import '../services/cyan_event_bus.dart';
import '../events/cyan_event.dart';

class ObjectsUINotifier extends StateNotifier<List<ObjectUIItem>> {
  ObjectsUINotifier() : super([]);

  void loadObjects(String workspaceId) {
    final payload = Uint8List.fromList(workspaceId.codeUnits);
    CyanEventBus().dispatch(CyanEvent(
      type: CyanEventType.objectCreate,
      id: 'load_objects',
      payload: payload,
    ));

    state = [
      ObjectUIItem(
        id: 'whiteboard_1',
        name: 'System Architecture Whiteboard',
        type: 'whiteboard',
        lastModified: '15m ago',
      ),
      ObjectUIItem(
        id: 'whiteboard_2',
        name: 'User Flow Design Board',
        type: 'whiteboard',
        lastModified: '30m ago',
      ),
      ObjectUIItem(
        id: 'whiteboard_3',
        name: 'API Design & Documentation',
        type: 'whiteboard',
        lastModified: '1h ago',
      ),
      ObjectUIItem(
        id: 'whiteboard_4',
        name: 'Database Schema Planning',
        type: 'whiteboard',
        lastModified: '2h ago',
      ),
      ObjectUIItem(
        id: 'whiteboard_5',
        name: 'Sprint Planning Board',
        type: 'whiteboard',
        lastModified: '45m ago',
      ),
      ObjectUIItem(
        id: 'whiteboard_6',
        name: 'Feature Brainstorming',
        type: 'whiteboard',
        lastModified: '3h ago',
      ),
    ];
  }
}

final objectsUIProvider =
    StateNotifierProvider<ObjectsUINotifier, List<ObjectUIItem>>((ref) {
  return ObjectsUINotifier();
});

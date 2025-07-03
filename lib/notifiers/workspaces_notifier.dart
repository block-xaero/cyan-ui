import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workspace_ui_item.dart';
import '../services/cyan_event_bus.dart';
import '../events/cyan_event.dart';

class WorkspacesUINotifier extends StateNotifier<List<WorkspaceUIItem>> {
  WorkspacesUINotifier() : super([]);

  void loadWorkspaces(String groupId) {
    final payload = Uint8List.fromList(groupId.codeUnits);
    CyanEventBus().dispatch(CyanEvent(
      type: CyanEventType.workspaceJoin,
      id: 'load_workspaces',
      payload: payload,
    ));

    state = [
      WorkspaceUIItem(
        id: 'ws_1',
        name: 'Q3 Sprint Planning',
        description:
            'User stories, epics, and roadmap planning for Q3 deliverables',
        lastActivity: '2h ago',
      ),
      WorkspaceUIItem(
        id: 'ws_2',
        name: 'System Architecture',
        description:
            'Microservices design, API contracts, and infrastructure diagrams',
        lastActivity: '30m ago',
      ),
      WorkspaceUIItem(
        id: 'ws_3',
        name: 'User Research Findings',
        description: 'Interview insights, user personas, and journey mapping',
        lastActivity: '1h ago',
      ),
      WorkspaceUIItem(
        id: 'ws_4',
        name: 'Database Schema Design',
        description:
            'Entity relationships, indexing strategy, and migration plans',
        lastActivity: '45m ago',
      ),
      WorkspaceUIItem(
        id: 'ws_5',
        name: 'Marketing Campaign Ideas',
        description:
            'Brand messaging, content calendar, and social media strategy',
        lastActivity: '3h ago',
      ),
      WorkspaceUIItem(
        id: 'ws_6',
        name: 'Mobile App Wireframes',
        description:
            'iOS and Android screen flows, component library, and prototypes',
        lastActivity: '1d ago',
      ),
    ];
  }

  void createWorkspace(String groupId, String name, String description) {
    final groupBytes = groupId.codeUnits;
    final nameBytes = name.codeUnits;
    final descBytes = description.codeUnits;
    final payload = Uint8List.fromList([
      groupBytes.length,
      ...groupBytes,
      nameBytes.length,
      ...nameBytes,
      descBytes.length,
      ...descBytes,
    ]);

    CyanEventBus().dispatch(CyanEvent(
      type: CyanEventType.workspaceCreate,
      id: 'create_workspace_${DateTime.now().millisecondsSinceEpoch}',
      payload: payload,
    ));
  }
}

final workspacesUIProvider =
    StateNotifierProvider<WorkspacesUINotifier, List<WorkspaceUIItem>>((ref) {
  return WorkspacesUINotifier();
});

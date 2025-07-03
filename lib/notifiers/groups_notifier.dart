import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group_ui_item.dart';
import '../services/cyan_event_bus.dart';
import '../events/cyan_event.dart';

class GroupsUINotifier extends StateNotifier<List<GroupUIItem>> {
  final CyanEventBus _eventBus = CyanEventBus();

  GroupsUINotifier() : super([]) {
    _loadGroups();
  }

  void _loadGroups() {
    _eventBus.dispatch(CyanEvent(
      type: CyanEventType.groupJoin,
      id: 'load_groups',
      payload: Uint8List.fromList([0]),
    ));

    state = [
      GroupUIItem(
        id: 'group_1',
        name: 'Data Engineering Team',
        description: 'Building data pipelines and analytics infrastructure',
        isPrivate: true,
        isAdmin: true,
      ),
      GroupUIItem(
        id: 'group_2',
        name: 'Product Design',
        description: 'UI/UX design collaboration and user research',
        isPrivate: true,
        isAdmin: false,
      ),
      GroupUIItem(
        id: 'group_3',
        name: 'Marketing Strategy',
        description: 'Campaign planning and content creation',
        isPrivate: false,
        isAdmin: true,
      ),
      GroupUIItem(
        id: 'group_4',
        name: 'Engineering All-Hands',
        description: 'Cross-team technical discussions and architecture',
        isPrivate: false,
        isAdmin: false,
      ),
      GroupUIItem(
        id: 'group_5',
        name: 'Open Source Projects',
        description: 'Community-driven development and contributions',
        isPrivate: false,
        isAdmin: false,
      ),
      GroupUIItem(
        id: 'group_6',
        name: 'Research & Innovation',
        description: 'Experimental projects and cutting-edge tech exploration',
        isPrivate: true,
        isAdmin: true,
      ),
    ];
  }

  void createGroup(String name, String description, bool isPrivate) {
    final nameBytes = name.codeUnits;
    final descBytes = description.codeUnits;
    final payload = Uint8List.fromList([
      isPrivate ? 1 : 0,
      nameBytes.length,
      ...nameBytes,
      descBytes.length,
      ...descBytes,
    ]);

    _eventBus.dispatch(CyanEvent(
      type: CyanEventType.groupCreate,
      id: 'create_group_${DateTime.now().millisecondsSinceEpoch}',
      payload: payload,
    ));
  }
}

final groupsUIProvider =
    StateNotifierProvider<GroupsUINotifier, List<GroupUIItem>>((ref) {
  return GroupsUINotifier();
});

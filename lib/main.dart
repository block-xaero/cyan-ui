import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:go_router/go_router.dart';
import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'dart:math' show cos, sin;

// ============================================================================
// THEME & CONSTANTS
// ============================================================================

class CyanTheme {
  static const Color background = Color(0xFF272822);
  static const Color surface = Color(0xFF3E3D32);
  static const Color primary = Color(0xFF66D9EF);
  static const Color secondary = Color(0xFFA6E22E);
  static const Color accent = Color(0xFFF92672);
  static const Color text = Color(0xFFF8F8F2);
  static const Color textSecondary = Color(0xFF75715E);
  static const Color warning = Color(0xFFE6DB74);

  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          background: background,
          surface: surface,
          primary: primary,
          secondary: secondary,
          error: accent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: text,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: text, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: text),
          bodyMedium: TextStyle(color: textSecondary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: background,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: textSecondary),
        ),
      );
}

// ============================================================================
// EVENTS & FFI LAYER
// ============================================================================

enum CyanEventType {
  authCreateDid,
  authSignIn,
  authSignOut,
  groupCreate,
  groupJoin,
  groupLeave,
  groupInvite,
  workspaceCreate,
  workspaceJoin,
  workspaceUpdate,
  workspaceDelete,
  objectCreate,
  objectUpdate,
  objectDelete,
  objectShare,
  canvasStroke,
  canvasShape,
  canvasText,
  canvasImage,
  canvasUndo,
  canvasRedo,
  canvasClear,
  chatMessage,
  chatTyping,
  aiDigitizePhoto,
  aiProcessResult,
  syncRequest,
  syncResponse,
}

class CyanEvent {
  final CyanEventType type;
  final String id;
  final Uint8List payload;
  final DateTime timestamp;

  CyanEvent({
    required this.type,
    required this.id,
    required this.payload,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class XaeroFluxFFI {
  static void sendEvent(CyanEvent event) {
    print('FFI: Sending ${event.type} event (${event.payload.length} bytes)');
  }

  static Stream<CyanEvent> getEventStream() {
    return Stream.periodic(
        const Duration(seconds: 2),
        (i) => CyanEvent(
              type: CyanEventType.syncResponse,
              id: 'sync_response_$i',
              payload: Uint8List.fromList([0, 1, 2, 3]),
            ));
  }
}

class CyanEventBus {
  static final _instance = CyanEventBus._internal();
  factory CyanEventBus() => _instance;
  CyanEventBus._internal();

  final _eventSubject = BehaviorSubject<CyanEvent>();

  Stream<CyanEvent> get eventStream => _eventSubject.stream;
  Stream<CyanEvent> eventsOfType(CyanEventType type) =>
      eventStream.where((event) => event.type == type);

  void dispatch(CyanEvent event) {
    XaeroFluxFFI.sendEvent(event);
    _eventSubject.add(event);
  }

  void dispose() {
    _eventSubject.close();
  }
}

// ============================================================================
// CANVAS MODELS & STATE
// ============================================================================

enum CanvasTool {
  pan,
  select,
  pen,
  line,
  rectangle,
  circle,
  arrow,
  text,
  sticky,
  eraser,
}

enum CanvasObjectType {
  pen,
  line,
  rectangle,
  circle,
  arrow,
  text,
  sticky,
}

class CanvasObject {
  final String id;
  final CanvasObjectType type;
  final Offset position;
  final Size size;
  final Color color;
  final String? text;
  final List<Offset>? path;
  final double strokeWidth;

  CanvasObject({
    required this.id,
    required this.type,
    required this.position,
    this.size = const Size(100, 100),
    this.color = CyanTheme.primary,
    this.text,
    this.path,
    this.strokeWidth = 2.0,
  });

  CanvasObject copyWith({
    Offset? position,
    Size? size,
    Color? color,
    String? text,
    double? strokeWidth,
  }) {
    return CanvasObject(
      id: id,
      type: type,
      position: position ?? this.position,
      size: size ?? this.size,
      color: color ?? this.color,
      text: text ?? this.text,
      path: path,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}

class PeerUser {
  final String did;
  final String name;
  final Color color;
  final bool isOnline;
  final Offset? cursorPosition;

  PeerUser({
    required this.did,
    required this.name,
    required this.color,
    required this.isOnline,
    this.cursorPosition,
  });
}

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

// Canvas State Provider
final canvasProvider =
    StateNotifierProvider.family<CanvasNotifier, CanvasState, String>(
        (ref, objectId) {
  return CanvasNotifier(objectId);
});

// ============================================================================
// DATA MODELS
// ============================================================================

class XaeroID {
  final String did;
  final String publicKey;
  final List<ZKProof> zkProofs;
  final DateTime createdAt;

  XaeroID({
    required this.did,
    required this.publicKey,
    required this.zkProofs,
    required this.createdAt,
  });
}

class ZKProof {
  final String id;
  final String type;
  final String issuer;
  final Map<String, dynamic> claims;
  final String proof;
  final DateTime issuedAt;
  final DateTime? expiresAt;

  ZKProof({
    required this.id,
    required this.type,
    required this.issuer,
    required this.claims,
    required this.proof,
    required this.issuedAt,
    this.expiresAt,
  });
}

class AuthUIState {
  final bool isLoading;
  final XaeroID? user;
  final String? error;

  AuthUIState({this.isLoading = false, this.user, this.error});

  bool get isAuthenticated => user != null;
}

class GroupUIItem {
  final String id;
  final String name;
  final String description;
  final bool isPrivate;
  final bool isAdmin;

  GroupUIItem({
    required this.id,
    required this.name,
    required this.description,
    required this.isPrivate,
    required this.isAdmin,
  });
}

class WorkspaceUIItem {
  final String id;
  final String name;
  final String description;
  final String lastActivity;

  WorkspaceUIItem({
    required this.id,
    required this.name,
    required this.description,
    required this.lastActivity,
  });
}

class ObjectUIItem {
  final String id;
  final String name;
  final String type;
  final String lastModified;

  ObjectUIItem({
    required this.id,
    required this.name,
    required this.type,
    required this.lastModified,
  });
}

// ============================================================================
// PROVIDERS
// ============================================================================

final authUIProvider =
    StateNotifierProvider<AuthUINotifier, AuthUIState>((ref) {
  return AuthUINotifier();
});

final groupsUIProvider =
    StateNotifierProvider<GroupsUINotifier, List<GroupUIItem>>((ref) {
  return GroupsUINotifier();
});

final workspacesUIProvider =
    StateNotifierProvider<WorkspacesUINotifier, List<WorkspaceUIItem>>((ref) {
  return WorkspacesUINotifier();
});

final objectsUIProvider =
    StateNotifierProvider<ObjectsUINotifier, List<ObjectUIItem>>((ref) {
  return ObjectsUINotifier();
});

class AuthUINotifier extends StateNotifier<AuthUIState> {
  final CyanEventBus _eventBus = CyanEventBus();

  AuthUINotifier() : super(AuthUIState()) {
    _eventBus
        .eventsOfType(CyanEventType.authSignIn)
        .listen(_handleAuthResponse);
  }

  void _handleAuthResponse(CyanEvent event) {
    state = AuthUIState(
        user: XaeroID(
      did: 'did:peer:1zQmYj8K9XwLWZ3VxN4qP7RdS2',
      publicKey: 'falcon512_02a1b2c3d4e5f6...',
      zkProofs: [
        ZKProof(
          id: 'admin_proof_1',
          type: 'GroupAdmin',
          issuer: 'did:peer:genesis',
          claims: {'role': 'admin', 'groupId': 'group_1'},
          proof: 'zkp_a1b2c3d4e5f6...',
          issuedAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        ZKProof(
          id: 'member_proof_1',
          type: 'GroupMember',
          issuer: 'did:peer:1zQmYj8K9XwLWZ3VxN4qP7RdS2',
          claims: {'role': 'member', 'groupId': 'group_2'},
          proof: 'zkp_b2c3d4e5f6a1...',
          issuedAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ));
  }

  void createDid() {
    state = AuthUIState(isLoading: true);
    _eventBus.dispatch(CyanEvent(
      type: CyanEventType.authCreateDid,
      id: 'create_did_${DateTime.now().millisecondsSinceEpoch}',
      payload: Uint8List.fromList([]),
    ));

    Future.delayed(const Duration(seconds: 1), () {
      state = AuthUIState(
          user: XaeroID(
        did: 'did:peer:1zQmNew7X9wLWZ3VxN4qP7RdS2',
        publicKey: 'falcon512_new_02a1b2c3d4e5f6...',
        zkProofs: [],
        createdAt: DateTime.now(),
      ));
    });
  }

  void signIn() {
    state = AuthUIState(isLoading: true);
    _eventBus.dispatch(CyanEvent(
      type: CyanEventType.authSignIn,
      id: 'sign_in_${DateTime.now().millisecondsSinceEpoch}',
      payload: Uint8List.fromList([]),
    ));

    Future.delayed(const Duration(seconds: 1), () {
      state = AuthUIState(
          user: XaeroID(
        did: 'did:peer:1zQmExisting8K9XwLWZ3VxN4qP7',
        publicKey: 'falcon512_existing_02a1b2c3d4e5f6...',
        zkProofs: [
          ZKProof(
            id: 'member_proof_2',
            type: 'GroupMember',
            issuer: 'did:peer:admin',
            claims: {'role': 'member', 'groupId': 'group_1'},
            proof: 'zkp_existing_member...',
            issuedAt: DateTime.now().subtract(const Duration(days: 10)),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ));
    });
  }
}

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
      ObjectUIItem(
        id: 'whiteboard_7',
        name: 'Team Retrospective',
        type: 'whiteboard',
        lastModified: '1d ago',
      ),
      ObjectUIItem(
        id: 'whiteboard_8',
        name: 'Customer Journey Mapping',
        type: 'whiteboard',
        lastModified: '6h ago',
      ),
      ObjectUIItem(
        id: 'whiteboard_9',
        name: 'Technical Debt Analysis',
        type: 'whiteboard',
        lastModified: '4h ago',
      ),
      ObjectUIItem(
        id: 'whiteboard_10',
        name: 'Security Review Board',
        type: 'whiteboard',
        lastModified: '2d ago',
      ),
      ObjectUIItem(
        id: 'whiteboard_11',
        name: 'Mobile App Wireframes',
        type: 'whiteboard',
        lastModified: '8h ago',
      ),
      ObjectUIItem(
        id: 'whiteboard_12',
        name: 'Integration Planning',
        type: 'whiteboard',
        lastModified: '1d ago',
      ),
    ];
  }
}

// ============================================================================
// SHARED COMPONENTS
// ============================================================================

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
                _SideMenuItem(
                  icon: Icons.home,
                  label: 'Home',
                  isActive: currentRoute.contains('/groups'),
                  onTap: () => context.go('/groups'),
                ),
                const SizedBox(height: 6),
                _SideMenuItem(
                  icon: Icons.groups,
                  label: 'Groups',
                  isActive: currentRoute.contains('/groups'),
                  onTap: () => context.go('/groups'),
                ),
                const SizedBox(height: 6),
                _SideMenuItem(
                  icon: Icons.chat_bubble_outline,
                  label: 'Recent Chats',
                  isActive: currentRoute.contains('/chat'),
                  onTap: () => context.go('/chat/ws_1'),
                ),
                const SizedBox(height: 6),
                _SideMenuItem(
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
                _SideMenuItem(
                  icon: Icons.dashboard,
                  label: 'Q3 Sprint Planning',
                  isActive: false,
                  onTap: () => context.go('/workspace/ws_1/objects'),
                ),
                const SizedBox(height: 4),
                _SideMenuItem(
                  icon: Icons.architecture,
                  label: 'System Architecture',
                  isActive: false,
                  onTap: () => context.go('/workspace/ws_2/objects'),
                ),
                const SizedBox(height: 4),
                _SideMenuItem(
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

class _SideMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SideMenuItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? CyanTheme.primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(6),
          border: isActive
              ? Border.all(color: CyanTheme.primary.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? CyanTheme.primary : CyanTheme.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? CyanTheme.primary : CyanTheme.text,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ROUTING
// ============================================================================

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authUIProvider);

  return GoRouter(
    initialLocation: '/auth',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isOnAuthPage = state.uri.toString().startsWith('/auth');

      if (!isAuthenticated && !isOnAuthPage) return '/auth';
      if (isAuthenticated && isOnAuthPage) return '/groups';
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: '/groups',
        builder: (context, state) => const GroupsPage(),
      ),
      GoRoute(
        path: '/group/:groupId/workspaces',
        builder: (context, state) => WorkspacesPage(
          groupId: state.pathParameters['groupId']!,
        ),
      ),
      GoRoute(
        path: '/workspace/:workspaceId/objects',
        builder: (context, state) => ObjectsPage(
          workspaceId: state.pathParameters['workspaceId']!,
        ),
      ),
      GoRoute(
        path: '/canvas/:objectId',
        builder: (context, state) => CanvasPage(
          objectId: state.pathParameters['objectId']!,
        ),
      ),
      GoRoute(
        path: '/digitize',
        builder: (context, state) => const DigitizePage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/chat/:workspaceId',
        builder: (context, state) => ChatPage(
          workspaceId: state.pathParameters['workspaceId']!,
        ),
      ),
    ],
  );
});

// ============================================================================
// PAGES
// ============================================================================

class AuthPage extends ConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authUIProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              CyanTheme.background,
              CyanTheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.hub_outlined,
                    size: 80,
                    color: CyanTheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'CYAN',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 48,
                          color: CyanTheme.primary,
                          letterSpacing: 8,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Decentralized Collaborative Whiteboarding',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  if (authState.isLoading)
                    const CircularProgressIndicator()
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            ref.read(authUIProvider.notifier).createDid(),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Create DID & Join'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            ref.read(authUIProvider.notifier).signIn(),
                        icon: const Icon(Icons.login),
                        label: const Text('Sign In with DID'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          side: const BorderSide(color: CyanTheme.primary),
                        ),
                      ),
                    ),
                  ],
                  if (authState.error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      authState.error!,
                      style: const TextStyle(color: CyanTheme.accent),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.security,
                          size: 16, color: CyanTheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'P2P • Offline-First • Zero-Knowledge',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: CyanTheme.secondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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

// ============================================================================
// WHITEBOARD PREVIEW PAINTER
// ============================================================================

class WhiteboardPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw some mock shapes to make it look like a real whiteboard
    // Rectangle
    paint.color = CyanTheme.primary.withOpacity(0.6);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.2, size.width * 0.3,
          size.height * 0.25),
      paint,
    );

    // Circle
    paint.color = CyanTheme.secondary.withOpacity(0.6);
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.3),
      size.width * 0.12,
      paint,
    );

    // Arrow
    paint.color = CyanTheme.warning.withOpacity(0.6);
    canvas.drawLine(
      Offset(size.width * 0.45, size.height * 0.35),
      Offset(size.width * 0.6, size.height * 0.35),
      paint,
    );

    // Arrow head
    final arrowPath = Path();
    arrowPath.moveTo(size.width * 0.6, size.height * 0.35);
    arrowPath.lineTo(size.width * 0.55, size.height * 0.32);
    arrowPath.lineTo(size.width * 0.55, size.height * 0.38);
    arrowPath.close();
    paint.style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, paint);

    // Some connecting lines
    paint
      ..color = CyanTheme.textSecondary.withOpacity(0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.32),
      Offset(size.width * 0.45, size.height * 0.35),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.6),
      Offset(size.width * 0.65, size.height * 0.45),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// CANVAS PAGE - PROPER LAYOUT AS DISCUSSED
// ============================================================================

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
// REMAINING PAGES
// ============================================================================

class DigitizePage extends StatelessWidget {
  const DigitizePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          CyanSideMenu(currentRoute: '/digitize'),
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
                        'Digitize Whiteboard',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: CyanTheme.primary, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt,
                                      size: 64, color: CyanTheme.textSecondary),
                                  SizedBox(height: 16),
                                  Text(
                                    'Take a photo of your whiteboard',
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: CyanTheme.textSecondary),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'XaeroAI will convert it to digital diagrams and notes',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: CyanTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  CyanEventBus().dispatch(CyanEvent(
                                    type: CyanEventType.aiDigitizePhoto,
                                    id: 'capture_photo',
                                    payload: Uint8List.fromList([1]),
                                  ));
                                },
                                icon: const Icon(Icons.camera),
                                label: const Text('Take Photo'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  CyanEventBus().dispatch(CyanEvent(
                                    type: CyanEventType.aiDigitizePhoto,
                                    id: 'select_photo',
                                    payload: Uint8List.fromList([2]),
                                  ));
                                },
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Choose from Gallery'),
                              ),
                            ),
                          ],
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
}

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authUIProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          CyanSideMenu(currentRoute: '/profile'),
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
                        'Profile & ZK Wallet',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          CyanEventBus().dispatch(CyanEvent(
                            type: CyanEventType.authSignOut,
                            id: 'sign_out',
                            payload: Uint8List.fromList([]),
                          ));
                          context.go('/auth');
                        },
                        icon: const Icon(Icons.logout, size: 16),
                        label: const Text('Sign Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CyanTheme.accent,
                          foregroundColor: Colors.white,
                        ),
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
                          'Profile & Identity',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: CyanTheme.primary,
                                      child: Text(
                                        user.did
                                            .split(':')
                                            .last
                                            .substring(0, 2)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'XaeroID',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            user.did,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      CyanTheme.textSecondary,
                                                  fontFamily: 'monospace',
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Divider(),
                                const SizedBox(height: 20),
                                Text(
                                  'Zero-Knowledge Proofs',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                ...user.zkProofs.map((proof) => Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: proof.type ==
                                                            'GroupAdmin'
                                                        ? CyanTheme.primary
                                                            .withOpacity(0.2)
                                                        : CyanTheme.secondary
                                                            .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    proof.type,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: proof.type ==
                                                              'GroupAdmin'
                                                          ? CyanTheme.primary
                                                          : CyanTheme.secondary,
                                                    ),
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  '${DateTime.now().difference(proof.issuedAt).inDays}d ago',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        CyanTheme.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Role: ${proof.claims['role']}',
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                            Text(
                                              'Group: ${proof.claims['groupId']}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: CyanTheme.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Proof: ${proof.proof.substring(0, 20)}...',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: CyanTheme.textSecondary,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )),
                                const SizedBox(height: 20),
                                Text(
                                  'Security Details',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.key,
                                                color: CyanTheme.warning),
                                            const SizedBox(width: 8),
                                            const Text('Public Key'),
                                            const Spacer(),
                                            Text(
                                              user.publicKey.substring(0, 16) +
                                                  '...',
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 12,
                                                color: CyanTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const Icon(Icons.schedule,
                                                color: CyanTheme.secondary),
                                            const SizedBox(width: 8),
                                            const Text('Created'),
                                            const Spacer(),
                                            Text(
                                              '${DateTime.now().difference(user.createdAt).inDays} days ago',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: CyanTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const Icon(Icons.security,
                                                color: CyanTheme.primary),
                                            const SizedBox(width: 8),
                                            const Text('Encryption'),
                                            const Spacer(),
                                            const Text(
                                              'Falcon-512 Post-Quantum',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: CyanTheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
}

class ChatPage extends StatefulWidget {
  final String workspaceId;

  const ChatPage({super.key, required this.workspaceId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'Alice Chen',
      'text': 'Hey team! Ready for our sprint planning session?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
      'isOwn': false,
    },
    {
      'sender': 'Bob Wilson',
      'text': 'Absolutely! I\'ve got the user stories ready to review.',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 12)),
      'isOwn': false,
    },
    {
      'sender': 'You',
      'text': 'Perfect! Let\'s start with the high-priority items.',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 8)),
      'isOwn': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          CyanSideMenu(currentRoute: '/chat/${widget.workspaceId}'),
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
                        'Team Chat',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          CyanEventBus().dispatch(CyanEvent(
                            type: CyanEventType.chatMessage,
                            id: 'video_call',
                            payload: Uint8List.fromList([
                              ...widget.workspaceId.codeUnits,
                              0,
                              ...'video_call_request'.codeUnits,
                            ]),
                          ));
                        },
                        icon: const Icon(Icons.video_call),
                        tooltip: 'Start Video Call',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _ChatMessage(
                        sender: message['sender'],
                        message: message['text'],
                        timestamp: message['timestamp'],
                        isOwnMessage: message['isOwn'],
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: CyanTheme.surface,
                    border:
                        Border(top: BorderSide(color: CyanTheme.background)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: InputBorder.none,
                          ),
                          onSubmitted: _sendMessage,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _sendMessage(_messageController.text),
                        icon: const Icon(Icons.send, color: CyanTheme.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      id: 'send_message_${DateTime.now().millisecondsSinceEpoch}',
      payload: payload,
    ));

    setState(() {
      _messages.add({
        'sender': 'You',
        'text': text,
        'timestamp': DateTime.now(),
        'isOwn': true,
      });
    });

    _messageController.clear();
  }
}

class _ChatMessage extends StatelessWidget {
  final String sender;
  final String message;
  final DateTime timestamp;
  final bool isOwnMessage;

  const _ChatMessage({
    required this.sender,
    required this.message,
    required this.timestamp,
    required this.isOwnMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isOwnMessage) ...[
            CircleAvatar(
              backgroundColor: CyanTheme.primary,
              child: Text(sender[0]),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOwnMessage ? CyanTheme.primary : CyanTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isOwnMessage)
                    Text(
                      sender,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  Text(
                    message,
                    style: TextStyle(
                      color:
                          isOwnMessage ? CyanTheme.background : CyanTheme.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isOwnMessage
                          ? CyanTheme.background.withOpacity(0.7)
                          : CyanTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isOwnMessage) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: CyanTheme.secondary,
              child: Text('Y'),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// MAIN APP
// ============================================================================

class CyanApp extends ConsumerWidget {
  const CyanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Cyan',
      theme: CyanTheme.theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

void main() {
  runApp(
    const ProviderScope(
      child: CyanApp(),
    ),
  );
}

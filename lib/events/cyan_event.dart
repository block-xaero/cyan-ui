import 'dart:typed_data';

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

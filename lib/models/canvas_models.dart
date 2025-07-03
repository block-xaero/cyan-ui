import 'package:flutter/material.dart';
import '../theme/cyan_theme.dart';

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

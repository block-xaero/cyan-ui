import 'dart:typed_data';

import 'package:cyan/events/cyan_event.dart';
import 'package:cyan/services/cyan_event_bus.dart';
import 'package:cyan/theme/cyan_theme.dart';
import 'package:cyan/widgets/cyan_side_menu.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

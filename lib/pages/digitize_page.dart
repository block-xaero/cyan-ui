import 'dart:typed_data';

import 'package:cyan/events/cyan_event.dart';
import 'package:cyan/services/cyan_event_bus.dart';
import 'package:cyan/theme/cyan_theme.dart' show CyanTheme;
import 'package:cyan/widgets/cyan_side_menu.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

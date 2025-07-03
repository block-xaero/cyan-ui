import 'package:cyan/events/cyan_event.dart';
import 'package:cyan/notifiers/auth_notifier.dart';
import 'package:cyan/services/cyan_event_bus.dart';
import 'package:cyan/theme/cyan_theme.dart';
import 'package:cyan/widgets/cyan_side_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import 'dart:math' show cos, sin;

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
          const CyanSideMenu(currentRoute: '/profile'),
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
                                        const Row(
                                          children: [
                                            Icon(Icons.security,
                                                color: CyanTheme.primary),
                                            SizedBox(width: 8),
                                            Text('Encryption'),
                                            Spacer(),
                                            Text(
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

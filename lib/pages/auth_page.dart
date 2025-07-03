import 'package:cyan/notifiers/auth_notifier.dart';
import 'package:cyan/theme/cyan_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

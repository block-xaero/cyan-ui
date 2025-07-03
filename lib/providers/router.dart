import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../notifiers/auth_notifier.dart';
import '../pages/auth_page.dart';
import '../pages/groups_page.dart';
import '../pages/workspaces_page.dart';
import '../pages/objects_page.dart';
import '../pages/canvas_page.dart';
import '../pages/digitize_page.dart';
import '../pages/profile_page.dart';
import '../pages/chat_page.dart';

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

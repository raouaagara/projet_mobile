import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_paths.dart';
import '../../shared/widgets/async_value_view.dart';
import 'presentation/screens/availability_screens.dart';
import 'presentation/screens/chat_screen.dart';
import 'presentation/screens/compose_screen.dart';
import 'presentation/screens/conversations_screen.dart';
import 'presentation/screens/help_assistant_screen.dart';
import 'presentation/screens/support_screens.dart';

// Module 4 – Messaging, Support & Availability (branch: feature/messaging-support)
// Paths are listed in messaging_paths.dart. Static paths must come before ':id' ones.

/// Root of the third bottom tab.
final messagesTab = GoRoute(path: AppPaths.messages, builder: (context, state) => const ConversationsScreen());

/// Full-screen pages, above the bottom bar.
final messagingRoutes = <RouteBase>[
  GoRoute(path: '${AppPaths.messages}/compose', builder: (context, state) => const ComposeScreen()),
  GoRoute(
    path: '${AppPaths.messages}/new/:userId',
    builder: (context, state) => _withInt(state, 'userId', (id) => StartChatScreen(userId: id)),
  ),
  GoRoute(
    path: '${AppPaths.messages}/:conversationId',
    builder: (context, state) {
      final conversationId = int.tryParse(state.pathParameters['conversationId']!);
      final otherUserId = int.tryParse(state.uri.queryParameters['with'] ?? '');
      if (conversationId == null || otherUserId == null) return const _InvalidLink();
      return ChatScreen(conversationId: conversationId, otherUserId: otherUserId);
    },
  ),
  GoRoute(
    path: AppPaths.support,
    builder: (context, state) => const SupportScreen(),
    routes: [
      GoRoute(
        path: 'new',
        builder: (context, state) {
          // From the assistant: the request it wrote.
          final draft = state.extra as ({String title, String description})?;
          return NewTicketScreen(initialTitle: draft?.title, initialDescription: draft?.description);
        },
      ),
      GoRoute(path: 'assistant', builder: (context, state) => const HelpAssistantScreen()),
      GoRoute(
        path: ':ticketId',
        builder: (context, state) => _withInt(state, 'ticketId', (id) => TicketScreen(ticketId: id)),
      ),
    ],
  ),
  GoRoute(path: AppPaths.availability, builder: (context, state) => const AvailabilityScreen()),
  GoRoute(path: AppPaths.worldClock, builder: (context, state) => const WorldClockScreen()),
];

Widget _withInt(GoRouterState state, String name, Widget Function(int id) page) {
  final id = int.tryParse(state.pathParameters[name]!);
  return id == null ? const _InvalidLink() : page(id);
}

class _InvalidLink extends StatelessWidget {
  const _InvalidLink();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: const ErrorView(message: 'This link is not valid.'),
  );
}

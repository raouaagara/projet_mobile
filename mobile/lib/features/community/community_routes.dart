import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_paths.dart';
import '../../shared/widgets/async_value_view.dart';
import 'presentation/screens/community_screen.dart';
import 'presentation/screens/event_club_screens.dart';
import 'presentation/screens/group_screens.dart';

// Module 6 – Community (branch: feature/community)
// Paths are listed in community_paths.dart. Static paths must come before ':id' ones.

/// Root of the fourth bottom tab.
final communityTab = GoRoute(path: AppPaths.community, builder: (context, state) => const CommunityScreen());

/// Full-screen pages, above the bottom bar.
final communityRoutes = <RouteBase>[
  GoRoute(path: '${AppPaths.community}/groups/new', builder: (context, state) => const NewGroupScreen()),
  GoRoute(
    path: '${AppPaths.community}/groups/:id',
    builder: (context, state) => _withId(state, (id) => GroupScreen(groupId: id)),
  ),
  GoRoute(
    path: '${AppPaths.community}/posts/:id',
    builder: (context, state) => _withId(state, (id) => PostScreen(postId: id)),
  ),
  GoRoute(
    path: '${AppPaths.community}/events/new',
    builder: (context, state) => NewEventScreen(
      groupId: int.tryParse(state.uri.queryParameters['groupId'] ?? ''),
      clubId: int.tryParse(state.uri.queryParameters['clubId'] ?? ''),
    ),
  ),
  GoRoute(
    path: '${AppPaths.community}/events/:id',
    builder: (context, state) => _withId(state, (id) => EventScreen(eventId: id)),
  ),
  GoRoute(path: '${AppPaths.community}/clubs/new', builder: (context, state) => const ClubFormScreen()),
  GoRoute(
    path: '${AppPaths.community}/clubs/:id',
    builder: (context, state) => _withId(state, (id) => ClubScreen(clubId: id)),
    routes: [
      GoRoute(
        path: 'edit',
        builder: (context, state) => _withId(state, (id) => ClubFormScreen(clubId: id)),
      ),
    ],
  ),
];

Widget _withId(GoRouterState state, Widget Function(int id) page) {
  final id = int.tryParse(state.pathParameters['id']!);
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

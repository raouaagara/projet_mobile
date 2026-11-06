import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_paths.dart';
import '../../shared/widgets/async_value_view.dart';
import 'presentation/screens/notifications_screen.dart';
import 'presentation/screens/project_details_screen.dart';
import 'presentation/screens/project_form_screen.dart';
import 'presentation/screens/project_proposals_screen.dart';
import 'presentation/screens/projects_home_screen.dart';
import 'presentation/screens/submit_proposal_screen.dart';

// Module 2 – Projects & Proposals (branch: feature/projects)
// Paths are listed in project_paths.dart. Static paths must come before ':projectId'.

/// Root of the first bottom tab: "My projects" (client) or "Find work" (freelancer).
final projectsTab = GoRoute(path: AppPaths.projects, builder: (context, state) => const ProjectsHomeScreen());

/// Full-screen pages, above the bottom bar.
final projectsRoutes = <RouteBase>[
  GoRoute(path: '${AppPaths.projects}/new', builder: (context, state) => const ProjectFormScreen()),
  GoRoute(path: '${AppPaths.projects}/notifications', builder: (context, state) => const NotificationsScreen()),
  GoRoute(
    path: '${AppPaths.projects}/:projectId',
    builder: (context, state) => _withId(state, (id) => ProjectDetailsScreen(projectId: id)),
    routes: [
      GoRoute(
        path: 'edit',
        builder: (context, state) => _withId(state, (id) => ProjectFormScreen(projectId: id)),
      ),
      GoRoute(
        path: 'proposals',
        builder: (context, state) => _withId(state, (id) => ProjectProposalsScreen(projectId: id)),
      ),
      GoRoute(
        path: 'propose',
        builder: (context, state) => _withId(state, (id) => SubmitProposalScreen(projectId: id)),
      ),
    ],
  ),
];

Widget _withId(GoRouterState state, Widget Function(int id) page) {
  final id = int.tryParse(state.pathParameters['projectId']!);
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

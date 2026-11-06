import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_paths.dart';
import '../../shared/widgets/async_value_view.dart';
import 'data/models/skill_test.dart';
import 'presentation/screens/cv_assistant_screen.dart';
import 'presentation/screens/edit_profile_screen.dart';
import 'presentation/screens/leaderboard_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/review_form_screen.dart';
import 'presentation/screens/skill_test_detail_screen.dart';
import 'presentation/screens/skill_tests_screen.dart';
import 'presentation/screens/skills_screen.dart';
import 'presentation/screens/take_test_screen.dart';
import 'presentation/screens/test_result_screen.dart';

// Module 1 – Profile, Skills & Certifications (branch: feature/profile-skills)
// Paths are listed in profile_paths.dart. Static paths must come before ':id' ones.

final profileRoutes = <RouteBase>[
  GoRoute(
    path: AppPaths.profile,
    builder: (context, state) => const ProfileScreen(),
    routes: [
      GoRoute(path: 'edit', builder: (context, state) => const EditProfileScreen()),
      GoRoute(
        path: 'skills',
        builder: (context, state) =>
            SkillsScreen(onboarding: state.uri.queryParameters['onboarding'] == '1'),
      ),
      GoRoute(path: 'onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: 'leaderboard', builder: (context, state) => const LeaderboardScreen()),
      GoRoute(path: 'cv-assistant', builder: (context, state) => const CvAssistantScreen()),
      GoRoute(
        path: 'review',
        builder: (context, state) {
          final userId = int.tryParse(state.uri.queryParameters['userId'] ?? '');
          if (userId == null) return const _InvalidLink();
          return ReviewFormScreen(
            targetUserId: userId,
            projectId: int.tryParse(state.uri.queryParameters['projectId'] ?? ''),
          );
        },
      ),
      GoRoute(
        path: ':userId',
        builder: (context, state) {
          final userId = int.tryParse(state.pathParameters['userId']!);
          return userId == null ? const _InvalidLink() : ProfileScreen(userId: userId);
        },
      ),
    ],
  ),
  GoRoute(
    path: AppPaths.skillTests,
    builder: (context, state) => const SkillTestsScreen(),
    routes: [
      GoRoute(
        path: 'result',
        builder: (context, state) => TestResultScreen(certification: state.extra as Certification?),
      ),
      GoRoute(
        path: ':testId',
        builder: (context, state) {
          final testId = int.tryParse(state.pathParameters['testId']!);
          return testId == null ? const _InvalidLink() : SkillTestDetailScreen(testId: testId);
        },
        routes: [
          GoRoute(
            path: 'take',
            builder: (context, state) {
              final testId = int.tryParse(state.pathParameters['testId']!);
              return testId == null ? const _InvalidLink() : TakeTestScreen(testId: testId);
            },
          ),
        ],
      ),
    ],
  ),
];

class _InvalidLink extends StatelessWidget {
  const _InvalidLink();

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(), body: const ErrorView(message: 'This link is not valid.'));
}

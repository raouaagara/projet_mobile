import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/user_role.dart';
import '../../core/router/app_paths.dart';
import 'presentation/login_screen.dart';
import 'presentation/onboarding_screen.dart';
import 'presentation/register_screen.dart';
import 'presentation/role_choice_screen.dart';
import 'presentation/splash_screen.dart';

final authRoutes = <RouteBase>[
  GoRoute(path: AppPaths.splash, builder: (context, state) => const SplashScreen()),
  GoRoute(
    path: AppPaths.onboarding,
    // Fades in from the green splash screen.
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      transitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
      child: const OnboardingScreen(),
    ),
  ),
  GoRoute(path: AppPaths.login, builder: (context, state) => const LoginScreen()),
  // Sign-up: client or freelancer first, then the form.
  GoRoute(
    path: AppPaths.register,
    builder: (context, state) => const RoleChoiceScreen(),
    routes: [
      GoRoute(
        path: 'details',
        builder: (context, state) => RegisterScreen(
          role: state.uri.queryParameters['role'] == UserRole.client.name ? UserRole.client : UserRole.freelancer,
        ),
      ),
    ],
  ),
];

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_routes.dart';
import '../../features/auth/data/onboarding_store.dart';
import '../../features/auth/domain/auth_session.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/messaging/messaging_routes.dart';
import '../../features/shell/main_shell.dart';
import '../../features/shell/menu_screen.dart';
import 'app_paths.dart';

/// Assembles the routes exported by each module. Module owners edit their own
/// `<module>_routes.dart`, not this file.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.listen(splashDoneProvider, (_, _) => refresh.value++);
  ref.listen(onboardingDoneProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppPaths.splash,
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) => _redirect(
      auth: ref.read(authControllerProvider),
      onboardingDone: ref.read(onboardingDoneProvider),
      splashDone: ref.read(splashDoneProvider),
      location: state.matchedLocation,
    ),
    routes: [
      ...authRoutes,
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [messagesTab]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppPaths.menu, builder: (context, state) => const MenuScreen()),
          ]),
        ],
      ),
      // Full-screen pages, displayed above the bottom navigation.
      ...messagingRoutes,
    ],
  );
});

String? _redirect({
  required AsyncValue<AuthSession?> auth,
  required AsyncValue<bool> onboardingDone,
  required bool splashDone,
  required String location,
}) {
  // The splash screen stays until its animation has played and the saved state is read.
  bool loading(AsyncValue<Object?> value) => value.isLoading && !value.hasValue;
  if (!splashDone || loading(auth) || loading(onboardingDone)) {
    return location == AppPaths.splash ? null : AppPaths.splash;
  }

  final session = auth.value;
  final onAuthPage = location == AppPaths.login || location == AppPaths.register || location.startsWith('${AppPaths.register}/');

  if (session == null) {
    // First launch: the intro pages, then the login.
    if (onboardingDone.value != true) return location == AppPaths.onboarding ? null : AppPaths.onboarding;
    return onAuthPage ? null : AppPaths.login;
  }
  if (onAuthPage || location == AppPaths.splash || location == AppPaths.onboarding) return AppPaths.messages;

  bool under(List<String> roots) =>
      roots.any((root) => location == root || location.startsWith('$root/'));
  if (session.isClient && under(AppPaths.freelancerOnly)) return AppPaths.messages;
  if (session.isFreelancer && under(AppPaths.clientOnly)) return AppPaths.messages;
  return null;
}

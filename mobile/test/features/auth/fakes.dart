import 'package:catchopp_mobile/core/models/user_role.dart';
import 'package:catchopp_mobile/core/router/app_router.dart';
import 'package:catchopp_mobile/features/auth/data/onboarding_store.dart';
import 'package:catchopp_mobile/features/auth/domain/auth_session.dart';
import 'package:catchopp_mobile/features/auth/presentation/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class LoggedOut extends AuthController {
  @override
  Future<AuthSession?> build() async => null;

  /// The sign-ups sent, instead of calling the server.
  final signUps = <Map<String, Object?>>[];

  @override
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
    String? country,
  }) async =>
      signUps.add({'firstName': firstName, 'lastName': lastName, 'email': email, 'role': role, 'country': country});
}

/// In-memory "intro pages seen" flag.
class FakeOnboardingStore extends OnboardingStore {
  FakeOnboardingStore({this.done = false});

  bool done;

  @override
  Future<bool> isDone() async => done;

  @override
  Future<void> markDone() async => done = true;
}

/// The whole app with its real router, logged out. Returns when the splash animation starts
/// (it waits for the first frame to be on screen).
Future<void> pumpWorkify(WidgetTester tester, {required FakeOnboardingStore onboarding, LoggedOut? auth}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => auth ?? LoggedOut()),
      onboardingStoreProvider.overrideWithValue(onboarding),
    ],
    child: Consumer(builder: (context, ref, _) => MaterialApp.router(routerConfig: ref.watch(routerProvider))),
  ));
  await tester.pump(const Duration(milliseconds: 200));
}

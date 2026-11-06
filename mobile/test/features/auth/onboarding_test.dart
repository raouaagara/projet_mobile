import 'package:catchopp_mobile/features/auth/presentation/login_screen.dart';
import 'package:catchopp_mobile/features/auth/presentation/onboarding_screen.dart';
import 'package:catchopp_mobile/features/auth/presentation/role_choice_screen.dart';
import 'package:catchopp_mobile/features/auth/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

final _next = find.byIcon(Icons.touch_app_outlined);

/// The tap hand keeps pulsing, so the screen never "settles": pump for a while instead.
Future<void> _wait(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

/// The splash animation, then the router opens the next page with a fade.
Future<void> _pastSplash(WidgetTester tester) async {
  await tester.pump(SplashScreen.duration);
  await tester.pump(const Duration(seconds: 1));
  await _wait(tester);
}

void main() {
  testWidgets('first launch: the 3 intro pages, then the sign-up', (tester) async {
    final onboarding = FakeOnboardingStore();
    await pumpWorkify(tester, onboarding: onboarding);
    await _pastSplash(tester);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Find interesting projects'), findsOneWidget);
    await tester.tap(_next);
    await _wait(tester);
    expect(find.text('Work safely, get paid'), findsOneWidget);
    await tester.tap(_next);
    await _wait(tester);
    expect(find.text('Get started free'), findsOneWidget);
    expect(_next, findsNothing);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.byType(RoleChoiceScreen), findsOneWidget);
    expect(onboarding.done, isTrue);
  });

  testWidgets('the pages can be swiped, and skipped', (tester) async {
    final onboarding = FakeOnboardingStore();
    await pumpWorkify(tester, onboarding: onboarding);
    await _pastSplash(tester);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await _wait(tester);
    expect(find.text('Work safely, get paid'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(onboarding.done, isTrue);
  });

  testWidgets('once seen, the app goes from the splash screen to the login', (tester) async {
    await pumpWorkify(tester, onboarding: FakeOnboardingStore(done: true));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}

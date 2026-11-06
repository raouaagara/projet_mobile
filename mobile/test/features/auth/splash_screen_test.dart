import 'package:catchopp_mobile/features/auth/presentation/login_screen.dart';
import 'package:catchopp_mobile/features/auth/presentation/splash_screen.dart';
import 'package:catchopp_mobile/shared/widgets/workify_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  testWidgets('the splash screen draws the logo, with no text', (tester) async {
    await pumpWorkify(tester, onboarding: FakeOnboardingStore(done: true));
    double drawn() => tester.widget<WorkifyLogo>(find.byType(WorkifyLogo)).progress;

    expect(drawn(), 0);
    await tester.pump(SplashScreen.duration * 0.4);
    expect(drawn(), inExclusiveRange(0, 1));
    await tester.pump(SplashScreen.duration * 0.6);
    expect(drawn(), 1);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('the app leaves the splash screen once its animation has played', (tester) async {
    await pumpWorkify(tester, onboarding: FakeOnboardingStore(done: true));

    // The session is read at once, but the animation is still playing.
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}

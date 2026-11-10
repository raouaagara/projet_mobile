import 'package:catchopp_mobile/core/models/app_user.dart';
import 'package:catchopp_mobile/core/models/user_role.dart';
import 'package:catchopp_mobile/features/auth/domain/auth_session.dart';
import 'package:catchopp_mobile/features/auth/presentation/auth_controller.dart';
import 'package:catchopp_mobile/features/profile/data/leaderboard.dart';
import 'package:catchopp_mobile/features/profile/data/models/skill_test.dart';
import 'package:catchopp_mobile/features/profile/data/skill_test_repository.dart';
import 'package:catchopp_mobile/features/profile/presentation/screens/leaderboard_screen.dart';
import 'package:catchopp_mobile/features/profile/presentation/screens/skill_tests_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Me extends AuthController {
  @override
  Future<AuthSession?> build() async =>
      AuthSession(token: 't', userId: 7, email: 's@mail.com', role: UserRole.freelancer, expiresAt: DateTime(2100));
}

AppUser _user(int id, String name) =>
    AppUser(id: id, firstName: name, lastName: 'B', email: '$id@mail.com', role: UserRole.freelancer);

void main() {
  testWidgets('top freelancers: the first three on the podium, the others in the grid', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        leaderboardProvider.overrideWith((ref) async => [
              for (final (i, name) in ['Sara', 'Omar', 'Lina', 'Youssef', 'Amira'].indexed)
                LeaderboardEntry(user: _user(i + 1, name), averageRating: 5 - i * 0.2, reviewCount: 10 - i),
            ]),
      ],
      child: const MaterialApp(home: LeaderboardScreen()),
    ));
    await tester.pumpAndSettle();

    for (final name in ['Sara B', 'Omar B', 'Lina B', 'Youssef B', 'Amira B']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.byIcon(Icons.workspace_premium), findsOneWidget); // the crown of the first
    expect(find.text('#4'), findsOneWidget);
    expect(find.text('#5'), findsOneWidget);
    expect(find.text('#3'), findsNothing); // on the podium, not in the grid
  });

  testWidgets('skill tests: filter by category, passed tests are marked', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_Me.new),
        skillTestsProvider.overrideWith((ref) async => const [
              SkillTest(id: 1, title: 'Flutter fundamentals', category: 'Mobile'),
              SkillTest(id: 2, title: 'Spring Boot APIs', category: 'Backend'),
            ]),
        certificationsProvider.overrideWith((ref, id) async => const [
              Certification(id: 1, skillTestId: 1, testTitle: 'Flutter fundamentals', score: 90, passed: true),
            ]),
      ],
      child: const MaterialApp(home: SkillTestsScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.verified), findsOneWidget);
    expect(find.byIcon(Icons.phone_android), findsOneWidget); // Mobile category icon
    expect(find.byIcon(Icons.dns_outlined), findsOneWidget); // Backend category icon

    await tester.tap(find.widgetWithText(ChoiceChip, 'Backend'));
    await tester.pumpAndSettle();
    expect(find.text('Flutter fundamentals'), findsNothing);
    expect(find.text('Spring Boot APIs'), findsOneWidget);
  });
}

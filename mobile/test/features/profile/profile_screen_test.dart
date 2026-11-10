import 'package:catchopp_mobile/core/models/app_user.dart';
import 'package:catchopp_mobile/core/models/user_role.dart';
import 'package:catchopp_mobile/features/auth/domain/auth_session.dart';
import 'package:catchopp_mobile/features/auth/presentation/auth_controller.dart';
import 'package:catchopp_mobile/features/profile/data/competence_repository.dart';
import 'package:catchopp_mobile/features/profile/data/models/competence.dart';
import 'package:catchopp_mobile/features/profile/data/models/review.dart';
import 'package:catchopp_mobile/features/profile/data/models/skill_test.dart';
import 'package:catchopp_mobile/features/profile/data/profile_repository.dart';
import 'package:catchopp_mobile/features/profile/data/review_repository.dart';
import 'package:catchopp_mobile/features/profile/data/skill_test_repository.dart';
import 'package:catchopp_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _LoggedInAs extends AuthController {
  _LoggedInAs(this.session);
  final AuthSession session;

  @override
  Future<AuthSession?> build() async => session;
}

void main() {
  final client = AuthSession(
    token: 't',
    userId: 1,
    email: 'client@mail.com',
    role: UserRole.client,
    expiresAt: DateTime(2100),
  );
  const freelancer = AppUser(
    id: 7,
    firstName: 'Sara',
    lastName: 'Ben Salah',
    email: 'sara@mail.com',
    role: UserRole.freelancer,
    location: 'Tunis',
    bio: 'Flutter developer',
    website: 'sara.dev',
    competenceIds: [1],
  );
  const reviewer = AppUser(id: 1, firstName: 'Omar', lastName: 'K', email: 'o@mail.com', role: UserRole.client);

  Widget app() => ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _LoggedInAs(client)),
          userByIdProvider.overrideWith((ref, id) async => id == 7 ? freelancer : reviewer),
          competenceCatalogProvider.overrideWith((ref) async => const [
                Competence(id: 1, name: 'Flutter'),
                Competence(id: 2, name: 'Java'),
              ]),
          certificationsProvider.overrideWith((ref, id) async => const [
                Certification(id: 1, testTitle: 'Dart basics', category: 'Mobile', score: 90, passed: true),
                Certification(id: 2, testTitle: 'Failed one', score: 20),
              ]),
          reviewsAboutProvider.overrideWith((ref, key) async => const [
                Review(description: 'Excellent work', rating: 5, clientId: '1', freelancerId: '7', reviewerRole: 'CLIENT'),
                Review(description: 'Good', rating: 4, clientId: '1', freelancerId: '7', reviewerRole: 'CLIENT'),
              ]),
        ],
        child: const MaterialApp(home: ProfileScreen(userId: 7)),
      );

  testWidgets('shows a freelancer public profile', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Sara Ben Salah'), findsWidgets);
    expect(find.text('Flutter developer'), findsOneWidget);
    // The page scrolls down; certificates scroll sideways.
    final page = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;
    expect(find.text('Message Sara'), findsOneWidget); // a visitor can write to her
    await tester.scrollUntilVisible(find.text('Flutter'), 200, scrollable: page);
    expect(find.text('Flutter'), findsOneWidget); // selected skill
    expect(find.text('Java'), findsNothing); // not selected
    expect(find.byIcon(Icons.edit_outlined), findsNothing); // not my profile

    await tester.scrollUntilVisible(find.text('Dart basics'), 200, scrollable: page);
    expect(find.text('90%'), findsOneWidget); // its score
    await tester.scrollUntilVisible(find.text('Excellent work'), 200, scrollable: page);
    expect(find.text('Dart basics'), findsOneWidget); // passed certification
    expect(find.text('Failed one'), findsNothing); // failed ones are hidden
    expect(find.text('4.5'), findsWidgets); // average rating (the line under the name, and the reviews summary)
    expect(find.text('Omar K'), findsWidgets); // reviewer name
  });
}

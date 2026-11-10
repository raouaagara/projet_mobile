import 'package:catchopp_mobile/core/models/app_user.dart';
import 'package:catchopp_mobile/core/models/user_role.dart';
import 'package:catchopp_mobile/features/auth/domain/auth_session.dart';
import 'package:catchopp_mobile/features/auth/presentation/auth_controller.dart';
import 'package:catchopp_mobile/features/profile/data/competence_repository.dart';
import 'package:catchopp_mobile/features/profile/data/models/competence.dart';
import 'package:catchopp_mobile/features/profile/data/profile_repository.dart';
import 'package:catchopp_mobile/features/profile/presentation/screens/skills_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _LoggedIn extends AuthController {
  @override
  Future<AuthSession?> build() async =>
      AuthSession(token: 't', userId: 7, email: 'sara@mail.com', role: UserRole.freelancer, expiresAt: DateTime(2100));
}

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository() : super(Dio());

  List<int>? saved;

  @override
  Future<void> updateCompetences(int userId, List<int> competenceIds) async => saved = competenceIds;
}

void main() {
  const catalog = [
    Competence(id: 1, name: 'Flutter', category: 'Mobile'),
    Competence(id: 2, name: 'Docker', category: 'DevOps & Cloud'),
    Competence(id: 3, name: 'Kubernetes', category: 'DevOps & Cloud'),
    Competence(id: 4, name: 'Java', category: 'Programming languages'),
  ];
  const sara = AppUser(
    id: 7,
    firstName: 'Sara',
    lastName: 'B',
    email: 'sara@mail.com',
    role: UserRole.freelancer,
    competenceIds: [1, 2],
  );

  /// Scrolls [finder] fully into view (not under the save bar), then taps it.
  Future<void> scrollAndTap(WidgetTester tester, Finder finder, {double delta = 200}) async {
    await tester.scrollUntilVisible(finder, delta, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<_FakeProfileRepository> pumpSkills(WidgetTester tester) async {
    final repository = _FakeProfileRepository();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Profile')),
        ),
        GoRoute(path: '/skills', builder: (_, _) => const SkillsScreen()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_LoggedIn.new),
          userByIdProvider.overrideWith((ref, id) async => sara),
          currentUserProvider.overrideWith((ref) async => sara),
          competenceCatalogProvider.overrideWith((ref) async => catalog),
          profileRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.push('/skills');
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('lists my skills by category; nothing to save at first', (tester) async {
    await pumpSkills(tester);

    expect(find.text('Mobile'), findsWidgets); // the field, and its filter under "Add skills"
    expect(find.text('DevOps & Cloud'), findsWidgets);
    expect(find.text('Flutter'), findsOneWidget);
    expect(find.text('Docker'), findsOneWidget);
    expect(find.text('skills on your profile'), findsOneWidget);
    expect(find.text('All changes saved'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('add a suggestion, remove a skill, then save exactly that', (tester) async {
    final repository = await pumpSkills(tester);

    // Kubernetes is suggested: same category as Docker.
    await scrollAndTap(tester, find.text('Kubernetes'));
    expect(find.text('1 unsaved change'), findsOneWidget);
    expect(find.text('+1 added'), findsOneWidget);

    await scrollAndTap(tester, find.byTooltip('Remove Docker'), delta: -200);
    expect(find.text('2 unsaved changes'), findsOneWidget);
    expect(find.text('+1 added · −1 removed'), findsOneWidget);

    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(repository.saved, unorderedEquals([1, 3]));
    expect(find.text('Profile'), findsOneWidget); // back on the profile
  });

  testWidgets('search the catalog and add a result', (tester) async {
    await pumpSkills(tester);

    await tester.scrollUntilVisible(find.byType(TextField), 200, scrollable: find.byType(Scrollable).first);
    await tester.enterText(find.byType(TextField), 'jav');
    await tester.pumpAndSettle();
    expect(find.text('1 skill'), findsOneWidget);
    await scrollAndTap(tester, find.text('Java'));
    expect(find.text('1 unsaved change'), findsOneWidget);
    expect(find.text('Programming languages'), findsWidgets); // its category card appears
  });
}

import 'package:catchopp_mobile/core/models/app_user.dart';
import 'package:catchopp_mobile/core/models/user_role.dart';
import 'package:catchopp_mobile/features/auth/domain/auth_session.dart';
import 'package:catchopp_mobile/features/auth/presentation/auth_controller.dart';
import 'package:catchopp_mobile/features/profile/data/models/skill_test.dart';
import 'package:catchopp_mobile/features/profile/data/skill_test_repository.dart';
import 'package:catchopp_mobile/features/profile/presentation/screens/take_test_screen.dart';
import 'package:catchopp_mobile/features/profile/presentation/screens/test_result_screen.dart';
import 'package:catchopp_mobile/features/profile/profile_paths.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _LoggedIn extends AuthController {
  @override
  Future<AuthSession?> build() async => AuthSession(
      token: 't', userId: 7, email: 'sara@mail.com', role: UserRole.freelancer, expiresAt: DateTime(2100));
}

/// Records what the screen submits and scores it like the backend (all "A" are correct).
class _FakeRepository extends SkillTestRepository {
  _FakeRepository() : super(Dio());

  Map<int, String>? submitted;
  String? userName;

  @override
  Future<Certification> submit({
    required int userId,
    required int testId,
    required String userName,
    required Map<int, String> answers,
  }) async {
    submitted = answers;
    this.userName = userName;
    final score = answers.values.where((a) => a == 'A').length * 100 ~/ 2;
    return Certification(id: 1, skillTestId: testId, testTitle: 'Dart basics', score: score, passed: score >= 70);
  }
}

void main() {
  const test = SkillTest(id: 3, title: 'Dart basics', durationMinutes: 1, passScore: 70);
  const questions = [
    TestQuestion(id: 11, questionText: 'What is Dart?', optionA: 'A language', optionB: 'A database'),
    TestQuestion(id: 12, questionText: 'Who created Flutter?', optionA: 'Google', optionB: 'Apple'),
  ];

  late _FakeRepository repository;
  late ProviderContainer container;

  Widget app() {
    final router = GoRouter(
      initialLocation: ProfilePaths.takeTest(3),
      routes: [
        GoRoute(path: '/skill-tests/:id/take', builder: (context, state) => const TakeTestScreen(testId: 3)),
        GoRoute(
          path: ProfilePaths.testResult,
          builder: (context, state) => TestResultScreen(certification: state.extra as Certification?),
        ),
      ],
    );
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    );
  }

  setUp(() async {
    repository = _FakeRepository();
    container = ProviderContainer(overrides: [
      authControllerProvider.overrideWith(_LoggedIn.new),
      currentUserProvider.overrideWith((ref) async => const AppUser(
          id: 7, firstName: 'Sara', lastName: 'B', email: 'sara@mail.com', role: UserRole.freelancer)),
      skillTestProvider.overrideWith((ref, id) async => test),
      testQuestionsProvider.overrideWith((ref, id) async => questions),
      skillTestRepositoryProvider.overrideWithValue(repository),
    ]);
    // In the app, the session and profile are loaded before this page can open.
    await container.read(authControllerProvider.future);
    await container.read(currentUserProvider.future);
  });

  tearDown(() => container.dispose());

  // The test screen has a running timer, so pump explicit durations (pumpAndSettle would never settle).
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('answers every question, submits them and shows the result', (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);

    expect(find.text('Question 1 of 2'), findsOneWidget);
    expect(find.text('01:00'), findsOneWidget); // countdown from the test duration
    await tester.tap(find.text('A language'));
    await tester.tap(find.text('Next'));
    await settle(tester);

    expect(find.text('Question 2 of 2'), findsOneWidget);
    await tester.tap(find.text('Apple'));
    await tester.tap(find.text('Submit'));
    await settle(tester);

    expect(repository.submitted, {11: 'A', 12: 'B'});
    expect(repository.userName, 'Sara B');
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Not this time'), findsOneWidget);
  });

  testWidgets('asks for confirmation when questions are unanswered', (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);

    await tester.tap(find.text('A language'));
    await tester.tap(find.text('Next'));
    await settle(tester);
    await tester.tap(find.text('Submit')); // question 2 not answered
    await settle(tester);

    expect(find.text('Submit now?'), findsOneWidget);
    expect(repository.submitted, isNull);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Submit')));
    await settle(tester);

    expect(repository.submitted, {11: 'A'});
  });

  testWidgets('submits automatically when the time is up', (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);

    await tester.tap(find.text('A language'));
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('00:30'), findsOneWidget);
    await tester.pump(const Duration(seconds: 31)); // past the 1-minute limit
    await settle(tester);

    expect(repository.submitted, {11: 'A'});
    expect(find.text('50%'), findsOneWidget);
  });
}

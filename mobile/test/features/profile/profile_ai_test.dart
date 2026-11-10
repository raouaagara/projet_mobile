import 'package:catchopp_mobile/core/models/app_user.dart';
import 'package:catchopp_mobile/core/models/user_role.dart';
import 'package:catchopp_mobile/core/network/api_exception.dart';
import 'package:catchopp_mobile/features/auth/domain/auth_session.dart';
import 'package:catchopp_mobile/features/auth/presentation/auth_controller.dart';
import 'package:catchopp_mobile/features/profile/data/competence_repository.dart';
import 'package:catchopp_mobile/features/profile/data/models/competence.dart';
import 'package:catchopp_mobile/features/profile/data/models/review.dart';
import 'package:catchopp_mobile/features/profile/data/models/skill_test.dart';
import 'package:catchopp_mobile/features/profile/data/profile_ai_repository.dart';
import 'package:catchopp_mobile/features/profile/data/profile_repository.dart';
import 'package:catchopp_mobile/features/profile/data/review_repository.dart';
import 'package:catchopp_mobile/features/profile/data/skill_test_repository.dart';
import 'package:catchopp_mobile/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:catchopp_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:catchopp_mobile/features/projects/data/models/job_match.dart';
import 'package:catchopp_mobile/features/projects/presentation/project_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _LoggedIn extends AuthController {
  @override
  Future<AuthSession?> build() async =>
      AuthSession(token: 't', userId: 7, email: 'sara@mail.com', role: UserRole.freelancer, expiresAt: DateTime(2100));
}

class _FakeAi extends ProfileAiRepository {
  _FakeAi({this.down = false}) : super(Dio());

  final bool down;
  String? notes;
  List<SkillDemand>? planned;

  @override
  Future<String> writeBio(AppUser user, {String? notes}) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (down) throw const ApiException("AI isn't set up on the server yet (GEMINI_API_KEY is missing).");
    this.notes = notes;
    return 'I build mobile apps with Flutter.';
  }

  @override
  Future<List<PlanItem>> learningPlan({required List<int> skillIds, required List<SkillDemand> skills}) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    planned = skills;
    return const [
      PlanItem(skill: 'Angular', why: 'Two of your jobs pair Flutter with an Angular dashboard.',
          steps: ['Follow the official Angular tutorial', 'Build a small admin page'], weeks: 3),
    ];
  }
}

// The page's vertical list (text fields and sheets are scrollables too).
final _page = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: _page);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  const sara = AppUser(
    id: 7,
    firstName: 'Sara',
    lastName: 'B',
    email: 'sara@mail.com',
    role: UserRole.freelancer,
    competenceIds: [1],
  );

  Widget app(Widget home, _FakeAi ai, {Map<int, JobMatch> matches = const {}}) => ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_LoggedIn.new),
          userByIdProvider.overrideWith((ref, id) async => sara),
          currentUserProvider.overrideWith((ref) async => sara),
          competenceCatalogProvider.overrideWith((ref) async => const [Competence(id: 1, name: 'Flutter')]),
          certificationsProvider.overrideWith((ref, id) async => const <Certification>[]),
          reviewsAboutProvider.overrideWith((ref, key) async => const <Review>[]),
          profileAiRepositoryProvider.overrideWithValue(ai),
          jobMatchesProvider.overrideWith((ref) async => matches),
        ],
        child: MaterialApp(home: home),
      );

  testWidgets('writes the bio with AI from my notes, and can undo', (tester) async {
    final ai = _FakeAi();
    await tester.pumpWidget(app(const EditProfileScreen(), ai));
    await tester.pumpAndSettle();

    final bio = find.widgetWithText(TextFormField, 'What you do, what you are good at — or a few notes for the AI');
    await _scrollTo(tester, find.text('Write with AI'));
    await tester.enterText(bio, 'mobile dev, 3 apps');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Write with AI'));
    await tester.tap(find.text('Write with AI'));
    await tester.pumpAndSettle();

    expect(ai.notes, 'mobile dev, 3 apps');
    expect(find.text('I build mobile apps with Flutter.'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('mobile dev, 3 apps'), findsOneWidget);
  });

  testWidgets('shows the server message when the AI is not available', (tester) async {
    await tester.pumpWidget(app(const EditProfileScreen(), _FakeAi(down: true)));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Write with AI'));
    await tester.tap(find.text('Write with AI'));
    await tester.pumpAndSettle();
    expect(find.textContaining("AI isn't set up"), findsOneWidget);
  });

  testWidgets('suggests skills from jobs I almost fit, and makes a plan', (tester) async {
    final ai = _FakeAi();
    await tester.pumpWidget(app(const ProfileScreen(), ai, matches: const {
      1: JobMatch(score: 60, matched: ['Flutter'], missing: ['Angular']),
      2: JobMatch(score: 45, matched: ['Flutter'], missing: ['Angular', 'Docker']),
      3: JobMatch(score: 10, missing: ['Figma']), // too far: not counted
    }));
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('Make my learning plan'));
    expect(find.text('Worth learning next'), findsOneWidget);
    expect(find.text('2 jobs'), findsOneWidget); // Angular
    expect(find.text('1 job'), findsOneWidget); // Docker
    expect(find.text('Figma'), findsNothing);

    await tester.tap(find.text('Make my learning plan'));
    await tester.pumpAndSettle();
    expect(ai.planned!.map((s) => s.name), ['Angular', 'Docker']);
    expect(find.text('Your learning plan'), findsOneWidget);
    expect(find.text('~3 weeks'), findsOneWidget);
    expect(find.text('Build a small admin page'), findsOneWidget);
  });

  testWidgets('no suggestion card without job scores', (tester) async {
    await tester.pumpWidget(app(const ProfileScreen(), _FakeAi()));
    await tester.pumpAndSettle();
    expect(find.text('Worth learning next'), findsNothing);
  });
}

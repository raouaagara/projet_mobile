import 'package:catchopp_mobile/core/models/user_role.dart';
import 'package:catchopp_mobile/features/projects/data/models/job_match.dart';
import 'package:catchopp_mobile/features/projects/data/models/project_enums.dart';
import 'package:catchopp_mobile/features/projects/data/models/proposal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Module 2's AI: match score, recommendations, cover letter and job post writers, applicant ranking.
void main() {
  // The page's vertical list (the feed also has the tab pages and the recommendations sideways).
  final page = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;

  Future<void> scrollTo(WidgetTester tester, Finder finder, {double delta = 200}) async {
    await tester.scrollUntilVisible(finder, delta, scrollable: page);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  group('freelancer', () {
    testWidgets('sees AI recommendations and a match score on each job', (tester) async {
      final repository = FakeProjectRepository(
        projects: [project(1, title: 'Flutter app'), project(2, title: 'Logo design'), project(3, title: 'Applied job')],
        proposals: [Proposal(id: 9, bidAmount: 100, freelancerId: freelancerId, project: project(3, title: 'Applied job'))],
        matches: const {
          1: JobMatch(score: 87, matched: ['Flutter', 'Firebase']),
          3: JobMatch(score: 75, matched: ['Flutter']),
          2: JobMatch(score: 12, missing: ['Figma']),
        },
      );
      await pumpProjectsApp(tester, role: UserRole.freelancer, repository: repository);

      expect(repository.matchedSkills, [1]); // my skills were sent
      expect(find.text('Recommended for you'), findsOneWidget);
      expect(find.text('Great match'), findsOneWidget); // only job 1: job 3 is applied, job 2 scores too low
      expect(find.textContaining(r'$1,000   you know Flutter, Firebase'), findsOneWidget);

      await scrollTo(tester, find.text('87% match'));
      expect(find.text('87% match'), findsOneWidget);
      await scrollTo(tester, find.text('Logo design'));
      expect(find.text('12% match'), findsNothing); // too low to be worth a pill
    });

    testWidgets('sorts the feed by match', (tester) async {
      final repository = FakeProjectRepository(
        projects: [project(1, title: 'Old good fit'), project(2, title: 'New poor fit')],
        matches: const {1: JobMatch(score: 90), 2: JobMatch(score: 20)},
      );
      await pumpProjectsApp(tester, role: UserRole.freelancer, repository: repository);
      double top(String title) => tester.getTopLeft(find.text(title).last).dy;

      await scrollTo(tester, find.text('New poor fit'));
      expect(top('New poor fit') < top('Old good fit'), isTrue); // newest first
      await scrollTo(tester, find.text('Sort by match'), delta: -200);
      await tester.tap(find.text('Sort by match'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('New poor fit'));
      expect(top('Old good fit') < top('New poor fit'), isTrue);
    });

    testWidgets('without skills, is asked to add some', (tester) async {
      final repository = FakeProjectRepository(projects: [project(1, title: 'Flutter app')]);
      await pumpProjectsApp(tester, role: UserRole.freelancer, repository: repository, mySkills: const []);

      expect(find.text('Get jobs picked for you'), findsOneWidget);
      expect(repository.matchedSkills, isNull); // no AI call
    });

    testWidgets('the feed still works when the AI is offline', (tester) async {
      final repository = FakeProjectRepository(projects: [project(1, title: 'Flutter app')], aiDown: true);
      await pumpProjectsApp(tester, role: UserRole.freelancer, repository: repository);

      expect(find.textContaining('recommendations are unavailable'), findsOneWidget);
      await scrollTo(tester, find.text('Flutter app'));
      expect(find.text('Flutter app'), findsOneWidget);
    });

    testWidgets('sees which skills fit on the job page', (tester) async {
      final repository = FakeProjectRepository(
        projects: [project(1, title: 'Flutter app')],
        matches: const {1: JobMatch(score: 64, matched: ['Flutter'], related: ['iOS'], missing: ['Angular'])},
      );
      await pumpProjectsApp(tester, role: UserRole.freelancer, repository: repository, location: '/projects/1');

      await scrollTo(tester, find.text('Angular'));
      expect(find.text('Your match'), findsOneWidget);
      expect(find.text('Good match'), findsOneWidget);
      expect(find.text('You have 1 of the 3 skills this job asks for.'), findsOneWidget);
      expect(find.text('Close to what you know'), findsOneWidget);
      expect(find.text('To learn'), findsOneWidget);
    });

    testWidgets('writes the cover letter with AI and sends it', (tester) async {
      final repository = FakeProjectRepository(projects: [project(1, title: 'Flutter app', budget: 900)]);
      await pumpProjectsApp(tester, role: UserRole.freelancer, repository: repository, location: '/projects/1/propose');

      final letter = find.byType(TextFormField).last;
      Future<void> writeWithAi() async {
        FocusManager.instance.primaryFocus?.unfocus(); // a focused field scrolls itself back into view
        await scrollTo(tester, find.text('Write with AI'));
        await tester.tap(find.text('Write with AI'));
        await tester.pumpAndSettle();
      }

      await scrollTo(tester, find.text('Write with AI'));
      await tester.enterText(letter, 'I built 3 apps like this');
      await writeWithAi();
      await tester.pumpAndSettle();
      expect(repository.letterNotes, 'I built 3 apps like this'); // my notes go to the AI
      expect(find.text(r'Hello, I am Sara B and I can build this for $900.'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('I built 3 apps like this'), findsOneWidget);

      await writeWithAi();
      await scrollTo(tester, find.text('When will it be done?'), delta: -200);
      await tester.tap(find.text('When will it be done?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send proposal'));
      await tester.pumpAndSettle();

      expect(repository.proposals.single.coverLetter, r'Hello, I am Sara B and I can build this for $900.');
    });
  });

  group('client', () {
    testWidgets('lets the AI write the job post, and can undo it', (tester) async {
      final repository = FakeProjectRepository();
      await pumpProjectsApp(tester, role: UserRole.client, repository: repository, location: '/projects/new');

      await tester.enterText(
          find.widgetWithText(TextField, 'e.g. An app for my restaurant so customers can order and pay online'),
          'app for my restaurant');
      await tester.tap(find.text('Write my post'));
      await tester.pumpAndSettle();

      expect(repository.idea, 'app for my restaurant');
      expect(find.text('Restaurant ordering app'), findsOneWidget);
      expect(find.textContaining('The AI wrote your post and added 1 skill'), findsOneWidget);
      await scrollTo(tester, find.widgetWithText(InputChip, 'Flutter'));
      final expert = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, ExperienceLevel.expert));
      expect(expert.selected, isTrue);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Restaurant ordering app'), findsNothing);
      expect(find.widgetWithText(InputChip, 'Flutter'), findsNothing);
    });

    testWidgets('sees applicants ranked by AI match, with their cover letter', (tester) async {
      final job = project(1, title: 'Flutter app');
      const amineId = 8;
      final repository = FakeProjectRepository(
        projects: [job],
        proposals: [
          Proposal(id: 10, bidAmount: 900, freelancerId: freelancerId, project: job, coverLetter: 'Hi, I am Sara.'),
          Proposal(id: 11, bidAmount: 700, freelancerId: amineId, project: job),
        ],
        candidateMatches: const {
          freelancerId: JobMatch(score: 91, matched: ['Flutter', 'Firebase']),
          amineId: JobMatch(score: 30, missing: ['Flutter']),
        },
      );
      await pumpProjectsApp(tester, role: UserRole.client, repository: repository, location: '/projects/1/proposals');
      double top(String name) => tester.getTopLeft(find.text(name)).dy;

      expect(find.text('Ranked by AI: how well their skills fit your project.'), findsOneWidget);
      await scrollTo(tester, find.text('Amine B'));
      expect(top('Sara B') < top('Amine B'), isTrue); // best match first, though Amine applied last
      expect(find.text('91% match'), findsOneWidget);
      expect(find.text('Has Flutter, Firebase'), findsOneWidget);
      expect(find.text('Hi, I am Sara.'), findsOneWidget);

      await scrollTo(tester, find.text('Lowest bid'), delta: -200);
      await tester.tap(find.text('Lowest bid'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Sara B'));
      expect(top('Amine B') < top('Sara B'), isTrue);
    });
  });
}

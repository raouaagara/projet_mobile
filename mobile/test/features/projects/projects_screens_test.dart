import 'package:catchopp_mobile/core/models/user_role.dart';
import 'package:catchopp_mobile/features/projects/data/models/project_enums.dart';
import 'package:catchopp_mobile/features/projects/data/models/proposal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  group('client', () {
    testWidgets('sees only their projects and filters them by status', (tester) async {
      final repository = FakeProjectRepository(projects: [
        project(1, title: 'My open job'),
        project(2, title: 'My running job', status: ProjectStatus.active),
        project(3, title: 'Someone else', client: 99),
      ]);
      await pumpProjectsApp(tester, role: UserRole.client, repository: repository);

      expect(find.text('My projects'), findsOneWidget);
      expect(find.text('My open job'), findsOneWidget);
      expect(find.text('My running job'), findsOneWidget);
      expect(find.text('Someone else'), findsNothing);

      await tester.tap(find.text('In progress').first); // the status counter
      await tester.pumpAndSettle();
      expect(find.text('My open job'), findsNothing);
      expect(find.text('My running job'), findsOneWidget);
    });

    testWidgets('accepts a proposal: project goes in progress, contract is offered', (tester) async {
      final job = project(1, title: 'Flutter app');
      final repository = FakeProjectRepository(projects: [job], proposals: [
        Proposal(id: 10, bidAmount: 900, estimationEndDate: DateTime(2026, 10, 30), freelancerId: freelancerId, project: job),
      ]);
      await pumpProjectsApp(tester, role: UserRole.client, repository: repository, location: '/projects/1/proposals');

      expect(find.text('Sara B'), findsOneWidget);
      expect(find.text(r'$900'), findsWidgets);
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();
      expect(find.text('Accept this proposal?'), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Accept')));
      await tester.pumpAndSettle();

      expect(repository.proposalStatuses, {10: ProposalStatus.accepted});
      expect(repository.projectStatuses, {1: ProjectStatus.active});
      expect(find.text('Proposal accepted'), findsOneWidget);
      expect(find.text('Accepted'), findsOneWidget); // the list behind the dialog is already up to date

      // Module 3 isn't in this app: the link says so instead of crashing.
      await tester.tap(find.text('Create contract'));
      await tester.pumpAndSettle();
      expect(find.textContaining('module 3'), findsOneWidget);
      expect(find.text('Create the contract'), findsOneWidget);
      expect(find.text('Accept'), findsNothing); // the project is not open anymore
    });

    testWidgets('posts a project and lands on it', (tester) async {
      final repository = FakeProjectRepository();
      await pumpProjectsApp(tester, role: UserRole.client, repository: repository, location: '/projects/new');

      final publish = find.text('Publish project');
      Future<void> tapPublish() async {
        FocusManager.instance.primaryFocus?.unfocus(); // a focused field scrolls itself back into view
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(publish, 300, scrollable: find.byType(Scrollable).first);
        await tester.ensureVisible(publish);
        await tester.pumpAndSettle();
        await tester.tap(publish);
        await tester.pumpAndSettle();
      }

      await tapPublish();
      await tester.scrollUntilVisible(find.text('At least 5 characters'), -300, scrollable: find.byType(Scrollable).first);
      expect(find.text('At least 5 characters'), findsOneWidget);
      expect(repository.projects, isEmpty);

      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Flutter app for a restaurant'), 'Mobile app for my gym');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'What needs to be done, deliverables, deadline...'), 'Members book classes and pay online.');
      await tester.scrollUntilVisible(find.widgetWithText(TextFormField, 'e.g. 500'), 200, scrollable: find.byType(Scrollable).first);
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. 500'), '800');
      await tapPublish();

      final created = repository.projects.single;
      expect(created.title, 'Mobile app for my gym');
      expect(created.budget, 800);
      expect(created.clientId, clientId);
      expect(created.status, ProjectStatus.open);
      expect(created.experienceLevel, ExperienceLevel.intermediate);
      expect(find.text('View proposals (0)'), findsOneWidget); // details page of the new project
    });
  });

  group('freelancer', () {
    testWidgets('searches the feed of open jobs', (tester) async {
      final repository = FakeProjectRepository(projects: [
        project(1, title: 'Flutter app'),
        project(2, title: 'Logo design'),
        project(3, title: 'Closed job', status: ProjectStatus.closed),
      ]);
      await pumpProjectsApp(tester, role: UserRole.freelancer, repository: repository);

      expect(find.text('2 open jobs'), findsOneWidget);
      expect(find.text('Closed job'), findsNothing);
      await tester.enterText(find.byType(TextField), 'logo');
      await tester.pumpAndSettle();
      expect(find.text('1 open job'), findsOneWidget);
      expect(find.text('Flutter app'), findsNothing);
      expect(find.text('Logo design'), findsOneWidget);
    });

    testWidgets('sends a proposal, then sees it instead of the button', (tester) async {
      final repository = FakeProjectRepository(projects: [project(1, title: 'Flutter app', budget: 1200)]);
      await pumpProjectsApp(tester, role: UserRole.freelancer, repository: repository, location: '/projects/1');

      await tester.scrollUntilVisible(find.text('Karim B'), 200, scrollable: find.byType(Scrollable).first); // lower on the page
      expect(find.text('Karim B'), findsOneWidget);
      await tester.tap(find.text('Submit a proposal'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '1000'); // the bid
      await tester.tap(find.text('Send proposal'));
      await tester.pumpAndSettle();
      expect(find.text('Pick a delivery date'), findsOneWidget);

      await tester.tap(find.text('When will it be done?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send proposal'));
      await tester.pumpAndSettle();

      final sent = repository.proposals.single;
      expect(sent.bidAmount, 1000);
      expect(sent.freelancerId, freelancerId);
      expect(sent.estimationEndDate!.isAfter(DateTime.now()), isTrue);
      // Back on the project page.
      expect(find.text('Submit a proposal'), findsNothing);
      expect(find.text(r'You bid $1,000'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('cannot apply to a project that is not open', (tester) async {
      final repository = FakeProjectRepository(projects: [project(1, status: ProjectStatus.active)]);
      await pumpProjectsApp(tester, role: UserRole.freelancer, repository: repository, location: '/projects/1');

      expect(find.text('Submit a proposal'), findsNothing);
      expect(find.text('This project is not accepting proposals anymore.'), findsOneWidget);
    });
  });
}

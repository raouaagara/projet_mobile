import 'package:catchopp_mobile/core/models/user_role.dart';
import 'package:catchopp_mobile/core/storage/local_db.dart';
import 'package:catchopp_mobile/features/auth/domain/auth_session.dart';
import 'package:catchopp_mobile/features/auth/presentation/auth_controller.dart';
import 'package:catchopp_mobile/features/profile/data/learning_tracker.dart';
import 'package:catchopp_mobile/features/profile/data/profile_ai_repository.dart';
import 'package:catchopp_mobile/features/profile/presentation/screens/learning_tracker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _LoggedIn extends AuthController {
  @override
  Future<AuthSession?> build() async =>
      AuthSession(token: 't', userId: 7, email: 's@mail.com', role: UserRole.freelancer, expiresAt: DateTime(2100));
}

const angular = PlanItem(
  skill: 'Angular',
  why: 'Two jobs pair Flutter with an Angular dashboard.',
  steps: ['Follow the Tour of Heroes tutorial', 'Build a small admin page', 'Add Angular to your profile'],
  weeks: 3,
);

void main() {
  sqfliteFfiInit();
  late LocalDb db;

  setUp(() => db = LocalDb.inMemory(databaseFactoryFfi));
  tearDown(() => db.close());

  group('LearningTracker (SQLite)', () {
    test('create, read, update and delete a tracked skill and its steps', () async {
      final tracker = LearningTracker(db);

      final id = await tracker.track(7, angular);
      var list = await tracker.list(7);
      expect(list.single.skill, 'Angular');
      expect(list.single.steps.map((s) => s.text), angular.steps);
      expect(await tracker.list(8), isEmpty); // another user's list

      final first = list.single.steps.first;
      await tracker.setDone(first.id, true);
      await tracker.renameStep(first.id, 'Finish the Tour of Heroes');
      await tracker.addStep(id, 'Push it to GitHub');
      await tracker.deleteStep(list.single.steps.last.id);
      list = await tracker.list(7);
      expect(list.single.steps.map((s) => s.text),
          ['Finish the Tour of Heroes', 'Build a small admin page', 'Push it to GitHub']);
      expect(list.single.done, 1);

      await tracker.delete(id);
      expect(await tracker.list(7), isEmpty);
      final orphans = await (await db.database).query('learning_step');
      expect(orphans, isEmpty); // ON DELETE CASCADE
    });

    test('tracking the same skill again replaces its steps', () async {
      final tracker = LearningTracker(db);
      await tracker.track(7, angular);
      await tracker.track(7, const PlanItem(skill: 'Angular', why: 'New', steps: ['One step'], weeks: 2));
      final list = await tracker.list(7);
      expect(list.single.steps.single.text, 'One step');
      expect(list.single.weeks, 2);
    });
  });

  testWidgets('the screen ticks, adds and deletes, all kept in the database', (tester) async {
    await tester.runAsync(() => LearningTracker(db).track(7, angular));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_LoggedIn.new),
        localDbProvider.overrideWithValue(db),
      ],
      child: const MaterialApp(home: LearningTrackerScreen()),
    ));
    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
      }
    }

    await settle();
    expect(find.text('Angular'), findsOneWidget);
    expect(find.text('0 of 3 steps'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).first);
    await settle();
    expect(find.text('1 of 3 steps'), findsOneWidget);

    await tester.tap(find.text('Add a step'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Push it to GitHub');
    await tester.tap(find.text('Save'));
    await settle();
    await tester.pumpAndSettle(); // the dialog's closing animation
    expect(find.text('Push it to GitHub'), findsOneWidget);
    expect(find.text('1 of 4 steps'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete Angular'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await settle();
    await tester.pumpAndSettle();
    expect(find.textContaining('Nothing tracked yet'), findsOneWidget);
    expect(await tester.runAsync(() => LearningTracker(db).list(7)), isEmpty);
  });
}

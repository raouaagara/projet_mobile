import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/storage/local_db.dart';
import '../../auth/presentation/auth_controller.dart';
import 'profile_ai_repository.dart';

/// A skill the freelancer is learning, saved on the phone (SQLite), with its steps.
class TrackedSkill {
  const TrackedSkill({
    required this.id,
    required this.skill,
    this.why = '',
    this.weeks = 4,
    required this.createdAt,
    this.steps = const [],
  });

  final int id;
  final String skill;
  final String why;
  final int weeks;
  final DateTime createdAt;
  final List<TrackedStep> steps;

  int get done => steps.where((s) => s.done).length;

  /// 0–1.
  double get progress => steps.isEmpty ? 0 : done / steps.length;
}

class TrackedStep {
  const TrackedStep({required this.id, required this.position, required this.text, this.done = false});

  final int id;
  final int position;
  final String text;
  final bool done;
}

/// Module 1's SQLite tables: the learning plans the freelancer keeps, and their steps.
/// Deleting a plan deletes its steps (foreign key, ON DELETE CASCADE).
class LearningTracker {
  LearningTracker(this._db);

  final LocalDb _db;

  static const create = [
    'CREATE TABLE IF NOT EXISTS learning_plan ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'user_id INTEGER NOT NULL, '
        'skill TEXT NOT NULL, '
        'why TEXT NOT NULL DEFAULT \'\', '
        'weeks INTEGER NOT NULL DEFAULT 4, '
        'created_at INTEGER NOT NULL, '
        'UNIQUE (user_id, skill))',
    'CREATE TABLE IF NOT EXISTS learning_step ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'plan_id INTEGER NOT NULL REFERENCES learning_plan(id) ON DELETE CASCADE, '
        'position INTEGER NOT NULL, '
        'text TEXT NOT NULL, '
        'done INTEGER NOT NULL DEFAULT 0)',
  ];

  Future<Database> get _tables => _db.table(create);

  /// [userId]'s skills, newest first, each with its steps in order.
  Future<List<TrackedSkill>> list(int userId) async {
    final db = await _tables;
    final plans = await db.query(
      'learning_plan',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC, id DESC',
    );
    if (plans.isEmpty) return [];
    final ids = [for (final p in plans) p['id']! as int];
    final steps = await db.query(
      'learning_step',
      where: 'plan_id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
      orderBy: 'position, id',
    );
    return [
      for (final p in plans)
        TrackedSkill(
          id: p['id']! as int,
          skill: p['skill']! as String,
          why: p['why']! as String,
          weeks: p['weeks']! as int,
          createdAt: DateTime.fromMillisecondsSinceEpoch(p['created_at']! as int),
          steps: [
            for (final s in steps)
              if (s['plan_id'] == p['id'])
                TrackedStep(
                  id: s['id']! as int,
                  position: s['position']! as int,
                  text: s['text']! as String,
                  done: s['done'] == 1,
                ),
          ],
        ),
    ];
  }

  /// Saves an AI plan item; tracking the same skill again replaces its steps.
  Future<int> track(int userId, PlanItem item) async {
    final db = await _tables;
    return db.transaction((txn) async {
      final existing = await txn.query(
        'learning_plan',
        columns: ['id'],
        where: 'user_id = ? AND skill = ?',
        whereArgs: [userId, item.skill],
        limit: 1,
      );
      final int planId;
      if (existing.isEmpty) {
        planId = await txn.insert('learning_plan', {
          'user_id': userId,
          'skill': item.skill,
          'why': item.why,
          'weeks': item.weeks,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        planId = existing.first['id']! as int;
        await txn.update('learning_plan', {'why': item.why, 'weeks': item.weeks}, where: 'id = ?', whereArgs: [planId]);
        await txn.delete('learning_step', where: 'plan_id = ?', whereArgs: [planId]);
      }
      for (final (i, step) in item.steps.indexed) {
        await txn.insert('learning_step', {'plan_id': planId, 'position': i, 'text': step, 'done': 0});
      }
      return planId;
    });
  }

  Future<void> setDone(int stepId, bool done) async =>
      (await _tables).update('learning_step', {'done': done ? 1 : 0}, where: 'id = ?', whereArgs: [stepId]);

  Future<void> renameStep(int stepId, String text) async =>
      (await _tables).update('learning_step', {'text': text}, where: 'id = ?', whereArgs: [stepId]);

  /// Adds a step at the end of [planId].
  Future<int> addStep(int planId, String text) async {
    final db = await _tables;
    final last =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT MAX(position) FROM learning_step WHERE plan_id = ?', [planId]),
        ) ??
        -1;
    return db.insert('learning_step', {'plan_id': planId, 'position': last + 1, 'text': text, 'done': 0});
  }

  Future<void> deleteStep(int stepId) async =>
      (await _tables).delete('learning_step', where: 'id = ?', whereArgs: [stepId]);

  /// Deletes a skill and, through the foreign key, its steps.
  Future<void> delete(int planId) async =>
      (await _tables).delete('learning_plan', where: 'id = ?', whereArgs: [planId]);
}

final learningTrackerProvider = Provider((ref) => LearningTracker(ref.watch(localDbProvider)));

/// The logged-in freelancer's tracked skills; every change goes through here so the screens follow.
final trackedSkillsProvider = AsyncNotifierProvider<TrackedSkillsController, List<TrackedSkill>>(
  TrackedSkillsController.new,
);

class TrackedSkillsController extends AsyncNotifier<List<TrackedSkill>> {
  LearningTracker get _tracker => ref.read(learningTrackerProvider);

  Future<int?> get _userId async => (await ref.read(authControllerProvider.future))?.userId;

  @override
  Future<List<TrackedSkill>> build() async {
    final session = await ref.watch(authControllerProvider.future);
    if (session == null) return [];
    return ref.watch(learningTrackerProvider).list(session.userId);
  }

  Future<void> _reload() async {
    final userId = await _userId;
    if (userId != null) state = AsyncData(await _tracker.list(userId));
  }

  Future<void> track(PlanItem item) async {
    final userId = await _userId;
    if (userId == null) return;
    await _tracker.track(userId, item);
    await _reload();
  }

  Future<void> setDone(TrackedStep step, bool done) async {
    await _tracker.setDone(step.id, done);
    await _reload();
  }

  Future<void> renameStep(TrackedStep step, String text) async {
    await _tracker.renameStep(step.id, text);
    await _reload();
  }

  Future<void> addStep(TrackedSkill skill, String text) async {
    await _tracker.addStep(skill.id, text);
    await _reload();
  }

  Future<void> deleteStep(TrackedStep step) async {
    await _tracker.deleteStep(step.id);
    await _reload();
  }

  Future<void> delete(TrackedSkill skill) async {
    await _tracker.delete(skill.id);
    await _reload();
  }
}

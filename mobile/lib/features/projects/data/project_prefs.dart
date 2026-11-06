import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final projectPrefsProvider = Provider((ref) => ProjectPrefs());

/// Small per-user data kept on the phone, because the backend has no endpoint
/// for it (the web app keeps the same things in localStorage):
/// saved jobs and the reaction left on each project.
class ProjectPrefs {
  ProjectPrefs([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<Set<int>> savedJobs(int userId) async {
    final raw = await read('saved_jobs_$userId');
    if (raw == null) return {};
    return (jsonDecode(raw) as List<dynamic>).map((e) => (e as num).toInt()).toSet();
  }

  Future<void> setSavedJobs(int userId, Set<int> projectIds) =>
      write('saved_jobs_$userId', jsonEncode(projectIds.toList()));

  /// project id → reaction name (`LIKE`, `LOVE`...).
  Future<Map<int, String>> reactions(int userId) async {
    final raw = await read('project_reactions_$userId');
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>).map((key, value) => MapEntry(int.parse(key), value as String));
  }

  Future<void> setReactions(int userId, Map<int, String> reactions) =>
      write('project_reactions_$userId', jsonEncode(reactions.map((key, value) => MapEntry('$key', value))));

  // Overridden in tests.
  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
}

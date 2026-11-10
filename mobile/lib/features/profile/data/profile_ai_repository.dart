import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../projects/data/models/job_match.dart';

final profileAiRepositoryProvider = Provider((ref) => ProfileAiRepository(ref.watch(dioProvider)));

/// One skill of an AI learning plan.
class PlanItem {
  const PlanItem({required this.skill, required this.why, required this.steps, required this.weeks});

  final String skill;
  final String why;
  final List<String> steps;

  /// Part-time weeks, 1–12.
  final int weeks;

  factory PlanItem.fromJson(Map<String, dynamic> json) => PlanItem(
        skill: json['skill'] as String? ?? '',
        why: json['why'] as String? ?? '',
        steps: [for (final s in json['steps'] as List<dynamic>? ?? []) s as String],
        weeks: (json['weeks'] as num?)?.toInt() ?? 4,
      );
}

/// Profile AI of module 1 (`/Competance/ai/**`, Gemini on the server).
class ProfileAiRepository {
  ProfileAiRepository(this._dio);

  final Dio _dio;

  /// An "About me" text (at most 250 characters) from [user]'s skills and the [notes] they typed.
  Future<String> writeBio(AppUser user, {String? notes}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/Competance/ai/bio', data: {
        'firstName': user.firstName,
        'role': user.role.name.toUpperCase(),
        'location': ?user.location,
        'skillIds': user.competenceIds,
        'notes': ?notes,
      });
      return res.data!['bio'] as String? ?? '';
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// A short plan to learn [skills], building on the skills in [skillIds].
  Future<List<PlanItem>> learningPlan({required List<int> skillIds, required List<SkillDemand> skills}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/Competance/ai/learning-plan', data: {
        'skillIds': skillIds,
        'skills': [for (final s in skills) s.toJson()],
      });
      return [for (final item in res.data!['plan'] as List<dynamic>) PlanItem.fromJson(item as Map<String, dynamic>)];
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}

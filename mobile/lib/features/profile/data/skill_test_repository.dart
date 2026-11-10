import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import 'models/cv_analysis.dart';
import 'models/skill_test.dart';

final skillTestRepositoryProvider =
    Provider((ref) => SkillTestRepository(ref.watch(dioProvider)));

final skillTestsProvider = FutureProvider<List<SkillTest>>(
    (ref) => ref.watch(skillTestRepositoryProvider).fetchTests());

final skillTestProvider = FutureProvider.family<SkillTest, int>(
    (ref, id) => ref.watch(skillTestRepositoryProvider).fetchTest(id));

final testQuestionsProvider = FutureProvider.family<List<TestQuestion>, int>(
    (ref, testId) => ref.watch(skillTestRepositoryProvider).fetchQuestions(testId));

/// Certifications of a user, newest first.
final certificationsProvider = FutureProvider.family<List<Certification>, int>(
    (ref, userId) => ref.watch(skillTestRepositoryProvider).fetchCertifications(userId));

final skillCategoriesProvider = FutureProvider<List<String>>(
    (ref) => ref.watch(skillTestRepositoryProvider).fetchCategories());

/// SkillTestsMicroService endpoints (`/SkillTests/**`).
class SkillTestRepository {
  SkillTestRepository(this._dio);

  final Dio _dio;

  /// AI calls can take much longer than regular requests.
  static final _aiOptions = Options(receiveTimeout: const Duration(seconds: 90));

  Future<List<String>> fetchCategories() async {
    try {
      final res = await _dio.get<List<dynamic>>('/SkillTests/categories');
      return res.data!.map((e) => e.toString()).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Creates a new test with questions written by the AI (503 with a message without an AI key).
  /// Only call it when `aiAccessProvider` is true.
  Future<SkillTest> generateAiTest({
    required int userId,
    required String userName,
    required String category,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/SkillTests/ai/generate',
        data: {'userId': userId, 'userName': userName, 'category': category, 'hasAiAccess': true},
        options: _aiOptions,
      );
      return SkillTest.fromJson(res.data!);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<CvAnalysis> analyzeCvText({required String cvText, required String targetDomain}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/SkillTests/ai/cv/analyze-text',
        data: {'cvText': cvText, 'targetDomain': targetDomain},
        options: _aiOptions,
      );
      return CvAnalysis.fromJson(res.data!);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<CvAnalysis> analyzeCvImage({
    required List<int> bytes,
    required String mimeType,
    required String targetDomain,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/SkillTests/ai/cv/analyze-image',
        data: {'imageBase64': base64Encode(bytes), 'mimeType': mimeType, 'targetDomain': targetDomain},
        options: _aiOptions,
      );
      return CvAnalysis.fromJson(res.data!);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<SkillTest>> fetchTests() async {
    try {
      final res = await _dio.get<List<dynamic>>('/SkillTests/tests');
      return res.data!.map((e) => SkillTest.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<SkillTest> fetchTest(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/SkillTests/tests/$id');
      return SkillTest.fromJson(res.data!);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<TestQuestion>> fetchQuestions(int testId) async {
    try {
      final res = await _dio.get<List<dynamic>>('/SkillTests/tests/$testId/questions');
      return res.data!.map((e) => TestQuestion.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// [answers] maps question id → chosen letter ("A".."D"). The server scores it.
  Future<Certification> submit({
    required int userId,
    required int testId,
    required String userName,
    required Map<int, String> answers,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/SkillTests/submit-with-name',
        queryParameters: {'userId': userId, 'testId': testId, 'userName': userName},
        data: answers.map((id, letter) => MapEntry(id.toString(), letter)),
      );
      return Certification.fromJson(res.data!);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<Certification>> fetchCertifications(int userId) async {
    try {
      final res = await _dio.get<List<dynamic>>('/SkillTests/certifications/user/$userId');
      return res.data!.map((e) => Certification.fromJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => (b.completedAt ?? DateTime(0)).compareTo(a.completedAt ?? DateTime(0)));
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import 'models/competence.dart';
import 'models/cv_extraction.dart';

final competenceRepositoryProvider =
    Provider((ref) => CompetenceRepository(ref.watch(dioProvider)));

/// The whole skill catalog, sorted by name.
final competenceCatalogProvider = FutureProvider<List<Competence>>(
    (ref) => ref.watch(competenceRepositoryProvider).fetchCatalog());

/// Skill catalog endpoints (`/Competance/**`).
class CompetenceRepository {
  CompetenceRepository(this._dio);

  final Dio _dio;

  Future<List<Competence>> fetchCatalog() async {
    try {
      final res = await _dio.get<List<dynamic>>('/Competance/GetAllCompetance');
      return res.data!.map((e) => Competence.fromJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Sends a PDF CV (French or English). The AI service returns the catalog skills
  /// found in it, with confidence and the CV text that matched.
  Future<CvExtraction> parseCv({required List<int> bytes, required String fileName}) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });
      final res = await _dio.post<Map<String, dynamic>>(
        '/Competance/ParseCV/details',
        data: form,
        options: Options(receiveTimeout: const Duration(seconds: 90)),
      );
      return CvExtraction.fromJson(res.data!);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/models/app_user.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';

final profileRepositoryProvider =
    Provider((ref) => ProfileRepository(ref.watch(dioProvider)));

/// Any user by id, cached. Other modules can use it to show names/avatars:
///   ref.watch(userByIdProvider(contract.freelancerId))
final userByIdProvider = FutureProvider.family<AppUser, int>(
    (ref, id) => ref.watch(profileRepositoryProvider).fetchUser(id));

final allUsersProvider = FutureProvider<List<AppUser>>(
    (ref) => ref.watch(profileRepositoryProvider).fetchAll());

/// UserMicroService profile endpoints (`/users/**`).
class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  Future<AppUser> fetchUser(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/users/$id');
      return AppUser.fromJson(res.data!);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<AppUser>> fetchAll() async {
    try {
      final res = await _dio.get<List<dynamic>>('/users/all');
      return res.data!.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// The backend overwrites every profile field (including the pictures),
  /// so always send the full user, not only the changed fields.
  Future<AppUser> updateProfile(int id, Map<String, dynamic> user) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>('/users/update/$id', data: user);
      return AppUser.fromJson(res.data!);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> updateCompetences(int userId, List<int> competenceIds) async {
    try {
      await _dio.post<dynamic>('/users/$userId/competences', data: competenceIds);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> uploadCv(int userId, {required List<int> bytes, required String fileName}) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });
      await _dio.post<dynamic>('/users/$userId/upload-cv', data: form);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  String cvDownloadUrl(String fileName) =>
      '${Env.apiBaseUrl}/users/download-cv/${Uri.encodeComponent(fileName)}';
}

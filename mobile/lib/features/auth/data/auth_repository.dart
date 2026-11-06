import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/user_role.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository(ref.watch(dioProvider)));

/// UserMicroService auth endpoints (through the gateway: `/users/**`).
class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  /// Returns the raw JWT.
  Future<String> login({required String email, required String password}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/users/login',
        data: {'email': email, 'password': password},
      );
      return res.data!['token'] as String;
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
    String? country,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/users/register',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'role': role.apiValue,
          // Saved as the user's location (UserMicroService has no separate country).
          'location': ?country,
        },
      );
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<AppUser> fetchUser(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/users/$id');
      return AppUser.fromJson(res.data!);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}

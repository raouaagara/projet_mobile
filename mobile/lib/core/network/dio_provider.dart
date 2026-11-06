import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../config/env.dart';
import '../storage/token_storage.dart';

/// The single HTTP client of the app. Every repository should use it:
///
///   final dio = ref.watch(dioProvider);
///   final res = await dio.get('/Project/allprojects');
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: Env.connectTimeout,
      receiveTimeout: Env.receiveTimeout,
      contentType: Headers.jsonContentType,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.readToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // The backend doesn't enforce auth yet; once the gateway validates
        // the JWT, an expired token will log the user out here.
        final isLogin = error.requestOptions.path.endsWith('/users/login');
        if (error.response?.statusCode == 401 && !isLogin) {
          ref.read(authControllerProvider.notifier).logout();
        }
        handler.next(error);
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: false,
        logPrint: (line) => debugPrint(line.toString()),
      ),
    );
  }

  return dio;
});

import 'package:dio/dio.dart';

/// Error with a message that is safe to show to the user.
///
/// Repositories should catch errors and rethrow `ApiException.from(e)` so
/// screens only ever deal with one error type.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.from(Object error) {
    if (error is ApiException) return error;
    if (error is! DioException) return ApiException(error.toString());

    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'Cannot reach the server. Check that the backend is running '
          'and that API_BASE_URL points to the gateway.',
        );
      default:
        break;
    }

    final status = error.response?.statusCode;
    final data = error.response?.data;
    // The Spring services mostly return plain-text error bodies
    // (e.g. "Email ou mot de passe incorrect."), sometimes JSON.
    if (data is String && data.trim().isNotEmpty && data.length < 300) {
      return ApiException(data.trim(), statusCode: status);
    }
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.isNotEmpty) {
        return ApiException(message, statusCode: status);
      }
    }
    return ApiException(
      'Request failed${status != null ? ' ($status)' : ''}.',
      statusCode: status,
    );
  }

  @override
  String toString() => message;
}

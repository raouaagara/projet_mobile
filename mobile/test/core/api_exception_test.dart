import 'package:catchopp_mobile/core/network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException dioError({Object? data, int? status, DioExceptionType? type}) {
  final options = RequestOptions(path: '/users/login');
  return DioException(
    requestOptions: options,
    type: type ?? DioExceptionType.badResponse,
    response: status == null
        ? null
        : Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  test('uses the plain-text body sent by Spring', () {
    final e = ApiException.from(dioError(status: 401, data: 'Email ou mot de passe incorrect.'));
    expect(e.message, 'Email ou mot de passe incorrect.');
    expect(e.statusCode, 401);
  });

  test('uses the message field of a JSON body', () {
    final e = ApiException.from(dioError(status: 400, data: {'message': 'Invalid code'}));
    expect(e.message, 'Invalid code');
  });

  test('explains connection failures', () {
    final e = ApiException.from(dioError(type: DioExceptionType.connectionError));
    expect(e.message, contains('Cannot reach the server'));
  });
}

import 'dart:convert';

import 'package:catchopp_mobile/core/models/user_role.dart';
import 'package:catchopp_mobile/features/auth/domain/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds an unsigned JWT shaped like the one UserMicroService returns.
String fakeJwt(Map<String, dynamic> claims) {
  String part(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part(claims)}.signature';
}

void main() {
  test('decodes id, email and role from the backend token', () {
    final exp = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
    final session = AuthSession.fromToken(
      fakeJwt({'sub': 'sara@mail.com', 'id': 42, 'role': 'FREELANCER', 'exp': exp}),
    );

    expect(session.userId, 42);
    expect(session.email, 'sara@mail.com');
    expect(session.role, UserRole.freelancer);
    expect(session.isFreelancer, isTrue);
    expect(session.isExpired, isFalse);
  });

  test('detects an expired token', () {
    final exp = DateTime.now().subtract(const Duration(minutes: 1)).millisecondsSinceEpoch ~/ 1000;
    final session = AuthSession.fromToken(
      fakeJwt({'sub': 'a@b.c', 'id': 1, 'role': 'CLIENT', 'exp': exp}),
    );

    expect(session.isClient, isTrue);
    expect(session.isExpired, isTrue);
  });
}

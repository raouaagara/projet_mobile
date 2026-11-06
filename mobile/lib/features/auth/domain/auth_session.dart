import 'package:jwt_decoder/jwt_decoder.dart';

import '../../../core/models/user_role.dart';

/// The logged-in user, decoded from the JWT returned by `POST /users/login`.
///
/// Token claims: `sub` = email, `id` = user id, `role` = CLIENT | FREELANCER | ADMIN.
class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.email,
    required this.role,
    required this.expiresAt,
  });

  factory AuthSession.fromToken(String token) {
    final claims = JwtDecoder.decode(token);
    return AuthSession(
      token: token,
      userId: (claims['id'] as num).toInt(),
      email: claims['sub'] as String? ?? '',
      role: UserRole.fromApi(claims['role'] as String?),
      expiresAt: JwtDecoder.getExpirationDate(token),
    );
  }

  final String token;
  final int userId;
  final String email;
  final UserRole role;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isClient => role == UserRole.client;
  bool get isFreelancer => role == UserRole.freelancer;
}

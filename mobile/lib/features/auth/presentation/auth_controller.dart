import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/user_role.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../domain/auth_session.dart';

/// Current session, or `null` when logged out. The router listens to it.
///
/// In any module:
///   final session = ref.watch(authControllerProvider).value;
///   session?.userId / session?.role
final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

/// Full profile of the logged-in user (name, avatar...), refetched on login.
/// After editing the profile, call `ref.invalidate(currentUserProvider)`.
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final session = await ref.watch(authControllerProvider.future);
  if (session == null) return null;
  return ref.watch(authRepositoryProvider).fetchUser(session.userId);
});

class AuthController extends AsyncNotifier<AuthSession?> {
  TokenStorage get _storage => ref.read(tokenStorageProvider);
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<AuthSession?> build() async {
    final String? token;
    try {
      token = await _storage.readToken();
    } on Object {
      // Unreadable storage (restored from a backup without its key, written by another build of
      // the app…). Riverpod would retry this forever and keep the splash screen: log out instead.
      await _clearQuietly();
      return null;
    }
    if (token == null) return null;
    try {
      final session = AuthSession.fromToken(token);
      if (!session.isExpired) return session;
    } on Object {
      // Corrupted token: fall through and clear it.
    }
    await _clearQuietly();
    return null;
  }

  Future<void> _clearQuietly() async {
    try {
      await _storage.clear();
    } on Object {
      // The token is already dropped from memory, which is enough to log out.
    }
  }

  /// Throws [ApiException] with a user-facing message on failure.
  Future<void> login(String email, String password) async {
    final token = await _repository.login(email: email.trim(), password: password);
    final session = AuthSession.fromToken(token);
    if (!session.isClient && !session.isFreelancer) {
      throw const ApiException('Admin accounts must use the web dashboard.');
    }
    await _storage.saveToken(token);
    state = AsyncData(session);
  }

  /// Creates the account, then logs in with it.
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
    String? country,
  }) async {
    await _repository.register(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim(),
      password: password,
      role: role,
      country: country,
    );
    await login(email, password);
  }

  Future<void> logout() async {
    await _storage.clear();
    state = const AsyncData(null);
  }
}

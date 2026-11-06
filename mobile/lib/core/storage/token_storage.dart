import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Persists the JWT in the Android Keystore-backed secure storage and keeps
/// an in-memory copy so the HTTP interceptor doesn't hit the disk per request.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';

  final FlutterSecureStorage _storage;
  String? _cached;
  bool _loaded = false;

  Future<String?> readToken() async {
    if (!_loaded) {
      _cached = await _storage.read(key: _tokenKey);
      _loaded = true;
    }
    return _cached;
  }

  Future<void> saveToken(String token) async {
    _cached = token;
    _loaded = true;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    await _storage.delete(key: _tokenKey);
  }
}

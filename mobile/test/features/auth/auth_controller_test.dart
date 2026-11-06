import 'package:catchopp_mobile/core/storage/token_storage.dart';
import 'package:catchopp_mobile/features/auth/presentation/auth_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Secure storage that can't decrypt what it holds, like after an Android backup restore.
class _UnreadableTokenStorage extends TokenStorage {
  bool cleared = false;

  @override
  Future<String?> readToken() async => throw PlatformException(code: 'Exception encountered', message: 'read');

  @override
  Future<void> clear() async {
    cleared = true;
    throw PlatformException(code: 'Exception encountered', message: 'delete');
  }
}

class _MemoryTokenStorage extends TokenStorage {
  _MemoryTokenStorage(this.token);

  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> clear() async => token = null;
}

void main() {
  test('an unreadable token logs out instead of keeping the splash screen', () async {
    final storage = _UnreadableTokenStorage();
    final container = ProviderContainer(overrides: [tokenStorageProvider.overrideWithValue(storage)]);
    addTearDown(container.dispose);

    expect(await container.read(authControllerProvider.future), isNull);
    expect(storage.cleared, isTrue);
  });

  test('a corrupted token is cleared', () async {
    final storage = _MemoryTokenStorage('not-a-jwt');
    final container = ProviderContainer(overrides: [tokenStorageProvider.overrideWithValue(storage)]);
    addTearDown(container.dispose);

    expect(await container.read(authControllerProvider.future), isNull);
    expect(storage.token, isNull);
  });
}

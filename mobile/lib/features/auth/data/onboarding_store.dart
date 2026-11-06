import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final onboardingStoreProvider = Provider<OnboardingStore>((ref) => OnboardingStore());

/// Remembers that the intro pages were seen, so they only show on the first launch.
class OnboardingStore {
  OnboardingStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'onboarding_done';

  final FlutterSecureStorage _storage;

  Future<bool> isDone() async => await _storage.read(key: _key) == 'true';

  Future<void> markDone() => _storage.write(key: _key, value: 'true');
}

/// Whether the intro pages were already seen. The router shows them to logged-out users until then.
final onboardingDoneProvider = AsyncNotifierProvider<OnboardingDone, bool>(OnboardingDone.new);

class OnboardingDone extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    try {
      return await ref.read(onboardingStoreProvider).isDone();
    } on Object {
      return false; // Unreadable storage: show the intro again rather than retrying forever.
    }
  }

  Future<void> complete() async {
    state = const AsyncData(true);
    try {
      await ref.read(onboardingStoreProvider).markDone();
    } on Object {
      // Not saved: the intro shows once more on the next launch, nothing worse.
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../auth/presentation/auth_controller.dart';

/// AI features (CV assistant, AI-generated tests) need an ACTIVE Premium or
/// Enterprise subscription — same rule as the web app.
///
/// Subscriptions belong to module 5; this only reads the active plan.
/// Any error (no subscription, service down) means "no access".
/// autoDispose: re-checked each time an AI screen opens (e.g. right after upgrading).
final aiAccessProvider = FutureProvider.autoDispose<bool>((ref) async {
  final session = await ref.watch(authControllerProvider.future);
  if (session == null) return false;
  try {
    final res = await ref
        .watch(dioProvider)
        .get<dynamic>('/Subscription/user/${session.userId}/active');
    final data = res.data;
    if (data is! Map) return false; // 204 No Content = no active subscription
    final plan = data['plan'];
    final type = plan is Map ? plan['type']?.toString().toUpperCase() : null;
    return data['status'] == 'ACTIVE' && (type == 'PREMIUM' || type == 'ENTERPRISE');
  } catch (_) {
    return false;
  }
});

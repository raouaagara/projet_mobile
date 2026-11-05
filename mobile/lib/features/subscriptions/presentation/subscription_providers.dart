import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/user_role.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/models/referral_models.dart';
import '../data/models/reward_models.dart';
import '../data/models/subscription_models.dart';
import '../data/referral_repository.dart';
import '../data/subscription_repository.dart';

/// Runs [load] with the logged-in user's id (empty/null result when logged out).
Future<T> _forUser<T>(Ref ref, T whenLoggedOut, Future<T> Function(int userId) load) async {
  final session = await ref.watch(authControllerProvider.future);
  if (session == null) return whenLoggedOut;
  return load(session.userId);
}

// ── Subscriptions ──────────────────────────────────────────────────

final plansProvider = FutureProvider<List<SubscriptionPlan>>(
  (ref) => ref.watch(subscriptionRepositoryProvider).fetchPlans(),
);

final activeSubscriptionProvider = FutureProvider<UserSubscription?>(
  (ref) => _forUser(ref, null, ref.watch(subscriptionRepositoryProvider).fetchActive),
);

final subscriptionHistoryProvider = FutureProvider.autoDispose<List<UserSubscription>>(
  (ref) => _forUser(ref, const [], ref.watch(subscriptionRepositoryProvider).fetchHistory),
);

/// After a purchase: everything that shows the plan or the codes.
void refreshAfterCheckout(WidgetRef ref) {
  ref.invalidate(activeSubscriptionProvider);
  ref.invalidate(subscriptionHistoryProvider);
  ref.invalidate(promoCodesProvider);
}

// ── Rewards ────────────────────────────────────────────────────────

final promoCodesProvider = FutureProvider<List<PromoCode>>(
  (ref) => _forUser(ref, const [], ref.watch(subscriptionRepositoryProvider).fetchPromoCodes),
);

final spinStatusProvider = FutureProvider.autoDispose<SpinStatus>(
  (ref) => _forUser(ref, const SpinStatus(canSpin: false), ref.watch(subscriptionRepositoryProvider).fetchSpinStatus),
);

final spinHistoryProvider = FutureProvider.autoDispose<List<SpinAttempt>>(
  (ref) => _forUser(ref, const [], ref.watch(subscriptionRepositoryProvider).fetchSpinHistory),
);

// ── Referral & reward wallet ───────────────────────────────────────

final myReferralCodeProvider = FutureProvider<String>(
  (ref) => _forUser(ref, '', ref.watch(referralRepositoryProvider).fetchMyCode),
);

final referralsProvider = FutureProvider.autoDispose<List<Referral>>(
  (ref) => _forUser(ref, const [], ref.watch(referralRepositoryProvider).fetchReferrals),
);

final rewardWalletProvider = FutureProvider.autoDispose<RewardWallet>((ref) async {
  final session = await ref.watch(authControllerProvider.future);
  return ref.watch(referralRepositoryProvider).fetchWallet(session!.userId);
});

final rewardTransactionsProvider = FutureProvider.autoDispose<List<RewardTransaction>>(
  (ref) => _forUser(ref, const [], ref.watch(referralRepositoryProvider).fetchTransactions),
);

final topEarnersProvider = FutureProvider.autoDispose<List<RewardWallet>>(
  (ref) => ref.watch(referralRepositoryProvider).fetchTopEarners(),
);

/// Donations sent and received, newest first.
final donationsProvider = FutureProvider.autoDispose<({List<Donation> sent, List<Donation> received})>((ref) async {
  final session = await ref.watch(authControllerProvider.future);
  final repository = ref.watch(referralRepositoryProvider);
  final (sent, received) = await (
    repository.fetchDonationsSent(session!.userId),
    repository.fetchDonationsReceived(session.userId),
  ).wait;
  return (sent: sent, received: received);
});

// ── People ─────────────────────────────────────────────────────────

final rewardUserProvider = FutureProvider.family<AppUser, int>(
  (ref, id) => ref.watch(authRepositoryProvider).fetchUser(id),
);

/// People one can donate to: clients and freelancers except the user.
final donationRecipientsProvider = FutureProvider.autoDispose<List<AppUser>>((ref) async {
  final me = ref.watch(authControllerProvider).value?.userId;
  try {
    final res = await ref.watch(dioProvider).get<List<dynamic>>('/users/all');
    return res.data!
        .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
        .where((u) => u.id != me && (u.role == UserRole.client || u.role == UserRole.freelancer))
        .toList()
      ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
  } catch (e) {
    throw ApiException.from(e);
  }
});

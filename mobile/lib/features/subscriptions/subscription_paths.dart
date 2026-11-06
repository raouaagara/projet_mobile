import '../../core/router/app_paths.dart';

/// Pages of module 5 (freelancers only). Other modules may link here, e.g. module 1
/// sends freelancers without AI access to `SubscriptionPaths.plans`.
abstract final class SubscriptionPaths {
  static const plans = AppPaths.subscriptions;
  static const compare = '${AppPaths.subscriptions}/compare';
  static const mine = '${AppPaths.subscriptions}/mine';

  /// Checkout of [planId], with a promo code already filled in.
  static String checkout(int planId, {String? promoCode}) => Uri(
    path: '${AppPaths.subscriptions}/checkout/$planId',
    queryParameters: promoCode == null ? null : {'code': promoCode},
  ).toString();

  static const rewards = AppPaths.rewards;
  static const referral = AppPaths.referral;
  static const rewardWallet = '${AppPaths.referral}/wallet';
}

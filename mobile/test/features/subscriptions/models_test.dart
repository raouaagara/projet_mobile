import 'package:catchopp_mobile/features/subscriptions/data/models/referral_models.dart';
import 'package:catchopp_mobile/features/subscriptions/data/models/reward_models.dart';
import 'package:catchopp_mobile/features/subscriptions/data/models/subscription_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('subscription with plan and payments (backend JSON)', () {
    final sub = UserSubscription.fromJson({
      'id': 5,
      'userId': 1,
      'plan': {
        'id': 3,
        'name': 'Enterprise',
        'type': 'ENTERPRISE',
        'price': 49.99,
        'duration': 'monthly',
        'description': 'For teams with unlimited AI CV access.',
        'benefits': 'Everything in Premium,AI CV unlimited,Group subscription,Dedicated support',
        'hasAiCvAccess': true,
        'aiCvLimit': null,
      },
      'status': 'ACTIVE',
      'startDate': '2026-09-26',
      'endDate': '2026-11-26',
      'autoRenew': true,
      'payments': [
        {'id': 1, 'amount': 49.99, 'paymentMethod': 'flouci-test', 'status': 'PAID', 'paidAt': '2026-09-26T20:13:19', 'invoiceRef': 'INV-1'},
      ],
    });
    expect(sub.plan.type, PlanType.enterprise);
    expect(sub.plan.benefits, ['Everything in Premium', 'AI CV unlimited', 'Group subscription', 'Dedicated support']);
    expect(sub.plan.aiLabel, 'Unlimited AI tools');
    expect(sub.status, SubscriptionStatus.active);
    expect(sub.daysLeft(DateTime(2026, 11, 20, 18)), 6);
    expect(sub.payments.single.methodLabel, 'Flouci (test)');
    expect(const SubscriptionPlan(id: 1, name: 'Base', price: 9.99).aiLabel, 'No AI tools');
    expect(const SubscriptionPlan(id: 2, name: 'P', price: 1, hasAiCvAccess: true, aiCvLimit: 10).aiLabel, '10 AI uses / month');
  });

  test('checkout responses', () {
    final quote = CheckoutQuote.fromJson(const {
      'total': 37.49, 'price': 49.99, 'planName': 'Enterprise', 'discount': 12.5, 'planId': 3,
      'promoCode': 'SPIN5SHT9E', 'promoDescription': 'Spin the Wheel Winner - 25% off!',
    });
    expect(quote.total, 37.49);
    expect(quote.promoCode, 'SPIN5SHT9E');
    final start = CheckoutStart.fromJson(const {
      'total': 49.99, 'paymentId': 'TEST_f96d', 'testMode': true, 'link': 'https://catchopp.app/payment/success?payment_id=TEST_f96d',
    });
    expect(start.testMode, isTrue);
    expect(start.free, isFalse);
    expect(CheckoutStart.fromJson(const {'total': 0.0, 'free': true, 'testMode': true}).free, isTrue);
  });

  test('promo codes', () {
    final code = PromoCode.fromJson(const {
      'code': 'SPIN5SHT9E', 'description': 'Spin the Wheel Winner - 25% off!', 'discountType': 'PERCENTAGE',
      'discountValue': 25.0, 'earnedAt': '2026-09-26T20:13:31', 'expired': false, 'expiresAt': '2099-10-26T20:13:31',
      'id': 1, 'isActive': true, 'minSubscriptionCount': 1, 'type': 'SPIN_WHEEL', 'used': false, 'userId': 1,
    });
    expect(code.label, '25% off');
    expect(code.isUsable, isTrue);
    final used = PromoCode.fromJson(const {'id': 2, 'code': 'X', 'discountType': 'FIXED_AMOUNT', 'discountValue': 5, 'usedAt': '2026-09-26T20:13:32', 'isActive': false});
    expect(used.label, r'$5 off');
    expect(used.isUsable, isFalse);
    expect(PromoCode.fromJson(const {'id': 3, 'code': 'Y', 'discountType': 'FREE_MONTH', 'expiresAt': '2020-01-01T00:00:00'}).isUsable, isFalse);
  });

  test('reward wallet and donations', () {
    final wallet = RewardWallet.fromJson(const {
      'id': 1, 'userId': 1, 'balance': 3.0, 'totalEarned': 5.0, 'totalDonated': 2.0, 'totalReceived': 0.0,
      'certificationsCount': 12, 'currentTier': 'BRONZE',
    });
    expect(wallet.currentTier, RewardTier.bronze);
    expect(wallet.balance, 3);
    expect(const RewardTransaction(id: 1, amount: 5, type: 'REFERRAL_BONUS').typeLabel, 'Referral bonus');
    final donation = Donation.fromJson(const {
      'amount': 2.0, 'donorId': 1, 'id': 1, 'isAnonymous': false, 'message': 'Thanks', 'recipientId': 2, 'status': 'COMPLETED',
      'createdAt': '2026-09-26T20:13:43',
    });
    expect(donation.recipientId, 2);
    expect(Referral.fromJson(const {'id': 1, 'referredUserId': 2, 'referredAt': '2026-09-26T20:13:43'}).referredUserId, 2);
  });
}

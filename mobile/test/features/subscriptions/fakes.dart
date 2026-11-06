import 'package:catchopp_mobile/core/models/app_user.dart';
import 'package:catchopp_mobile/core/models/user_role.dart';
import 'package:catchopp_mobile/core/network/api_exception.dart';
import 'package:catchopp_mobile/features/auth/domain/auth_session.dart';
import 'package:catchopp_mobile/features/auth/presentation/auth_controller.dart';
import 'package:catchopp_mobile/features/contracts/data/models/contract.dart';
import 'package:catchopp_mobile/features/contracts/presentation/contract_providers.dart';
import 'package:catchopp_mobile/features/profile/data/competence_repository.dart';
import 'package:catchopp_mobile/features/profile/data/skill_test_repository.dart';
import 'package:catchopp_mobile/features/projects/presentation/project_providers.dart';
import 'package:catchopp_mobile/features/subscriptions/data/models/referral_models.dart';
import 'package:catchopp_mobile/features/subscriptions/data/models/reward_models.dart';
import 'package:catchopp_mobile/features/subscriptions/data/models/subscription_models.dart';
import 'package:catchopp_mobile/features/subscriptions/data/referral_repository.dart';
import 'package:catchopp_mobile/features/subscriptions/data/subscription_repository.dart';
import 'package:catchopp_mobile/features/subscriptions/presentation/subscription_providers.dart';
import 'package:catchopp_mobile/features/subscriptions/subscriptions_routes.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const me = 7;

const base = SubscriptionPlan(id: 1, name: 'Base', type: PlanType.base, price: 9.99, benefitsText: 'Up to 10 proposals,Basic profile');
const premium = SubscriptionPlan(
    id: 2, name: 'Premium', type: PlanType.premium, price: 24.99, benefitsText: 'Unlimited proposals,Featured visibility',
    hasAiCvAccess: true, aiCvLimit: 10);

PromoCode code(String value, {double percent = 20, DateTime? usedAt}) => PromoCode(
      id: value.hashCode,
      code: value,
      type: 'SPIN_WHEEL',
      discountType: DiscountType.percentage,
      discountValue: percent,
      description: 'Spin the Wheel Winner - ${percent.toInt()}% off!',
      expiresAt: DateTime.now().add(const Duration(days: 20)),
      usedAt: usedAt,
    );

class FakeSubscriptionRepository extends SubscriptionRepository {
  FakeSubscriptionRepository({this.active, List<PromoCode>? codes, this.canSpin = true})
      : codes = codes ?? [],
        super(Dio());

  UserSubscription? active;
  final List<PromoCode> codes;
  bool canSpin;
  final confirms = <({int planId, String? promoCode, String? paymentId})>[];
  int spinWins = 15;

  SubscriptionPlan _plan(int id) => [base, premium].firstWhere((p) => p.id == id);

  @override
  Future<List<SubscriptionPlan>> fetchPlans() async => [base, premium];

  PlanActivity? advisedWith;

  @override
  Future<PlanAdvice> advise(int userId, PlanActivity activity) async {
    advisedWith = activity;
    return const PlanAdvice(
      planId: 2,
      planName: 'Premium',
      headline: 'Premium pays for itself with your activity.',
      reasons: ['You sent 3 proposals', '2 contracts are in progress'],
      worthIt: r'$24.99 is less than 5% of what you earned this month.',
    );
  }

  @override
  Future<UserSubscription?> fetchActive(int userId) async => active;

  @override
  Future<List<UserSubscription>> fetchHistory(int userId) async => [?active];

  @override
  Future<CheckoutQuote> quote({required int userId, required int planId, String? promoCode}) async {
    final plan = _plan(planId);
    if (promoCode == null) return CheckoutQuote(planId: planId, planName: plan.name, price: plan.price, total: plan.price);
    final promo = codes.where((c) => c.code == promoCode && c.isUsable).firstOrNull;
    if (promo == null) throw const ApiException('This promo code was already used or has expired.', statusCode: 400);
    final discount = double.parse((plan.price * promo.discountValue / 100).toStringAsFixed(2));
    return CheckoutQuote(
      planId: planId,
      planName: plan.name,
      price: plan.price,
      discount: discount,
      total: double.parse((plan.price - discount).toStringAsFixed(2)),
      promoCode: promoCode,
      promoDescription: promo.description,
    );
  }

  @override
  Future<CheckoutStart> start({required int userId, required int planId, String? promoCode}) async {
    final total = (await quote(userId: userId, planId: planId, promoCode: promoCode)).total;
    return total <= 0
        ? CheckoutStart(total: 0, free: true, testMode: true)
        : CheckoutStart(total: total, testMode: true, paymentId: 'TEST_1', link: '${CheckoutUrls.success}?payment_id=TEST_1');
  }

  @override
  Future<CheckoutResult> confirm({required int userId, required int planId, String? promoCode, String? paymentId, String? email}) async {
    confirms.add((planId: planId, promoCode: promoCode, paymentId: paymentId));
    final total = (await quote(userId: userId, planId: planId, promoCode: promoCode)).total;
    active = UserSubscription(
      id: 10,
      plan: _plan(planId),
      status: SubscriptionStatus.active,
      startDate: DateTime(2026, 9, 26),
      endDate: DateTime(2026, 10, 26),
      payments: [SubscriptionPayment(id: 1, amount: total, paymentMethod: 'flouci-test', status: 'PAID', paidAt: DateTime(2026, 9, 26))],
    );
    return CheckoutResult(subscription: active!, total: total);
  }

  @override
  Future<List<PromoCode>> fetchPromoCodes(int userId) async => [...codes];

  @override
  Future<SpinStatus> fetchSpinStatus(int userId) async =>
      SpinStatus(canSpin: canSpin, daysUntilNextSpin: canSpin ? 0 : 12);

  @override
  Future<SpinAttempt> spin(int userId) async {
    canSpin = false;
    final won = code('SPINWIN1', percent: spinWins.toDouble());
    codes.add(won);
    return SpinAttempt(discountWon: spinWins, promoCode: won);
  }

  @override
  Future<List<SpinAttempt>> fetchSpinHistory(int userId) async => [];
}

class FakeReferralRepository extends ReferralRepository {
  FakeReferralRepository({this.extraReferrals = const []}) : super(Dio());

  final List<Referral> extraReferrals;
  String? inviteChannel;

  @override
  Future<String> writeInvite({
    required String code,
    String? firstName,
    String? role,
    String? skills,
    required String channel,
    String? language,
    String? note,
  }) async {
    inviteChannel = channel;
    return 'Hi! I use Workify for freelance work. Sign up and enter my code $code';
  }

  final donations = <Donation>[];
  final usedCodes = <String>[];

  @override
  Future<String> fetchMyCode(int userId) async => 'CATCH-7-A1B2C3';

  @override
  Future<List<Referral>> fetchReferrals(int userId) async =>
      [Referral(id: 1, referredUserId: 2, referralCode: 'CATCH-7-A1B2C3', status: 'COMPLETED', referredAt: DateTime(2026, 9, 25)), ...extraReferrals];

  @override
  Future<void> useCode(String code, {required int userId}) async {
    if (code == 'CATCH-7-A1B2C3') throw const ApiException("You can't use your own referral code.", statusCode: 400);
    usedCodes.add(code);
  }

  @override
  Future<RewardWallet> fetchWallet(int userId) async =>
      const RewardWallet(userId: me, balance: 5, totalEarned: 5, currentTier: RewardTier.none);

  @override
  Future<List<RewardTransaction>> fetchTransactions(int userId) async =>
      const [RewardTransaction(id: 1, amount: 5, type: 'REFERRAL_BONUS', description: 'Referral bonus: a friend joined with your code')];

  @override
  Future<List<RewardWallet>> fetchTopEarners() async => const [RewardWallet(userId: me, totalEarned: 5)];

  @override
  Future<Donation> donate({required int donorId, required int recipientId, required double amount, String? message, bool anonymous = false}) async {
    final donation = Donation(id: donations.length + 1, donorId: donorId, recipientId: recipientId, amount: amount, message: message);
    donations.add(donation);
    return donation;
  }

  @override
  Future<List<Donation>> fetchDonationsSent(int userId) async => [...donations];

  @override
  Future<List<Donation>> fetchDonationsReceived(int userId) async => [];
}

AppUser user(int id) => AppUser(
    id: id, firstName: id == me ? 'Sara' : 'Karim', lastName: 'B', email: 'u$id@mail.com',
    role: id == me ? UserRole.freelancer : UserRole.client);

class _NoContracts extends MyContractsController {
  @override
  Future<List<Contract>> build() async => [];
}

class _LoggedIn extends AuthController {
  @override
  Future<AuthSession?> build() async =>
      AuthSession(token: 't', userId: me, email: 'sara@mail.com', role: UserRole.freelancer, expiresAt: DateTime(2100));
}

Future<void> pumpSubscriptionsApp(
  WidgetTester tester, {
  required String location,
  FakeSubscriptionRepository? subscriptions,
  FakeReferralRepository? referral,
}) async {
  final router = GoRouter(initialLocation: location, routes: subscriptionsRoutes);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(_LoggedIn.new),
      subscriptionRepositoryProvider.overrideWithValue(subscriptions ?? FakeSubscriptionRepository()),
      referralRepositoryProvider.overrideWithValue(referral ?? FakeReferralRepository()),
      rewardUserProvider.overrideWith((ref, id) async => user(id)),
      donationRecipientsProvider.overrideWith((ref) async => [user(2)]),
      // What the plan advisor and the invite writer read from the other modules.
      currentUserProvider.overrideWith((ref) async => user(me)),
      myProposalsProvider.overrideWith((ref) async => []),
      myContractsProvider.overrideWith(_NoContracts.new),
      transactionsProvider.overrideWith((ref) async => []),
      certificationsProvider.overrideWith((ref, id) async => []),
      competenceCatalogProvider.overrideWith((ref) async => []),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

/// Scrolls until [finder] is on screen, then taps it.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import 'models/reward_models.dart';
import 'models/subscription_models.dart';

final subscriptionRepositoryProvider = Provider((ref) => SubscriptionRepository(ref.watch(dioProvider)));

/// Where Flouci sends the WebView back; the app intercepts these (they don't need to exist).
abstract final class CheckoutUrls {
  static const success = 'https://catchopp.app/payment/success';
  static const fail = 'https://catchopp.app/payment/fail';
}

/// What a freelancer did lately, gathered by the app from modules 1–3 for the plan advisor. Null: unknown.
class PlanActivity {
  const PlanActivity({
    this.proposalsSent,
    this.acceptedProposals,
    this.activeContracts,
    this.completedContracts,
    this.earnedLast30Days,
    this.skills,
    this.certificates,
  });

  final int? proposalsSent;
  final int? acceptedProposals;
  final int? activeContracts;
  final int? completedContracts;
  final double? earnedLast30Days;
  final int? skills;
  final int? certificates;

  Map<String, dynamic> toJson() => {
    'proposalsSent': ?proposalsSent,
    'acceptedProposals': ?acceptedProposals,
    'activeContracts': ?activeContracts,
    'completedContracts': ?completedContracts,
    'earnedLast30Days': ?earnedLast30Days,
    'skills': ?skills,
    'certificates': ?certificates,
  };
}

/// The AI's pick ([planId] null: stay free for now) and why.
class PlanAdvice {
  const PlanAdvice({this.planId, this.planName, required this.headline, this.reasons = const [], this.worthIt = ''});

  final int? planId;
  final String? planName;
  final String headline;
  final List<String> reasons;
  final String worthIt;

  factory PlanAdvice.fromJson(Map<String, dynamic> json) => PlanAdvice(
    planId: (json['planId'] as num?)?.toInt(),
    planName: json['planName'] as String?,
    headline: json['headline'] as String? ?? '',
    reasons: [for (final r in json['reasons'] as List<dynamic>? ?? []) r as String],
    worthIt: json['worthIt'] as String? ?? '',
  );
}

/// Plans, checkout, subscriptions, promo codes and the spin wheel (SubscriptionMicroService).
/// Every method throws [ApiException] on failure.
class SubscriptionRepository {
  SubscriptionRepository(this._dio);

  final Dio _dio;

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      // Reward endpoints answer {"success": false, "message": "..."}.
      final data = e.response?.data;
      if (data is Map && data['message'] is String && data['error'] is! String) {
        throw ApiException(data['message'] as String, statusCode: e.response?.statusCode);
      }
      throw ApiException.from(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  List<T> _list<T>(Object? data, T Function(Map<String, dynamic>) fromJson) =>
      (data as List<dynamic>).map((e) => fromJson(e as Map<String, dynamic>)).toList();

  // ── Plans & subscriptions ────────────────────────────────────────

  /// Which plan fits [userId], by the AI, from their [activity].
  Future<PlanAdvice> advise(int userId, PlanActivity activity) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/Subscription/ai/advise',
      data: {'userId': userId, 'activity': activity.toJson()},
    );
    return PlanAdvice.fromJson(res.data!);
  });

  /// Cheapest first.
  Future<List<SubscriptionPlan>> fetchPlans() => _call(() async {
    final res = await _dio.get<List<dynamic>>('/Subscription/plans');
    return _list(res.data, SubscriptionPlan.fromJson)..sort((a, b) => a.price.compareTo(b.price));
  });

  /// The current plan, or null.
  Future<UserSubscription?> fetchActive(int userId) => _call(() async {
    final res = await _dio.get<Object?>('/Subscription/user/$userId/active');
    final data = res.data;
    return res.statusCode == 204 || data is! Map<String, dynamic> ? null : UserSubscription.fromJson(data);
  });

  /// Newest first, with their payments.
  Future<List<UserSubscription>> fetchHistory(int userId) => _call(() async {
    final res = await _dio.get<List<dynamic>>('/Subscription/user/$userId/subscriptions');
    return _list(res.data, UserSubscription.fromJson)..sort((a, b) => b.id.compareTo(a.id));
  });

  // ── Checkout (server computes the price and verifies the payment) ─

  Map<String, Object> _body(int userId, int planId, String? promoCode) => {
    'userId': userId,
    'planId': planId,
    'promoCode': ?promoCode,
  };

  Future<CheckoutQuote> quote({required int userId, required int planId, String? promoCode}) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/Subscription/checkout/quote',
      data: _body(userId, planId, promoCode),
    );
    return CheckoutQuote.fromJson(res.data!);
  });

  Future<CheckoutStart> start({required int userId, required int planId, String? promoCode}) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/Subscription/checkout/start',
      data: {..._body(userId, planId, promoCode), 'successUrl': CheckoutUrls.success, 'failUrl': CheckoutUrls.fail},
    );
    return CheckoutStart.fromJson(res.data!);
  });

  Future<CheckoutResult> confirm({
    required int userId,
    required int planId,
    String? promoCode,
    String? paymentId,
    String? email,
  }) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/Subscription/checkout/confirm',
      data: {..._body(userId, planId, promoCode), 'paymentId': ?paymentId, 'email': ?email},
      options: Options(receiveTimeout: const Duration(seconds: 45)),
    );
    return CheckoutResult.fromJson(res.data!);
  });

  // ── Promo codes & spin wheel ─────────────────────────────────────

  /// All the user's codes, newest first.
  Future<List<PromoCode>> fetchPromoCodes(int userId) => _call(() async {
    final res = await _dio.get<List<dynamic>>('/api/promo-codes/user/$userId');
    return _list(res.data, PromoCode.fromJson)..sort((a, b) => b.id.compareTo(a.id));
  });

  Future<SpinStatus> fetchSpinStatus(int userId) => _call(() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/rewards/spin-wheel/can-spin/$userId');
    return SpinStatus.fromJson(res.data!);
  });

  Future<SpinAttempt> spin(int userId) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>('/api/rewards/spin-wheel/$userId');
    return SpinAttempt.fromJson(res.data!);
  });

  Future<List<SpinAttempt>> fetchSpinHistory(int userId) => _call(() async {
    final res = await _dio.get<List<dynamic>>('/api/rewards/spin-wheel/history/$userId');
    return _list(res.data, SpinAttempt.fromJson);
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import 'models/referral_models.dart';

final referralRepositoryProvider = Provider((ref) => ReferralRepository(ref.watch(dioProvider)));

/// Referral codes, reward wallet and donations (ReferralMicroService).
/// Every method throws [ApiException] on failure.
class ReferralRepository {
  ReferralRepository(this._dio);

  final Dio _dio;

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  List<T> _list<T>(Object? data, T Function(Map<String, dynamic>) fromJson) =>
      (data as List<dynamic>).map((e) => fromJson(e as Map<String, dynamic>)).toList();

  /// The user's code, created the first time (e.g. "CATCH-1-141FA1").
  Future<String> fetchMyCode(int userId) => _call(() async {
    final res = await _dio.get<String>('/Referral/code/$userId', options: Options(responseType: ResponseType.plain));
    return res.data!.trim();
  });

  /// A personal invite with [code], written by the AI for [channel] (WHATSAPP, LINKEDIN or EMAIL).
  Future<String> writeInvite({
    required String code,
    String? firstName,
    String? role,
    String? skills,
    required String channel,
    String? language,
    String? note,
  }) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/Referral/ai/invite',
      data: {
        'code': code,
        'firstName': ?firstName,
        'role': ?role,
        'skills': ?skills,
        'channel': channel,
        'language': ?language,
        'note': ?note,
      },
    );
    return res.data!['message'] as String? ?? '';
  });

  /// People who joined with the user's code, newest first.
  Future<List<Referral>> fetchReferrals(int userId) => _call(() async {
    final res = await _dio.get<List<dynamic>>('/Referral/referrals/$userId');
    return _list(res.data, Referral.fromJson)..sort((a, b) => b.id.compareTo(a.id));
  });

  /// The user joined with a friend's code (the friend gets a bonus).
  Future<void> useCode(String code, {required int userId}) => _call(
    () => _dio.post<void>(
      '/Referral/use/${Uri.encodeComponent(code.trim())}',
      queryParameters: {'referredUserId': userId},
    ),
  );

  Future<RewardWallet> fetchWallet(int userId) => _call(() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/wallet/$userId');
    return RewardWallet.fromJson(res.data!);
  });

  Future<List<RewardTransaction>> fetchTransactions(int userId) => _call(() async {
    final res = await _dio.get<List<dynamic>>('/api/wallet/$userId/transactions');
    return _list(res.data, RewardTransaction.fromJson)..sort((a, b) => b.id.compareTo(a.id));
  });

  Future<List<RewardWallet>> fetchTopEarners() => _call(() async {
    final res = await _dio.get<List<dynamic>>('/api/wallet/leaderboards/earners');
    return _list(res.data, RewardWallet.fromJson);
  });

  Future<Donation> donate({
    required int donorId,
    required int recipientId,
    required double amount,
    String? message,
    bool anonymous = false,
  }) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/donations/send',
      queryParameters: {
        'donorId': donorId,
        'recipientId': recipientId,
        'amount': amount,
        if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
        'isAnonymous': anonymous,
      },
    );
    return Donation.fromJson(res.data!['donation'] as Map<String, dynamic>);
  });

  Future<List<Donation>> fetchDonationsSent(int userId) => _call(() async {
    final res = await _dio.get<List<dynamic>>('/api/donations/sent/$userId');
    return _list(res.data, Donation.fromJson)..sort((a, b) => b.id.compareTo(a.id));
  });

  Future<List<Donation>> fetchDonationsReceived(int userId) => _call(() async {
    final res = await _dio.get<List<dynamic>>('/api/donations/received/$userId');
    return _list(res.data, Donation.fromJson)..sort((a, b) => b.id.compareTo(a.id));
  });
}

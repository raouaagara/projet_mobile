import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import 'models/payment_models.dart';

final paymentRepositoryProvider = Provider((ref) => PaymentRepository(ref.watch(dioProvider)));

/// Wallet, escrow and dispute endpoints (paiementMS). Every method throws [ApiException] on failure.
class PaymentRepository {
  PaymentRepository(this._dio);

  final Dio _dio;

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Like [_call], but a 404 ("no wallet yet", "nothing in escrow") gives [notFound].
  Future<T> _orIfMissing<T>(T notFound, Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return notFound;
      throw ApiException.from(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  List<T> _list<T>(Object? data, T Function(Map<String, dynamic>) fromJson) =>
      (data as List<dynamic>).map((e) => fromJson(e as Map<String, dynamic>)).toList();

  // ── Wallet ───────────────────────────────────────────────────────

  Future<Wallet?> fetchWallet(int userId) => _orIfMissing(null, () async {
        final res = await _dio.get<Map<String, dynamic>>('/api/payments/wallet/$userId');
        return Wallet.fromJson(res.data!);
      });

  Future<Wallet> createWallet(int userId, {required bool freelancer}) => _call(() async {
        final res = await _dio.post<Map<String, dynamic>>(
            freelancer ? '/api/payments/wallet/create/freelancer/$userId' : '/api/payments/wallet/create/$userId');
        return Wallet.fromJson(res.data!);
      });

  /// Adds (test) money to a wallet. There is no real card payment behind it yet, like on the web app.
  Future<Wallet> topUp(int userId, double amount) => _call(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/api/payments/topup',
          data: {'userId': userId, 'amount': amount},
        );
        return Wallet.fromJson(res.data!);
      });

  /// Newest first; empty when the user has no wallet yet.
  Future<List<WalletTransaction>> fetchTransactions(int userId) => _orIfMissing(const [], () async {
        final res = await _dio.get<List<dynamic>>('/api/payments/transactions/$userId');
        return _list(res.data, WalletTransaction.fromJson)..sort((a, b) => b.id.compareTo(a.id));
      });

  // ── Escrow ───────────────────────────────────────────────────────

  /// Null until the freelancer signs.
  Future<Escrow?> fetchEscrow(int contractId) => _orIfMissing(null, () async {
        final res = await _dio.get<Map<String, dynamic>>('/api/payments/escrow/contract/$contractId');
        return Escrow.fromJson(res.data!);
      });

  Future<List<Escrow>> fetchEscrows(int userId, {required bool freelancer}) => _call(() async {
        final res = await _dio.get<List<dynamic>>(
            freelancer ? '/api/payments/escrow/freelancer/$userId' : '/api/payments/escrow/client/$userId');
        return _list(res.data, Escrow.fromJson)..sort((a, b) => b.id.compareTo(a.id));
      });

  /// Client approves the work: the escrow goes to the freelancer, the contract is completed.
  Future<Escrow> release(int contractId, {required int clientId}) => _call(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/api/payments/escrow/contract/$contractId/release',
          data: {'clientId': clientId},
        );
        return Escrow.fromJson(res.data!);
      });

  // ── Disputes ─────────────────────────────────────────────────────

  Future<Dispute> raiseDispute({required int contractId, required int userId, required String reason}) =>
      _call(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/api/disputes/raise',
          data: {'contractId': contractId, 'raisedByUserId': userId, 'reason': reason},
        );
        return Dispute.fromJson(res.data!);
      });

  /// Disputes opened by or against [userId], newest first.
  Future<List<Dispute>> fetchDisputes(int userId) => _call(() async {
        final res = await _dio.get<List<dynamic>>('/api/disputes/user/$userId');
        return _list(res.data, Dispute.fromJson);
      });
}

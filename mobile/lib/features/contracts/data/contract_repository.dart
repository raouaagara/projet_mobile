import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/utils/json_utils.dart';
import 'models/contract.dart';

final contractRepositoryProvider = Provider((ref) => ContractRepository(ref.watch(dioProvider)));

/// What the contract form needs from an accepted proposal (`GET /Project/proposals/{id}`).
class ProposalSummary {
  const ProposalSummary({
    required this.id,
    required this.bidAmount,
    this.status,
    this.freelancerId,
    this.projectId,
    this.projectTitle,
    this.estimationEndDate,
    this.jobType,
  });

  final int id;
  final double bidAmount;
  final String? status;
  final int? freelancerId;
  final int? projectId;
  final String? projectTitle;
  final DateTime? estimationEndDate;
  final String? jobType;

  bool get isAccepted => status == 'ACCEPTED';

  factory ProposalSummary.fromJson(Map<String, dynamic> json) {
    final project = json['project'] as Map<String, dynamic>?;
    return ProposalSummary(
      id: (json['id'] as num).toInt(),
      bidAmount: (json['bidAmount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String?,
      freelancerId: (json['freelancerId'] as num?)?.toInt(),
      projectId: (project?['id'] as num?)?.toInt(),
      projectTitle: project?['title'] as String?,
      estimationEndDate: parseApiDate(json['estimationEndDate']),
      jobType: project?['jobType'] as String?,
    );
  }
}

/// A contract in plain words (AI), for the person about to sign it.
class ContractExplanation {
  const ContractExplanation({required this.summary, required this.check});

  final List<String> summary;

  /// Gaps worth agreeing on in the chat before signing.
  final List<String> check;

  factory ContractExplanation.fromJson(Map<String, dynamic> json) => ContractExplanation(
        summary: [for (final s in json['summary'] as List<dynamic>? ?? []) s as String],
        check: [for (final s in json['check'] as List<dynamic>? ?? []) s as String],
      );
}

/// Contract endpoints (`/Contract/**`). Every method throws [ApiException] on failure.
class ContractRepository {
  ContractRepository(this._dio);

  final Dio _dio;

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  List<Contract> _contracts(List<dynamic>? data) =>
      data!.map((e) => Contract.fromJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.id.compareTo(a.id));

  Future<List<Contract>> fetchForClient(int clientId) => _call(() async {
        final res = await _dio.get<List<dynamic>>('/Contract/client/$clientId');
        return _contracts(res.data);
      });

  Future<List<Contract>> fetchForFreelancer(int freelancerId) => _call(() async {
        final res = await _dio.get<List<dynamic>>('/Contract/freelancer/$freelancerId');
        return _contracts(res.data);
      });

  Future<Contract> fetch(int id) => _call(() async {
        final res = await _dio.get<Map<String, dynamic>>('/Contract/$id');
        return Contract.fromJson(res.data!);
      });

  /// The contract already made from [proposalId], or null.
  Future<Contract?> fetchByProposal(int proposalId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/Contract/proposal/$proposalId');
      return Contract.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.from(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ProposalSummary> fetchProposal(int proposalId) => _call(() async {
        final res = await _dio.get<Map<String, dynamic>>('/Project/proposals/$proposalId');
        return ProposalSummary.fromJson(res.data!);
      });

  /// Client: sends the contract (already signed by the client) to the freelancer.
  Future<Contract> createFromProposal({
    required int proposalId,
    required int clientId,
    required String clientName,
    required String clientSignature,
    required DateTime startDate,
    required String terms,
  }) =>
      _call(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/Contract/generate-from-proposal/$proposalId',
          data: {
            'clientId': clientId,
            'clientName': clientName,
            'clientSignature': clientSignature,
            'startDate': formatApiDate(startDate),
            'terms': terms,
          },
        );
        return Contract.fromJson(res.data!);
      });

  /// Freelancer: signs; the backend locks the client's payment in escrow.
  Future<Contract> sign(int id, {required String signature, required String freelancerName}) => _call(() async {
        final res = await _dio.put<Map<String, dynamic>>(
          '/Contract/$id/sign',
          data: {'signature': signature, 'freelancerName': freelancerName},
          options: Options(receiveTimeout: const Duration(seconds: 45)),
        );
        return Contract.fromJson(res.data!);
      });

  Future<Contract> reject(int id) => _call(() async {
        final res = await _dio.put<Map<String, dynamic>>('/Contract/$id/reject');
        return Contract.fromJson(res.data!);
      });

  // ── AI ──

  /// Terms written by the AI from the accepted proposal; [notes] are the client's own points to include.
  Future<String> draftTerms({required int proposalId, required DateTime startDate, String? notes}) => _call(() async {
        final res = await _dio.post<Map<String, dynamic>>('/Contract/ai/terms', data: {
          'proposalId': proposalId,
          'startDate': formatApiDate(startDate),
          'notes': ?notes,
        });
        return res.data!['terms'] as String? ?? '';
      });

  /// The contract explained by the AI to the one about to sign it ([role]: CLIENT or FREELANCER).
  Future<ContractExplanation> explain(int contractId, {required String role}) => _call(() async {
        final res = await _dio.post<Map<String, dynamic>>('/Contract/ai/$contractId/explain', data: {'role': role});
        return ContractExplanation.fromJson(res.data!);
      });

  /// A dispute message rewritten by the AI, clear and factual.
  Future<String> draftDispute({required int contractId, required String role, required String text}) =>
      _call(() async {
        final res = await _dio.post<Map<String, dynamic>>('/Contract/ai/dispute-draft', data: {
          'contractId': contractId,
          'role': role,
          'text': text,
        });
        return res.data!['text'] as String? ?? '';
      });
}

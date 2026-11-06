import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/utils/json_utils.dart';
import 'models/job_match.dart';
import 'models/project.dart';
import 'models/project_enums.dart';
import 'models/project_notification.dart';
import 'models/proposal.dart';

final projectRepositoryProvider = Provider((ref) => ProjectRepository(ref.watch(dioProvider)));

/// Project, proposal and notification endpoints (`/Project/**`).
/// Every method throws [ApiException] on failure.
class ProjectRepository {
  ProjectRepository(this._dio);

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

  // ── Projects ─────────────────────────────────────────────────────

  /// Every project, newest first. The backend has no pagination or filters.
  Future<List<Project>> fetchAll() => _call(() async {
    final res = await _dio.get<List<dynamic>>('/Project/allprojects');
    return _list(res.data, Project.fromJson)..sort(_newestFirst);
  });

  Future<Project> fetch(int id) => _call(() async {
    final res = await _dio.get<Map<String, dynamic>>('/Project/$id');
    return Project.fromJson(res.data!);
  });

  Future<Project> create(Project project) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>('/Project/newproject', data: project.toJson());
    return Project.fromJson(res.data!);
  });

  Future<Project> update(Project project) => _call(() async {
    final res = await _dio.put<Map<String, dynamic>>('/Project/update/${project.id}', data: project.toJson());
    return Project.fromJson(res.data!);
  });

  Future<void> delete(int id) => _call(() => _dio.delete<void>('/Project/delete/$id'));

  Future<Project> updateStatus(int id, ProjectStatus status) => _call(() async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/Project/$id/status',
      queryParameters: {'status': _enumName(status)},
    );
    return Project.fromJson(res.data!);
  });

  /// [previous] is the user's earlier reaction, removed by the backend when switching.
  Future<Project> react(int id, ProjectReaction reaction, {ProjectReaction? previous}) => _call(() async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/Project/$id/react',
      queryParameters: {'type': reaction.apiName, 'previous': ?previous?.apiName},
    );
    return Project.fromJson(res.data!);
  });

  // ── Proposals ────────────────────────────────────────────────────

  Future<List<Proposal>> fetchProposals(int projectId) => _call(() async {
    final res = await _dio.get<List<dynamic>>('/Project/$projectId/proposals');
    return _list(res.data, Proposal.fromJson);
  });

  /// Proposals sent by a freelancer, newest first.
  Future<List<Proposal>> fetchFreelancerProposals(int freelancerId) => _call(() async {
    final res = await _dio.get<List<dynamic>>('/Project/proposals/freelancer/$freelancerId');
    return _list(res.data, Proposal.fromJson)..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
  });

  Future<Proposal> submitProposal(int projectId, Proposal proposal) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>('/Project/$projectId/proposals', data: proposal.toJson());
    return Proposal.fromJson(res.data!);
  });

  Future<Proposal> updateProposalStatus(int proposalId, ProposalStatus status) => _call(() async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/Project/proposals/$proposalId/status',
      queryParameters: {'status': _enumName(status)},
    );
    return Proposal.fromJson(res.data!);
  });

  // ── AI ───────────────────────────────────────────────────────────

  /// A freelancer's match score on every open project, by project id (empty without skills).
  Future<Map<int, JobMatch>> matchJobs(List<int> skillIds) => _call(() async {
    final res = await _dio.post<List<dynamic>>('/Project/ai/match', data: {'skillIds': skillIds});
    return {
      for (final m in res.data!.cast<Map<String, dynamic>>()) (m['projectId'] as num).toInt(): JobMatch.fromJson(m),
    };
  });

  /// How each applicant fits [projectId], by freelancer id. [skills]: freelancer id → their skill ids.
  Future<Map<int, JobMatch>> matchCandidates(int projectId, Map<int, List<int>> skills) => _call(() async {
    final res = await _dio.post<List<dynamic>>(
      '/Project/ai/$projectId/candidates',
      data: {
        'candidates': [
          for (final entry in skills.entries) {'freelancerId': entry.key, 'skillIds': entry.value},
        ],
      },
    );
    return {
      for (final m in res.data!.cast<Map<String, dynamic>>()) (m['freelancerId'] as num).toInt(): JobMatch.fromJson(m),
    };
  });

  /// A cover letter for a proposal on [projectId], written by the AI from what the freelancer gives.
  Future<String> draftCoverLetter({
    required int projectId,
    String? freelancerName,
    String? bio,
    List<int> skillIds = const [],
    double? bidAmount,
    DateTime? deliveryDate,
    String? notes,
  }) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/Project/ai/proposal-draft',
      data: {
        'projectId': projectId,
        'freelancerName': ?freelancerName,
        'bio': ?bio,
        'skillIds': skillIds,
        'bidAmount': ?bidAmount,
        'estimationEndDate': ?formatApiDate(deliveryDate),
        'notes': ?notes,
      },
    );
    return res.data!['coverLetter'] as String? ?? '';
  });

  /// A job post (title, description, level, skills) written by the AI from the client's idea.
  Future<ProjectDraft> draftProject({
    required String idea,
    String? title,
    ProjectCategory? category,
    JobType? jobType,
  }) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/Project/ai/describe',
      data: {
        'idea': idea,
        'title': ?title,
        if (category != null) 'category': _enumName(category),
        if (jobType != null) 'jobType': _enumName(jobType),
      },
    );
    return ProjectDraft.fromJson(res.data!);
  });

  // ── Notifications ────────────────────────────────────────────────

  Future<List<ProjectNotification>> fetchNotifications(int userId) => _call(() async {
    final res = await _dio.get<List<dynamic>>('/Project/notifications/$userId');
    return _list(res.data, ProjectNotification.fromJson);
  });

  Future<void> markNotificationRead(int id) => _call(() => _dio.put<void>('/Project/notifications/$id/read'));
}

int _newestFirst(Project a, Project b) => (b.id ?? 0).compareTo(a.id ?? 0);

/// `ProjectStatus.open` → `OPEN`, `JobType.fixedPrice` → `FIXED_PRICE`, like the JSON.
String _enumName(Enum value) => value.name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}').toUpperCase();

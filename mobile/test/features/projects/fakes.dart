import 'package:catchopp_mobile/core/models/app_user.dart';
import 'package:catchopp_mobile/core/models/user_role.dart';
import 'package:catchopp_mobile/features/auth/domain/auth_session.dart';
import 'package:catchopp_mobile/features/auth/presentation/auth_controller.dart';
import 'package:catchopp_mobile/core/network/api_exception.dart';
import 'package:catchopp_mobile/features/projects/data/models/job_match.dart';
import 'package:catchopp_mobile/features/projects/data/models/project.dart';
import 'package:catchopp_mobile/features/projects/data/models/project_enums.dart';
import 'package:catchopp_mobile/features/projects/data/models/project_notification.dart';
import 'package:catchopp_mobile/features/projects/data/models/proposal.dart';
import 'package:catchopp_mobile/features/projects/data/project_prefs.dart';
import 'package:catchopp_mobile/features/projects/data/project_repository.dart';
import 'package:catchopp_mobile/features/projects/data/skill_catalog.dart';
import 'package:catchopp_mobile/features/projects/presentation/project_providers.dart';
import 'package:catchopp_mobile/features/projects/projects_routes.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const clientId = 2;
const freelancerId = 7;

Project project(int id,
        {String title = 'Project',
        ProjectStatus status = ProjectStatus.open,
        int client = clientId,
        double budget = 1000,
        ProjectCategory category = ProjectCategory.webDevelopment,
        JobType jobType = JobType.fixedPrice,
        String experience = ExperienceLevel.intermediate}) =>
    Project(
      id: id,
      title: title,
      description: 'Description of $title, long enough.',
      budget: budget,
      status: status,
      clientId: client,
      category: category,
      jobType: jobType,
      experienceLevel: experience,
      postedAt: DateTime(2026, 9, 20),
    );

/// In-memory backend for module 2.
class FakeProjectRepository extends ProjectRepository {
  FakeProjectRepository({
    List<Project>? projects,
    List<Proposal>? proposals,
    this.matches = const {},
    this.candidateMatches = const {},
    this.aiDown = false,
  })  : projects = projects ?? [],
        proposals = proposals ?? [],
        super(Dio());

  final List<Project> projects;
  final List<Proposal> proposals;

  /// AI scores: the freelancer's on each project, and each applicant's (by freelancer id).
  final Map<int, JobMatch> matches;
  final Map<int, JobMatch> candidateMatches;

  /// Every AI call fails, like when the AI service is offline.
  final bool aiDown;

  List<int>? matchedSkills;
  String? letterNotes;
  String? idea;

  /// Like a real network: every call answers a bit later, so screens rebuild in between.
  Future<void> _latency() => Future<void>.delayed(const Duration(milliseconds: 50));

  final projectStatuses = <int, ProjectStatus>{};
  final proposalStatuses = <int, ProposalStatus>{};

  @override
  Future<List<Project>> fetchAll() async => [...projects];

  @override
  Future<Project> fetch(int id) async => projects.firstWhere((p) => p.id == id);

  @override
  Future<Project> create(Project project) async {
    final created = Project.fromJson({...project.toJson(), 'id': 100 + projects.length});
    projects.add(created);
    return created;
  }

  @override
  Future<Project> updateStatus(int id, ProjectStatus status) async {
    await _latency();
    projectStatuses[id] = status;
    final i = projects.indexWhere((p) => p.id == id);
    return projects[i] = projects[i].copyWith(status: status);
  }

  @override
  Future<List<Proposal>> fetchProposals(int projectId) async {
    await _latency();
    return proposals.where((p) => p.project?.id == projectId).toList();
  }

  @override
  Future<List<Proposal>> fetchFreelancerProposals(int freelancerId) async =>
      proposals.where((p) => p.freelancerId == freelancerId).toList();

  @override
  Future<Proposal> submitProposal(int projectId, Proposal proposal) async {
    final saved = Proposal(
      id: 500 + proposals.length,
      bidAmount: proposal.bidAmount,
      estimationEndDate: proposal.estimationEndDate,
      freelancerId: proposal.freelancerId,
      coverLetter: proposal.coverLetter,
      project: projects.firstWhere((p) => p.id == projectId),
    );
    proposals.add(saved);
    return saved;
  }

  @override
  Future<Proposal> updateProposalStatus(int proposalId, ProposalStatus status) async {
    await _latency();
    proposalStatuses[proposalId] = status;
    final i = proposals.indexWhere((p) => p.id == proposalId);
    return proposals[i] = proposals[i].copyWith(status: status);
  }

  @override
  Future<List<ProjectNotification>> fetchNotifications(int userId) async => [];

  Future<void> _ai() async {
    await _latency();
    if (aiDown) throw const ApiException('The matching AI is offline right now. Try again in a moment.');
  }

  @override
  Future<Map<int, JobMatch>> matchJobs(List<int> skillIds) async {
    await _ai();
    matchedSkills = skillIds;
    return matches;
  }

  @override
  Future<Map<int, JobMatch>> matchCandidates(int projectId, Map<int, List<int>> skills) async {
    await _ai();
    return {for (final id in skills.keys) id: ?candidateMatches[id]};
  }

  @override
  Future<String> draftCoverLetter({
    required int projectId,
    String? freelancerName,
    String? bio,
    List<int> skillIds = const [],
    double? bidAmount,
    DateTime? deliveryDate,
    String? notes,
  }) async {
    await _ai();
    letterNotes = notes;
    return 'Hello, I am $freelancerName and I can build this for \$${bidAmount?.toStringAsFixed(0)}.';
  }

  @override
  Future<ProjectDraft> draftProject({
    required String idea,
    String? title,
    ProjectCategory? category,
    JobType? jobType,
  }) async {
    await _ai();
    this.idea = idea;
    return const ProjectDraft(
      title: 'Restaurant ordering app',
      description: 'Customers order and pay online.\n\n• Menu\n• Online payment',
      experienceLevel: ExperienceLevel.expert,
      skillIds: [1],
    );
  }
}

class MemoryPrefs extends ProjectPrefs {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _LoggedIn extends AuthController {
  _LoggedIn(this.role);

  final UserRole role;

  @override
  Future<AuthSession?> build() async => AuthSession(
        token: 't',
        userId: role == UserRole.client ? clientId : freelancerId,
        email: 'me@mail.com',
        role: role,
        expiresAt: DateTime(2100),
      );
}

/// Module 2's pages with a fake backend, logged in as [role].
Future<void> pumpProjectsApp(
  WidgetTester tester, {
  required UserRole role,
  required FakeProjectRepository repository,
  String location = '/projects',
  List<int> mySkills = const [1],
}) async {
  final router = GoRouter(initialLocation: location, routes: [projectsTab, ...projectsRoutes]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => _LoggedIn(role)),
      projectRepositoryProvider.overrideWithValue(repository),
      projectPrefsProvider.overrideWithValue(MemoryPrefs()),
      skillCatalogProvider.overrideWith((ref) async => {1: const CatalogSkill(id: 1, name: 'Flutter')}),
      currentUserProvider.overrideWith((ref) async => AppUser(
          id: role == UserRole.client ? clientId : freelancerId,
          firstName: role == UserRole.client ? 'Karim' : 'Sara',
          lastName: 'B',
          email: 'me@mail.com',
          role: role,
          competenceIds: mySkills)),
      projectUserProvider.overrideWith((ref, id) async => AppUser(
          id: id,
          firstName: switch (id) { freelancerId => 'Sara', clientId => 'Karim', _ => 'Amine' },
          lastName: 'B',
          email: 'u$id@mail.com',
          role: id == clientId ? UserRole.client : UserRole.freelancer)),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

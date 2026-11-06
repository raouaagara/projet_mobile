import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/models/job_match.dart';
import '../data/models/project.dart';
import '../data/models/project_enums.dart';
import '../data/models/project_notification.dart';
import '../data/models/proposal.dart';
import '../data/project_prefs.dart';
import '../data/project_repository.dart';

// Derived lists are plain `Provider<AsyncValue>`s (not FutureProviders) so they
// update in place when the project list changes, without a loading flash.

// ── Projects ───────────────────────────────────────────────────────

/// Every project, loaded once and patched after each change.
/// Pull-to-refresh: `ref.refresh(projectsControllerProvider.future)`.
final projectsControllerProvider = AsyncNotifierProvider<ProjectsController, List<Project>>(ProjectsController.new);

class ProjectsController extends AsyncNotifier<List<Project>> {
  ProjectRepository get _repository => ref.read(projectRepositoryProvider);

  @override
  Future<List<Project>> build() => ref.watch(projectRepositoryProvider).fetchAll();

  /// Inserts or replaces [project] in the loaded list.
  void put(Project project) {
    final projects = state.value;
    if (projects == null) return;
    final index = projects.indexWhere((p) => p.id == project.id);
    state = AsyncData(index == -1 ? [project, ...projects] : ([...projects]..[index] = project));
  }

  Future<Project> create(Project project) async {
    final created = await _repository.create(project);
    put(created);
    return created;
  }

  Future<Project> save(Project project) async {
    final updated = await _repository.update(project);
    put(updated);
    return updated;
  }

  Future<Project> setStatus(int id, ProjectStatus status) async {
    final updated = await _repository.updateStatus(id, status);
    put(updated);
    return updated;
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);
    state = AsyncData([...?state.value?.where((p) => p.id != id)]);
  }
}

/// One project: from the loaded list, or from the server if it isn't there
/// (e.g. opened from a notification about a project posted since).
final projectProvider = Provider.autoDispose.family<AsyncValue<Project>, int>((ref, id) {
  final all = ref.watch(projectsControllerProvider);
  final cached = all.value?.where((p) => p.id == id).firstOrNull;
  if (cached != null) return AsyncData(cached);
  if (all.isLoading) return const AsyncLoading();
  return ref.watch(_remoteProjectProvider(id));
});

final _remoteProjectProvider = FutureProvider.autoDispose.family<Project, int>(
  (ref, id) => ref.watch(projectRepositoryProvider).fetch(id),
);

/// The logged-in client's projects, newest first.
final myProjectsProvider = Provider.autoDispose<AsyncValue<List<Project>>>((ref) {
  final userId = ref.watch(authControllerProvider).value?.userId;
  return ref.watch(projectsControllerProvider).whenData((all) => all.where((p) => p.clientId == userId).toList());
});

// ── Freelancer feed ────────────────────────────────────────────────

enum FeedSort {
  bestMatch('Best match'),
  newest('Newest'),
  oldest('Oldest'),
  highestBudget('Highest budget'),
  lowestBudget('Lowest budget');

  const FeedSort(this.label);

  final String label;
}

enum BudgetRange {
  any('Any budget', 0, double.infinity),
  under500(r'Under $500', 0, 500),
  from500To1000(r'$500 – $1,000', 500, 1000),
  over1000(r'$1,000+', 1000, double.infinity);

  const BudgetRange(this.label, this.min, this.max);

  final String label;
  final double min;
  final double max;

  bool contains(double amount) => amount >= min && (max == double.infinity || amount < max);
}

class FeedFilter {
  const FeedFilter({
    this.query = '',
    this.category,
    this.jobType,
    this.experience,
    this.budget = BudgetRange.any,
    this.sort = FeedSort.newest,
  });

  final String query;
  final ProjectCategory? category;
  final JobType? jobType;
  final String? experience;
  final BudgetRange budget;
  final FeedSort sort;

  /// Filters picked in the filter sheet (the search box is not counted).
  int get activeCount =>
      [category, jobType, experience].where((f) => f != null).length + (budget == BudgetRange.any ? 0 : 1);

  FeedFilter copyWith({String? query, FeedSort? sort}) => FeedFilter(
    query: query ?? this.query,
    category: category,
    jobType: jobType,
    experience: experience,
    budget: budget,
    sort: sort ?? this.sort,
  );

  /// The same filter for one category (null: all categories).
  FeedFilter withCategory(ProjectCategory? category) => FeedFilter(
    query: query,
    category: category,
    jobType: jobType,
    experience: experience,
    budget: budget,
    sort: sort,
  );

  /// Open projects matching every filter, sorted. [matches]: AI scores by project id, for "Best match".
  List<Project> apply(List<Project> projects, {Map<int, JobMatch> matches = const {}}) {
    final q = query.trim().toLowerCase();
    final result = projects.where((p) {
      if (!p.isOpen) return false;
      if (q.isNotEmpty && !p.title.toLowerCase().contains(q) && !p.description.toLowerCase().contains(q)) {
        return false;
      }
      if (category != null && p.category != category) return false;
      if (jobType != null && p.jobType != jobType) return false;
      if (experience != null && p.experienceLevel != experience) return false;
      return budget.contains(p.budget);
    }).toList();

    int byId(Project a, Project b) => (a.id ?? 0).compareTo(b.id ?? 0);
    int score(Project p) => matches[p.id]?.score ?? -1;
    result.sort(switch (sort) {
      FeedSort.bestMatch => (a, b) => score(b) != score(a) ? score(b).compareTo(score(a)) : byId(b, a),
      FeedSort.newest => (a, b) => byId(b, a),
      FeedSort.oldest => byId,
      FeedSort.highestBudget => (a, b) => b.budget.compareTo(a.budget),
      FeedSort.lowestBudget => (a, b) => a.budget.compareTo(b.budget),
    });
    return result;
  }
}

final feedFilterProvider = NotifierProvider<FeedFilterController, FeedFilter>(FeedFilterController.new);

class FeedFilterController extends Notifier<FeedFilter> {
  @override
  FeedFilter build() => const FeedFilter();

  void set(FeedFilter filter) => state = filter;
  void search(String query) => state = state.copyWith(query: query);
  void sortBy(FeedSort sort) => state = state.copyWith(sort: sort);

  /// Clears the search and the filters, keeps the sort order.
  void reset() => state = FeedFilter(sort: state.sort);
}

final feedProvider = Provider.autoDispose<AsyncValue<List<Project>>>((ref) {
  final filter = ref.watch(feedFilterProvider);
  final matches = filter.sort == FeedSort.bestMatch ? ref.watch(jobMatchesProvider).value ?? {} : <int, JobMatch>{};
  return ref.watch(projectsControllerProvider).whenData((all) => filter.apply(all, matches: matches));
});

// ── AI match ───────────────────────────────────────────────────────

/// Scores from this one up are recommended to the freelancer.
const recommendedMinScore = 40;

/// The logged-in freelancer's AI match score on each open project, by project id, best first.
/// Empty for clients and for freelancers without skills. Pull-to-refresh on the feed refreshes it.
// No automatic retry: a failing AI would keep the screens loading forever. Pull-to-refresh retries.
final jobMatchesProvider = FutureProvider<Map<int, JobMatch>>(retry: (_, _) => null, (ref) async {
  final session = await ref.watch(authControllerProvider.future);
  if (session == null || !session.isFreelancer) return {};
  final me = await ref.watch(currentUserProvider.future);
  if (me == null || me.competenceIds.isEmpty) return {};
  return ref.watch(projectRepositoryProvider).matchJobs(me.competenceIds);
});

/// From this score down, a job is too far from the freelancer to say what they should learn for it.
const _almostFitScore = 25;

/// Skills to learn (module 1): the ones missing or only "close" in open jobs that almost fit the
/// freelancer, most asked first (at most 5).
final skillsToLearnProvider = Provider.autoDispose<AsyncValue<List<SkillDemand>>>((ref) {
  return ref.watch(jobMatchesProvider).whenData((matches) {
    final counts = <String, int>{};
    for (final match in matches.values.where((m) => m.score >= _almostFitScore)) {
      for (final skill in {...match.missing, ...match.related}) {
        counts[skill] = (counts[skill] ?? 0) + 1;
      }
    }
    final ranked = counts.entries.toList()
      ..sort((a, b) => b.value != a.value ? b.value.compareTo(a.value) : a.key.compareTo(b.key));
    return [for (final e in ranked.take(5)) SkillDemand(e.key, e.value)];
  });
});

/// The freelancer's best open jobs (at most 5) that they haven't applied to yet, best first.
final recommendedJobsProvider = Provider.autoDispose<AsyncValue<List<(Project, JobMatch)>>>((ref) {
  final projects = {for (final p in ref.watch(projectsControllerProvider).value ?? <Project>[]) p.id: p};
  final applied = {for (final p in ref.watch(myProposalsProvider).value ?? <Proposal>[]) p.project?.id};
  return ref.watch(jobMatchesProvider).whenData((matches) {
    final picks = <(Project, JobMatch)>[];
    for (final MapEntry(key: id, value: match) in matches.entries) {
      final project = projects[id];
      if (project == null || !project.isOpen || applied.contains(id) || match.score < recommendedMinScore) continue;
      picks.add((project, match));
      if (picks.length == 5) break;
    }
    return picks;
  });
});

/// Client: how each freelancer who applied to [projectId] fits it, by freelancer id.
final candidateMatchesProvider = FutureProvider.autoDispose.family<Map<int, JobMatch>, int>(retry: (_, _) => null, (
  ref,
  projectId,
) async {
  // Only the applicants matter: answering a proposal doesn't ask the AI again.
  final applicants = await ref.watch(
    projectProposalsProvider(
      projectId,
    ).selectAsync((proposals) => ({...proposals.map((p) => p.freelancerId).nonNulls}.toList()..sort()).join(',')),
  );
  if (applicants.isEmpty) return {};
  final skills = <int, List<int>>{};
  for (final id in applicants.split(',').map(int.parse)) {
    try {
      skills[id] = (await ref.watch(projectUserProvider(id).future)).competenceIds;
    } on Object {
      // Profile not found: that applicant just gets no score.
    }
  }
  return ref.watch(projectRepositoryProvider).matchCandidates(projectId, skills);
});

// ── Proposals ──────────────────────────────────────────────────────

/// Proposals received on a project (client side), newest first.
final projectProposalsProvider = AsyncNotifierProvider.autoDispose
    .family<ProjectProposalsController, List<Proposal>, int>(ProjectProposalsController.new);

class ProjectProposalsController extends AsyncNotifier<List<Proposal>> {
  ProjectProposalsController(this.projectId);

  final int projectId;

  @override
  Future<List<Proposal>> build() async {
    final proposals = await ref.watch(projectRepositoryProvider).fetchProposals(projectId);
    return proposals..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
  }

  /// Accepting also moves the project to "In progress", like the web app.
  /// The list is patched in place (no reload), so the page doesn't flicker.
  Future<void> answer(Proposal proposal, ProposalStatus status) async {
    final updated = await ref.read(projectRepositoryProvider).updateProposalStatus(proposal.id!, status);
    state = AsyncData([for (final p in state.value ?? <Proposal>[]) p.id == updated.id ? updated : p]);
    if (status == ProposalStatus.accepted) {
      await ref.read(projectsControllerProvider.notifier).setStatus(projectId, ProjectStatus.active);
    }
  }
}

/// Proposals sent by the logged-in freelancer.
final myProposalsProvider = FutureProvider<List<Proposal>>((ref) async {
  final session = await ref.watch(authControllerProvider.future);
  if (session == null || !session.isFreelancer) return [];
  return ref.watch(projectRepositoryProvider).fetchFreelancerProposals(session.userId);
});

/// The logged-in freelancer's proposal on [projectId], if any.
final myProposalForProvider = Provider.autoDispose.family<AsyncValue<Proposal?>, int>((ref, projectId) {
  return ref
      .watch(myProposalsProvider)
      .whenData((proposals) => proposals.where((p) => p.project?.id == projectId).firstOrNull);
});

// ── Saved jobs & reactions (kept on the phone) ─────────────────────

final savedJobsProvider = AsyncNotifierProvider<SavedJobsController, Set<int>>(SavedJobsController.new);

class SavedJobsController extends AsyncNotifier<Set<int>> {
  int? _userId;

  @override
  Future<Set<int>> build() async {
    final session = await ref.watch(authControllerProvider.future);
    _userId = session?.userId;
    if (_userId == null) return {};
    return ref.read(projectPrefsProvider).savedJobs(_userId!);
  }

  Future<void> toggle(int projectId) async {
    final saved = {...?state.value};
    if (!saved.remove(projectId)) saved.add(projectId);
    state = AsyncData(saved);
    if (_userId != null) await ref.read(projectPrefsProvider).setSavedJobs(_userId!, saved);
  }
}

final myReactionsProvider = AsyncNotifierProvider<MyReactionsController, Map<int, ProjectReaction>>(
  MyReactionsController.new,
);

class MyReactionsController extends AsyncNotifier<Map<int, ProjectReaction>> {
  int? _userId;

  @override
  Future<Map<int, ProjectReaction>> build() async {
    final session = await ref.watch(authControllerProvider.future);
    _userId = session?.userId;
    if (_userId == null) return {};
    final stored = await ref.read(projectPrefsProvider).reactions(_userId!);
    return {for (final entry in stored.entries) entry.key: ?ProjectReaction.fromApi(entry.value)};
  }

  /// One reaction per project; picking another one replaces it.
  Future<void> react(Project project, ProjectReaction reaction) async {
    final id = project.id!;
    final reactions = {...?state.value};
    final previous = reactions[id];
    if (previous == reaction) return;

    final updated = await ref.read(projectRepositoryProvider).react(id, reaction, previous: previous);
    ref.read(projectsControllerProvider.notifier).put(updated);
    reactions[id] = reaction;
    state = AsyncData(reactions);
    if (_userId != null) {
      await ref
          .read(projectPrefsProvider)
          .setReactions(_userId!, reactions.map((key, value) => MapEntry(key, value.apiName)));
    }
  }
}

// ── Notifications ──────────────────────────────────────────────────

final notificationsProvider = AsyncNotifierProvider<NotificationsController, List<ProjectNotification>>(
  NotificationsController.new,
);

class NotificationsController extends AsyncNotifier<List<ProjectNotification>> {
  @override
  Future<List<ProjectNotification>> build() async {
    final session = await ref.watch(authControllerProvider.future);
    if (session == null) return [];
    return ref.watch(projectRepositoryProvider).fetchNotifications(session.userId);
  }

  Future<void> markRead(ProjectNotification notification) async {
    if (notification.read) return;
    state = AsyncData([
      for (final n in state.value ?? <ProjectNotification>[]) n.id == notification.id ? n.markedRead() : n,
    ]);
    await ref.read(projectRepositoryProvider).markNotificationRead(notification.id);
  }

  Future<void> markAllRead() async {
    final unread = (state.value ?? []).where((n) => !n.read).toList();
    state = AsyncData([for (final n in state.value ?? <ProjectNotification>[]) n.markedRead()]);
    await Future.wait(unread.map((n) => ref.read(projectRepositoryProvider).markNotificationRead(n.id)));
  }
}

final unreadNotificationsProvider = Provider<int>(
  (ref) => ref.watch(notificationsProvider).value?.where((n) => !n.read).length ?? 0,
);

// ── People ─────────────────────────────────────────────────────────

/// Name and avatar of a client or freelancer shown on a project or proposal.
final projectUserProvider = FutureProvider.family<AppUser, int>(
  (ref, id) => ref.watch(authRepositoryProvider).fetchUser(id),
);

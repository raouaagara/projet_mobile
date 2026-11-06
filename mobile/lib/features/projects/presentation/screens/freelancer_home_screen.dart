import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_paths.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../data/models/job_match.dart';
import '../../data/models/project.dart';
import '../../data/models/project_enums.dart';
import '../../data/models/proposal.dart';
import '../../project_paths.dart';
import '../format.dart';
import '../project_providers.dart';
import '../widgets/category_style.dart';
import '../widgets/feed_filter_sheet.dart';
import '../widgets/home_widgets.dart';
import '../widgets/match_widgets.dart';
import '../widgets/module_link.dart';
import '../widgets/project_card.dart';
import '../widgets/save_job_button.dart';
import '../widgets/status_chips.dart';

/// Freelancer home: job feed, my proposals and saved jobs.
class FreelancerHomeScreen extends StatelessWidget {
  const FreelancerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              HomeHeader(),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: PillTabBar(tabs: ['Jobs', 'My proposals', 'Saved']),
              ),
              Expanded(child: TabBarView(children: [_JobsTab(), _ProposalsTab(), _SavedTab()])),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _projectTile(BuildContext context, Project project, {JobMatch? match}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: ProjectCard(
    project: project,
    match: match,
    trailing: SaveJobButton(projectId: project.id!),
    onTap: () => context.push(ProjectPaths.details(project.id!)),
  ),
);

// ── Jobs ───────────────────────────────────────────────────────────

class _JobsTab extends ConsumerStatefulWidget {
  const _JobsTab();

  @override
  ConsumerState<_JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends ConsumerState<_JobsTab> {
  late final _search = TextEditingController(text: ref.read(feedFilterProvider).query);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() => Future.wait([
    ref.refresh(projectsControllerProvider.future),
    ref.refresh(notificationsProvider.future),
    // A failing AI must not break pull-to-refresh: the feed works without scores.
    ref.refresh(jobMatchesProvider.future).then((_) {}, onError: (_) {}),
  ]);

  Future<void> _openFilters() async {
    final filter = await showFeedFilterSheet(context, ref.read(feedFilterProvider));
    if (filter != null) ref.read(feedFilterProvider.notifier).set(filter);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(feedFilterProvider);
    final jobs = ref.watch(feedProvider);
    final matches = ref.watch(jobMatchesProvider).value ?? const {};
    // "Clear filters" also empties the search box.
    ref.listen(feedFilterProvider.select((f) => f.query), (_, query) {
      if (_search.text != query) _search.text = query;
    });

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: ref.read(feedFilterProvider.notifier).search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search jobs',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    suffixIcon: filter.query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => ref.read(feedFilterProvider.notifier).search(''),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Filters',
                onPressed: _openFilters,
                style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                icon: Badge(
                  isLabelVisible: filter.activeCount > 0,
                  label: Text('${filter.activeCount}'),
                  child: const Icon(Icons.tune),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilterPills<ProjectCategory?>(
            values: [null, ...ProjectCategory.values],
            selected: filter.category,
            label: (category) => category?.label ?? 'All jobs',
            onSelected: (category) => ref.read(feedFilterProvider.notifier).set(filter.withCategory(category)),
          ),
          const SizedBox(height: 20),
          const _Recommended(),
          PromoBanner(
            title: 'Stand out with a',
            highlight: 'certificate',
            action: 'Take a skill test',
            image: 'assets/onboarding/get_started.svg',
            onPressed: () =>
                openModuleLink(context, AppPaths.skillTests, comingSoon: 'Skill tests arrive with module 1 (profile).'),
          ),
          const SizedBox(height: 20),
          AsyncValueView(
            value: jobs,
            onRetry: () => ref.invalidate(projectsControllerProvider),
            data: (jobs) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      filter.category == null
                          ? '${jobs.length} open job${jobs.length == 1 ? '' : 's'}'
                          : '${jobs.length} in ${filter.category!.label.toLowerCase()}',
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 19, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    PopupMenuButton<FeedSort>(
                      initialValue: filter.sort,
                      onSelected: ref.read(feedFilterProvider.notifier).sortBy,
                      itemBuilder: (context) => [
                        for (final sort in FeedSort.values) PopupMenuItem(value: sort, child: Text(sort.label)),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sort, size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              filter.sort.label,
                              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (jobs.isEmpty) ...[
                  const SizedBox(height: 24),
                  const EmptyView(message: 'No job matches your search.', icon: Icons.search_off),
                  if (filter.activeCount > 0 || filter.query.isNotEmpty)
                    Center(
                      child: TextButton(
                        onPressed: ref.read(feedFilterProvider.notifier).reset,
                        child: const Text('Clear search and filters'),
                      ),
                    ),
                ],
                for (final project in jobs) _projectTile(context, project, match: matches[project.id]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Recommended for you": the open jobs the AI scores best for my skills.
class _Recommended extends ConsumerWidget {
  const _Recommended();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final me = ref.watch(currentUserProvider).value;
    if (me != null && me.competenceIds.isEmpty) {
      return const Padding(padding: EdgeInsets.only(bottom: 16), child: AddSkillsCard());
    }
    final recommended = ref.watch(recommendedJobsProvider);
    if (recommended.hasError) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          'Job recommendations are unavailable right now. Pull down to try again.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }
    final picks = recommended.value;
    if (picks != null && picks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 20, color: AppAccent.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recommended for you',
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 19, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: () => ref.read(feedFilterProvider.notifier).sortBy(FeedSort.bestMatch),
                child: const Text('Sort by match'),
              ),
            ],
          ),
          Text(
            'Picked by AI from your skills',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 112,
            child: picks == null
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: picks.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) => _RecommendedCard(project: picks[i].$1, match: picks[i].$2),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.project, required this.match});

  final Project project;
  final JobMatch match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = MatchLevel.of(match.score);
    return SizedBox(
      width: 272,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(ProjectPaths.details(project.id!)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                MatchRing(score: match.score, size: 58),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        level.label,
                        style: theme.textTheme.labelMedium?.copyWith(color: level.color, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        project.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: project.budgetLabel,
                              style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
                            ),
                            if (match.matched.isNotEmpty) TextSpan(text: '   you know ${match.matched.join(', ')}'),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── My proposals ───────────────────────────────────────────────────

class _ProposalsTab extends ConsumerWidget {
  const _ProposalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueView(
      value: ref.watch(myProposalsProvider),
      onRetry: () => ref.invalidate(myProposalsProvider),
      data: (proposals) => RefreshIndicator(
        onRefresh: () => ref.refresh(myProposalsProvider.future),
        child: proposals.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 96),
                  EmptyView(
                    message: "You haven't sent any proposal yet.\nFind a job in the Jobs tab.",
                    icon: Icons.send_outlined,
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: proposals.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _ProposalCard(proposal: proposals[i]),
              ),
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({required this.proposal});

  final Proposal proposal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final project = proposal.project;
    final category = project?.category ?? ProjectCategory.other;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: project?.id == null ? null : () => context.push(ProjectPaths.details(project!.id!)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBubble(icon: category.icon, color: categoryColor(category), size: 44, solid: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            project?.title ?? 'Project',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ProposalStatusChip(status: proposal.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        PillTag('Your bid: ${proposal.bidLabel}', icon: Icons.gavel_rounded),
                        if (project != null)
                          PillTag(
                            'Budget: ${project.budgetLabel}',
                            icon: Icons.payments_outlined,
                            color: AppAccent.blue,
                          ),
                        if (proposal.estimationEndDate != null)
                          PillTag(
                            formatDay(proposal.estimationEndDate!),
                            icon: Icons.event_outlined,
                            color: AppAccent.purple,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Saved ──────────────────────────────────────────────────────────

class _SavedTab extends ConsumerWidget {
  const _SavedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedJobsProvider).value ?? {};
    final matches = ref.watch(jobMatchesProvider).value ?? const {};
    return AsyncValueView(
      value: ref.watch(projectsControllerProvider),
      onRetry: () => ref.invalidate(projectsControllerProvider),
      data: (all) {
        final projects = all.where((p) => saved.contains(p.id)).toList();
        if (projects.isEmpty) {
          return const EmptyView(message: 'Tap the bookmark on a job to find it here.', icon: Icons.bookmark_border);
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [for (final project in projects) _projectTile(context, project, match: matches[project.id])],
        );
      },
    );
  }
}

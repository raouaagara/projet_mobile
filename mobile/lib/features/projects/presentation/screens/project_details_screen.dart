import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/models/project.dart';
import '../../data/models/project_enums.dart';
import '../../data/models/proposal.dart';
import '../../data/skill_catalog.dart';
import '../../project_paths.dart';
import '../format.dart';
import '../project_providers.dart';
import '../widgets/category_style.dart';
import '../widgets/match_widgets.dart';
import '../widgets/module_link.dart';
import '../widgets/person_tile.dart';
import '../widgets/reaction_bar.dart';
import '../widgets/save_job_button.dart';
import '../widgets/status_chips.dart';

/// A project, for its client (manage it) or for a freelancer (apply).
class ProjectDetailsScreen extends ConsumerWidget {
  const ProjectDetailsScreen({super.key, required this.projectId});

  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider(projectId));
    if (project.value case final loaded?) return _Details(project: loaded);
    return Scaffold(
      appBar: AppBar(),
      body: AsyncValueView(
        value: project,
        onRetry: () => ref.invalidate(projectsControllerProvider),
        data: (_) => const SizedBox(),
      ),
    );
  }
}

class _Details extends ConsumerWidget {
  const _Details({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).value;
    final isFreelancer = session?.isFreelancer ?? false;
    final isOwner = session != null && session.userId == project.clientId;
    final image = project.imageProvider;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          ref.refresh(projectsControllerProvider.future),
          if (isFreelancer) ref.refresh(myProposalsProvider.future),
          if (isFreelancer) ref.refresh(jobMatchesProvider.future).then((_) {}, onError: (_) {}),
        ]),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: image == null ? null : 220,
              flexibleSpace: image == null
                  ? null
                  : FlexibleSpaceBar(
                      background: Image(image: image, fit: BoxFit.cover),
                    ),
              actions: [
                if (isFreelancer) SaveJobButton(projectId: project.id!),
                if (isOwner) _OwnerMenu(project: project),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              sliver: SliverList.list(
                children: [
                  _Header(project: project),
                  const SizedBox(height: 22),
                  _Facts(project: project),
                  const SizedBox(height: 28),
                  if (isFreelancer && project.isOpen) _MatchCard(projectId: project.id!),
                  _Block(
                    title: 'About the job',
                    child: SelectableText(
                      project.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55),
                    ),
                  ),
                  if (project.requiredCompetenceIds.isNotEmpty)
                    _Block(
                      title: 'Skills needed',
                      child: _RequiredSkills(ids: project.requiredCompetenceIds),
                    ),
                  _Block(
                    title: 'Reactions',
                    child: ReactionBar(project: project),
                  ),
                  if (!isOwner && project.clientId != null) ...[
                    _Block(
                      title: 'Posted by',
                      child: PersonTile(
                        userId: project.clientId!,
                        trailing: IconButton.filledTonal(
                          tooltip: 'Message',
                          icon: const Icon(Icons.chat_bubble_outline),
                          onPressed: () => openModuleLink(
                            context,
                            LinkedPaths.chatWith(project.clientId!),
                            comingSoon: 'Chat arrives with module 4 (messaging).',
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isOwner
          ? _OwnerBar(project: project)
          : isFreelancer
          ? _FreelancerBar(project: project)
          : null,
    );
  }
}

/// A part of the page: a title and its content, no card.
class _Block extends StatelessWidget {
  const _Block({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Field and status, the title as the headline, and when it was posted.
class _Header extends StatelessWidget {
  const _Header({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final category = project.category ?? ProjectCategory.other;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                category.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: categoryColor(category),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ProjectStatusChip(status: project.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          project.title,
          style: theme.textTheme.headlineMedium?.copyWith(fontSize: 27, fontWeight: FontWeight.w800, height: 1.18),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.access_time, size: 15, color: muted),
            const SizedBox(width: 4),
            Text(postedLabel(project.postedAt), style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
          ],
        ),
      ],
    );
  }
}

/// Budget, payment and level as three figures in type, the budget first and largest.
class _Facts extends StatelessWidget {
  const _Facts({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    Widget figure(String value, String label, {double size = 18}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(fontSize: size, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(label, style: muted),
      ],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        figure(project.budgetLabel, 'Budget', size: 30),
        const SizedBox(width: 28),
        Expanded(child: figure(project.jobType?.label ?? '—', 'Payment')),
        Expanded(child: figure(project.experienceLevel ?? '—', 'Level')),
      ],
    );
  }
}

/// Freelancer: how well my skills fit this job, scored by the AI.
class _MatchCard extends ConsumerWidget {
  const _MatchCard({required this.projectId});

  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final me = ref.watch(currentUserProvider).value;
    if (me != null && me.competenceIds.isEmpty) {
      return const Padding(padding: EdgeInsets.only(bottom: 28), child: AddSkillsCard());
    }
    final matches = ref.watch(jobMatchesProvider);
    final match = matches.value?[projectId];
    if (match == null) {
      if (!matches.isLoading) return const SizedBox.shrink(); // AI offline: the page works without it
      return const Padding(padding: EdgeInsets.only(bottom: 28), child: LinearProgressIndicator());
    }

    final level = MatchLevel.of(match.score);
    final needed = match.matched.length + match.related.length + match.missing.length;
    final summary = needed == 0
        ? 'Scored from how close the job is to your skills.'
        : 'You have ${match.matched.length} of the $needed skills this job asks for.';
    // Tinted: this is the AI talking about you, not the client's job.
    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppAccent.purple.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: AppAccent.purple),
              const SizedBox(width: 8),
              Text('Your match', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              MatchRing(score: match.score),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.label,
                      style: theme.textTheme.titleMedium?.copyWith(color: level.color, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (needed > 0) ...[const SizedBox(height: 14), MatchSkills(match: match)],
        ],
      ),
    );
  }
}

class _RequiredSkills extends ConsumerWidget {
  const _RequiredSkills({required this.ids});

  final List<int> ids;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(skillCatalogProvider).value ?? {};
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final id in ids)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Text(catalog[id]?.name ?? 'Skill #$id', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

// ── Client (owner) ─────────────────────────────────────────────────

class _OwnerBar extends ConsumerWidget {
  const _OwnerBar({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(projectProposalsProvider(project.id!)).value?.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: () => context.push(ProjectPaths.proposals(project.id!)),
          icon: const Icon(Icons.people_alt_outlined),
          label: Text(count == null ? 'View proposals' : 'View proposals ($count)'),
        ),
      ),
    );
  }
}

enum _OwnerAction { edit, status, delete }

class _OwnerMenu extends ConsumerWidget {
  const _OwnerMenu({required this.project});

  final Project project;

  Future<void> _changeStatus(BuildContext context, WidgetRef ref) async {
    final status = await showModalBottomSheet<ProjectStatus>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: RadioGroup<ProjectStatus>(
          groupValue: project.status,
          onChanged: (value) => Navigator.pop(context, value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('Project status')),
              for (final status in ProjectStatus.choices)
                RadioListTile<ProjectStatus>(
                  value: status,
                  secondary: Icon(status.icon),
                  title: Text(status.label),
                  subtitle: Text(switch (status) {
                    ProjectStatus.open => 'Freelancers can send proposals',
                    ProjectStatus.active => 'Someone is working on it',
                    _ => 'Finished or cancelled',
                  }),
                ),
            ],
          ),
        ),
      ),
    );
    if (status == null || status == project.status || !context.mounted) return;
    await _run(
      context,
      () => ref.read(projectsControllerProvider.notifier).setStatus(project.id!, status),
      done: 'Status changed to ${status.label}.',
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this project?'),
        content: const Text('Its proposals are deleted too. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              minimumSize: const Size(0, 40),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final router = GoRouter.of(context);
    final ok = await _run(
      context,
      () => ref.read(projectsControllerProvider.notifier).delete(project.id!),
      done: 'Project deleted.',
    );
    if (ok) router.pop();
  }

  Future<bool> _run(BuildContext context, Future<void> Function() action, {required String done}) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
      return true;
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_OwnerAction>(
      onSelected: (action) => switch (action) {
        _OwnerAction.edit => context.push(ProjectPaths.edit(project.id!)),
        _OwnerAction.status => _changeStatus(context, ref),
        _OwnerAction.delete => _delete(context, ref),
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _OwnerAction.edit,
          child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit')),
        ),
        PopupMenuItem(
          value: _OwnerAction.status,
          child: ListTile(leading: Icon(Icons.flag_outlined), title: Text('Change status')),
        ),
        PopupMenuItem(
          value: _OwnerAction.delete,
          child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete')),
        ),
      ],
    );
  }
}

// ── Freelancer ─────────────────────────────────────────────────────

class _FreelancerBar extends ConsumerWidget {
  const _FreelancerBar({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposal = ref.watch(myProposalForProvider(project.id!));
    final Widget child;
    if (proposal.isLoading && !proposal.hasValue) {
      child = const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()));
    } else if (proposal.value case final Proposal mine) {
      child = _MyProposal(proposal: mine);
    } else if (project.isOpen) {
      child = FilledButton.icon(
        onPressed: () => context.push(ProjectPaths.propose(project.id!)),
        icon: const Icon(Icons.send),
        label: const Text('Submit a proposal'),
      );
    } else {
      child = Text(
        'This project is not accepting proposals anymore.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.outline),
      );
    }
    return SafeArea(
      child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: child),
    );
  }
}

class _MyProposal extends StatelessWidget {
  const _MyProposal({required this.proposal});

  final Proposal proposal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        leading: const IconBubble(icon: Icons.task_alt, color: AppAccent.green, size: 42),
        title: Text(
          'You bid ${proposal.bidLabel}',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: proposal.estimationEndDate == null
            ? null
            : Text('Delivery by ${formatDay(proposal.estimationEndDate!)}'),
        trailing: ProposalStatusChip(status: proposal.status),
      ),
    );
  }
}

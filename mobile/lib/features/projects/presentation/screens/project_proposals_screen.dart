import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/models/job_match.dart';
import '../../data/models/project.dart';
import '../../data/models/project_enums.dart';
import '../../data/models/proposal.dart';
import '../../project_paths.dart';
import '../format.dart';
import '../project_providers.dart';
import '../widgets/match_widgets.dart';
import '../widgets/module_link.dart';
import '../widgets/person_tile.dart';
import '../widgets/status_chips.dart';

enum _Sort {
  bestMatch('Best match', Icons.auto_awesome),
  newest('Newest', Icons.schedule),
  lowestBid('Lowest bid', Icons.south);

  const _Sort(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Client: proposals received on one of my projects, ranked by the AI — accept or decline them.
class ProjectProposalsScreen extends ConsumerStatefulWidget {
  const ProjectProposalsScreen({super.key, required this.projectId});

  final int projectId;

  @override
  ConsumerState<ProjectProposalsScreen> createState() => _ProjectProposalsScreenState();
}

class _ProjectProposalsScreenState extends ConsumerState<ProjectProposalsScreen> {
  _Sort _sort = _Sort.bestMatch;

  int get projectId => widget.projectId;

  List<Proposal> _sorted(List<Proposal> proposals, Map<int, JobMatch> matches) {
    int score(Proposal p) => matches[p.freelancerId]?.score ?? -1;
    int newest(Proposal a, Proposal b) => (b.id ?? 0).compareTo(a.id ?? 0);
    return [...proposals]..sort(switch (_sort) {
      _Sort.bestMatch => (a, b) => score(b) != score(a) ? score(b).compareTo(score(a)) : newest(a, b),
      _Sort.newest => newest,
      _Sort.lowestBid => (a, b) => a.bidAmount.compareTo(b.bidAmount),
    });
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectProvider(projectId)).value;
    final userId = ref.watch(authControllerProvider).value?.userId;
    final proposals = ref.watch(projectProposalsProvider(projectId));
    final matching = ref.watch(candidateMatchesProvider(projectId));
    final matches = matching.value ?? const <int, JobMatch>{};

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Proposals'),
            if (project != null)
              Text(
                project.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
      body: project != null && project.clientId != userId
          ? const ErrorView(message: 'Only the client who posted this project can see its proposals.')
          : AsyncValueView(
              value: proposals,
              onRetry: () => ref.invalidate(projectProposalsProvider(projectId)),
              data: (proposals) => RefreshIndicator(
                onRefresh: () => ref.refresh(projectProposalsProvider(projectId).future),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    if (proposals.isEmpty) ...[
                      const SizedBox(height: 80),
                      const EmptyView(
                        message: "No proposal yet.\nYou'll get a notification when a freelancer applies.",
                        icon: Icons.hourglass_empty,
                      ),
                    ] else ...[
                      _Stats(proposals: proposals),
                      const SizedBox(height: 16),
                      FilterPills<_Sort>(
                        values: _Sort.values,
                        selected: _sort,
                        label: (sort) => sort.label,
                        icon: (sort) => sort.icon,
                        onSelected: (sort) => setState(() => _sort = sort),
                      ),
                      const SizedBox(height: 8),
                      if (_sort == _Sort.bestMatch)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            matching.isLoading
                                ? 'The AI is comparing their skills with your project…'
                                : matching.hasError
                                ? 'AI ranking is unavailable right now: newest first.'
                                : 'Ranked by AI: how well their skills fit your project.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                      for (final proposal in _sorted(proposals, matches))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ProposalCard(
                            key: ValueKey(proposal.id),
                            proposal: proposal,
                            project: project,
                            match: matches[proposal.freelancerId],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.proposals});

  final List<Proposal> proposals;

  @override
  Widget build(BuildContext context) {
    final average = proposals.map((p) => p.bidAmount).reduce((a, b) => a + b) / proposals.length;
    final pending = proposals.where((p) => p.status == ProposalStatus.pending).length;
    return Row(
      children: [
        Expanded(
          child: StatTile(
            icon: Icons.people_alt_outlined,
            color: AppAccent.blue,
            value: '${proposals.length}',
            label: 'Proposals',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatTile(
            icon: Icons.payments_outlined,
            color: AppAccent.green,
            value: formatMoney(average),
            label: 'Average bid',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatTile(icon: Icons.hourglass_empty, color: AppAccent.amber, value: '$pending', label: 'To answer'),
        ),
      ],
    );
  }
}

class _ProposalCard extends ConsumerStatefulWidget {
  const _ProposalCard({super.key, required this.proposal, required this.project, this.match});

  final Proposal proposal;
  final Project? project;

  /// How this freelancer's skills fit the project (AI).
  final JobMatch? match;

  @override
  ConsumerState<_ProposalCard> createState() => _ProposalCardState();
}

class _ProposalCardState extends ConsumerState<_ProposalCard> {
  bool _busy = false;

  Proposal get _proposal => widget.proposal;

  Future<bool> _confirm(String title, String message, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _answer(ProposalStatus status) async {
    final accept = status == ProposalStatus.accepted;
    final name = ref.read(projectUserProvider(_proposal.freelancerId ?? 0)).value?.firstName ?? 'this freelancer';
    final confirmed = accept
        ? await _confirm(
            'Accept this proposal?',
            'You hire $name for ${_proposal.bidLabel}. The project moves to "In progress".',
            'Accept',
          )
        : await _confirm('Decline this proposal?', '$name will be notified.', 'Decline');
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    final projectId = widget.project?.id ?? _proposal.project!.id!;
    final proposalId = _proposal.id!;
    // This card may be rebuilt while the requests run: keep a context that stays.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(projectProposalsProvider(projectId).notifier).answer(_proposal, status);
      if (accept && navigator.mounted) await _offerContract(navigator.context, name, proposalId);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Next step after hiring: module 3 creates the contract from the proposal.
  static Future<void> _offerContract(BuildContext context, String name, int proposalId) async {
    final create = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.handshake_outlined),
        title: const Text('Proposal accepted'),
        content: Text('Create the contract with $name now: the payment is kept in escrow until the job is done.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Later')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create contract'),
          ),
        ],
      ),
    );
    if (create == true && context.mounted) _openContract(context, proposalId);
  }

  static void _openContract(BuildContext context, int proposalId) => openModuleLink(
    context,
    LinkedPaths.newContract(proposalId),
    comingSoon: 'Contracts arrive with module 3 (contracts & payments).',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final project = widget.project;
    final canAnswer = _proposal.status == ProposalStatus.pending && (project?.isOpen ?? false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_proposal.freelancerId != null)
              PersonTile(
                userId: _proposal.freelancerId!,
                trailing: ProposalStatusChip(status: _proposal.status),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _proposal.bidLabel,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                if (widget.match != null) MatchPill(match: widget.match!),
              ],
            ),
            if (widget.match case final match? when match.matched.isNotEmpty || match.missing.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                [
                  if (match.matched.isNotEmpty) 'Has ${match.matched.join(', ')}',
                  if (match.missing.isNotEmpty) 'Missing ${match.missing.join(', ')}',
                ].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (project != null)
                  PillTag('Your budget: ${project.budgetLabel}', icon: Icons.payments_outlined, color: AppAccent.blue),
                if (_proposal.estimationEndDate != null)
                  PillTag(
                    'Delivery by ${formatDay(_proposal.estimationEndDate!)}',
                    icon: Icons.event_outlined,
                    color: AppAccent.purple,
                  ),
              ],
            ),
            if (_proposal.coverLetter?.trim() case final letter? when letter.isNotEmpty) ...[
              const SizedBox(height: 12),
              _CoverLetter(text: letter),
            ],
            if (canAnswer) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                      onPressed: _busy ? null : () => _answer(ProposalStatus.rejected),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                      onPressed: _busy ? null : () => _answer(ProposalStatus.accepted),
                      child: _busy
                          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
            if (_proposal.status == ProposalStatus.accepted) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                onPressed: () => _openContract(context, _proposal.id!),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Create the contract'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The freelancer's letter, cut to 4 lines until "Read more".
class _CoverLetter extends StatefulWidget {
  const _CoverLetter({required this.text});

  final String text;

  @override
  State<_CoverLetter> createState() => _CoverLetterState();
}

class _CoverLetterState extends State<_CoverLetter> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(height: 1.45);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final painter = TextPainter(
            text: TextSpan(text: widget.text, style: style),
            maxLines: 4,
            textDirection: Directionality.of(context),
          )..layout(maxWidth: constraints.maxWidth);
          final long = painter.didExceedMaxLines;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cover letter', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                widget.text,
                style: style,
                maxLines: _open ? null : 4,
                overflow: _open ? null : TextOverflow.ellipsis,
              ),
              if (long)
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
                  onPressed: () => setState(() => _open = !_open),
                  child: Text(_open ? 'Show less' : 'Read more'),
                )
              else
                const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }
}

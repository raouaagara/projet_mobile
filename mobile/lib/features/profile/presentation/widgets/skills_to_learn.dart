import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/app_user.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../projects/data/models/job_match.dart';
import '../../../projects/presentation/project_providers.dart';
import '../../data/profile_ai_repository.dart';

/// My profile: skills asked in open jobs that almost fit me (from the AI match scores),
/// and a learning plan written by the AI. Hidden when there is nothing to suggest.
class SkillsToLearnCard extends ConsumerWidget {
  const SkillsToLearnCard({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skills = ref.watch(skillsToLearnProvider).value;
    if (skills == null || skills.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    // The only tinted block on the profile: it is the AI talking, not the person.
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppAccent.purple.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: AppAccent.purple),
              const SizedBox(width: 8),
              Text('Worth learning next', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Open jobs you almost fit ask for these',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          for (final skill in skills)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  const IconBubble(icon: Icons.trending_up, color: AppAccent.purple, size: 34, solid: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(skill.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  PillTag('${skill.jobs} job${skill.jobs == 1 ? '' : 's'}', color: AppAccent.purple),
                ],
              ),
            ),
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppAccent.purple, foregroundColor: Colors.white),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => _PlanSheet(user: user, skills: skills),
            ),
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Make my learning plan'),
          ),
        ],
      ),
    );
  }
}

class _PlanSheet extends ConsumerStatefulWidget {
  const _PlanSheet({required this.user, required this.skills});

  final AppUser user;
  final List<SkillDemand> skills;

  @override
  ConsumerState<_PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends ConsumerState<_PlanSheet> {
  late Future<List<PlanItem>> _plan = _load();

  Future<List<PlanItem>> _load() => ref
      .read(profileAiRepositoryProvider)
      .learningPlan(skillIds: widget.user.competenceIds, skills: widget.skills.take(3).toList());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, scroll) => FutureBuilder<List<PlanItem>>(
        future: _plan,
        builder: (context, snapshot) {
          final Widget body;
          if (snapshot.connectionState != ConnectionState.done) {
            body = const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [CircularProgressIndicator(), SizedBox(height: 16), Text('The AI is preparing your plan…')],
              ),
            );
          } else if (snapshot.hasError) {
            body = ErrorView(
              message: ApiException.from(snapshot.error!).message,
              onRetry: () => setState(() => _plan = _load()),
            );
          } else {
            body = Column(children: [for (final item in snapshot.data!) _PlanCard(item: item)]);
          }
          return ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text('Your learning plan', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'Written by AI from your skills and the jobs you almost fit.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              body,
            ],
          );
        },
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.item});

  final PlanItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconBubble(icon: Icons.school_outlined, color: AppAccent.purple, size: 40, solid: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(item.skill, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ),
                PillTag(
                  '~${item.weeks} week${item.weeks == 1 ? '' : 's'}',
                  icon: Icons.schedule,
                  color: AppAccent.blue,
                ),
              ],
            ),
            if (item.why.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(item.why, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
            ],
            const SizedBox(height: 8),
            for (final (i, step) in item.steps.indexed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: AppAccent.purple.withValues(alpha: 0.12),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppAccent.purple),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(step, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

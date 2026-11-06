import 'package:flutter/material.dart';

import '../../../../shared/widgets/ui_kit.dart';
import '../../data/models/job_match.dart';
import '../../project_paths.dart';
import 'module_link.dart';

/// Score bands shown to users.
enum MatchLevel {
  great('Great match', AppAccent.green),
  good('Good match', AppAccent.blue),
  low('Low match', AppAccent.grey);

  const MatchLevel(this.label, this.color);

  final String label;
  final Color color;

  static MatchLevel of(int score) => score >= 70 ? great : (score >= 40 ? good : low);
}

/// "87% match", colored by level.
class MatchPill extends StatelessWidget {
  const MatchPill({super.key, required this.match});

  final JobMatch match;

  @override
  Widget build(BuildContext context) =>
      PillTag('${match.score}% match', icon: Icons.auto_awesome, color: MatchLevel.of(match.score).color);
}

/// The score in a ring.
class MatchRing extends StatelessWidget {
  const MatchRing({super.key, required this.score, this.size = 64});

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = MatchLevel.of(score).color;
    return Semantics(
      label: '$score% match',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: score / 100,
              strokeWidth: size / 10,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
            Center(
              child: Text(
                '$score%',
                style: TextStyle(fontSize: size * 0.26, fontWeight: FontWeight.w800, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The job's skills in three groups: the ones the freelancer has, close ones, missing ones.
class MatchSkills extends StatelessWidget {
  const MatchSkills({
    super.key,
    required this.match,
    this.hasLabel = 'You have',
    this.relatedLabel = 'Close to what you know',
    this.missingLabel = 'To learn',
  });

  final JobMatch match;
  final String hasLabel;
  final String relatedLabel;
  final String missingLabel;

  @override
  Widget build(BuildContext context) {
    final groups = [
      (hasLabel, match.matched, Icons.check_circle, AppAccent.green),
      (relatedLabel, match.related, Icons.swap_horiz, AppAccent.blue),
      (missingLabel, match.missing, Icons.add_circle_outline, AppAccent.grey),
    ].where((g) => g.$2.isNotEmpty);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, skills, icon, color) in groups) ...[
          Text(label, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [for (final skill in skills) PillTag(skill, icon: icon, color: color)],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Freelancer without skills: the AI can't rank jobs yet.
class AddSkillsCard extends StatelessWidget {
  const AddSkillsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const IconBubble(icon: Icons.auto_awesome, color: AppAccent.purple, size: 46, solid: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get jobs picked for you',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Add your skills and the AI scores every job for you.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: () =>
                  openModuleLink(context, LinkedPaths.skills, comingSoon: 'Skills arrive with module 1 (profile).'),
              child: const Text('Add skills'),
            ),
          ],
        ),
      ),
    );
  }
}

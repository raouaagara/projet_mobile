import 'package:flutter/material.dart';

import '../../data/models/job_match.dart';
import '../../data/models/project.dart';
import '../../data/models/project_enums.dart';
import '../format.dart';
import 'category_style.dart';
import 'match_widgets.dart';

/// A project in a list. Read like a job ad: field, title, then the money as the one strong figure,
/// the summary, and the details in plain muted text. Only the AI match is colored.
class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.project, required this.onTap, this.trailing, this.match});

  final Project project;
  final VoidCallback onTap;

  /// Top-right corner: a status chip for clients, a bookmark for freelancers.
  final Widget? trailing;

  /// The freelancer's AI match score on this job.
  final JobMatch? match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final category = project.category ?? ProjectCategory.other;
    final image = project.imageProvider;
    final per = project.jobType == JobType.fixedPrice ? ' fixed price' : '';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (image != null)
              AspectRatio(
                aspectRatio: 16 / 7,
                child: Image(image: image, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox()),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.label,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: categoryColor(category),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              project.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.25),
                            ),
                          ],
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: project.budgetLabel,
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 20),
                              ),
                              TextSpan(
                                text: per,
                                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          project.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(color: muted, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 14,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // A low score is noise on a list: only show the ones worth a look.
                            if (match != null && match!.score >= 40) MatchPill(match: match!),
                            if (project.experienceLevel != null)
                              _Detail(icon: Icons.trending_up, text: project.experienceLevel!),
                            _Detail(icon: Icons.access_time, text: postedLabel(project.postedAt)),
                            if (project.totalReactions > 0) ReactionSummary(project: project),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: muted),
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.labelMedium?.copyWith(color: muted)),
      ],
    );
  }
}

/// "👍❤️ 5": the reactions used on a project and their total.
class ReactionSummary extends StatelessWidget {
  const ReactionSummary({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final used = ProjectReaction.values.where((r) => project.reactions(r) > 0);
    return Text(
      '${used.map((r) => r.emoji).join()} ${project.totalReactions}',
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}

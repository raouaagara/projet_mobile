import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../data/learning_tracker.dart';

/// My learning tracker: the skills I chose to learn (saved on the phone, SQLite) and their steps,
/// ticked, edited, added and deleted here.
class LearningTrackerScreen extends ConsumerWidget {
  const LearningTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracked = ref.watch(trackedSkillsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My learning')),
      body: AsyncValueView(
        value: tracked,
        onRetry: () => ref.invalidate(trackedSkillsProvider),
        data: (skills) => skills.isEmpty
            ? const EmptyView(
                icon: Icons.school_outlined,
                message: 'Nothing tracked yet.\nOn your profile, "Make my learning plan", then "Track it".',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Text(
                    'Saved on this phone: works without the internet.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  for (final skill in skills) _SkillCard(skill: skill),
                ],
              ),
      ),
    );
  }
}

class _SkillCard extends ConsumerWidget {
  const _SkillCard({required this.skill});

  final TrackedSkill skill;

  Future<String?> _ask(BuildContext context, {required String title, String initial = ''}) {
    final text = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: text,
          autofocus: true,
          maxLines: 3,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(context, text.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stop tracking ${skill.skill}?'),
        content: const Text('Its steps are deleted from this phone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(trackedSkillsProvider.notifier).delete(skill);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(trackedSkillsProvider.notifier);
    final complete = skill.steps.isNotEmpty && skill.done == skill.steps.length;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(skill.skill, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ),
                if (complete) const PillTag('Done', icon: Icons.check_circle, color: AppAccent.green),
                IconButton(
                  tooltip: 'Delete ${skill.skill}',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, ref),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: skill.progress,
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.surfaceContainerHigh,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${skill.done} of ${skill.steps.length} steps',
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (skill.why.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 8),
                child: Text(
                  skill.why,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: 4),
            for (final step in skill.steps)
              Row(
                children: [
                  Checkbox(value: step.done, onChanged: (v) => controller.setDone(step, v ?? false)),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final text = await _ask(context, title: 'Edit step', initial: step.text);
                        if (text != null && text.isNotEmpty && text != step.text) {
                          await controller.renameStep(step, text);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          step.text,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            decoration: step.done ? TextDecoration.lineThrough : null,
                            color: step.done ? theme.colorScheme.onSurfaceVariant : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove step',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => controller.deleteStep(step),
                  ),
                ],
              ),
            TextButton.icon(
              onPressed: () async {
                final text = await _ask(context, title: 'New step');
                if (text != null && text.isNotEmpty) await controller.addStep(skill, text);
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add a step'),
            ),
          ],
        ),
      ),
    );
  }
}

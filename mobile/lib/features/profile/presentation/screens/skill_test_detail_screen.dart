import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../data/skill_test_repository.dart';
import '../../profile_paths.dart';
import '../widgets/test_category.dart';

/// Test presentation + rules, before starting the timer.
class SkillTestDetailScreen extends ConsumerWidget {
  const SkillTestDetailScreen({super.key, required this.testId});

  final int testId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionCount = ref.watch(testQuestionsProvider(testId)).value?.length;
    final test = ref.watch(skillTestProvider(testId));
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Skill test')),
      body: AsyncValueView(
        value: test,
        onRetry: () => ref.invalidate(skillTestProvider(testId)),
        data: (test) {
          final (icon, color) = categoryStyle(test.category);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    children: [
                      IconBubble(icon: icon, color: color, size: 76, solid: true),
                      const SizedBox(height: 16),
                      Text(
                        test.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      PillTag(test.category ?? 'Other', color: color),
                      if (test.description?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 14),
                        Text(
                          test.description!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant, height: 1.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.help_outline,
                      color: AppAccent.blue,
                      value: questionCount?.toString() ?? '…',
                      label: 'Questions',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      icon: Icons.timer_outlined,
                      color: AppAccent.orange,
                      value: '${test.durationMinutes} min',
                      label: 'Time limit',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      icon: Icons.flag_outlined,
                      color: AppAccent.green,
                      value: '${test.passScore}%',
                      label: 'To pass',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: colors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'The timer starts when you press Start. When time runs out, your answers are submitted '
                        'automatically. Pass to earn a certificate on your profile.',
                        style: theme.textTheme.bodySmall?.copyWith(color: colors.onPrimaryContainer, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: test.hasValue
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  onPressed: questionCount == null || questionCount == 0
                      ? null
                      : () => context.pushReplacement(ProfilePaths.takeTest(testId)),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(questionCount == 0 ? 'No questions yet' : 'Start the test'),
                ),
              ),
            )
          : null,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/ui_kit.dart';
import '../../data/models/skill_test.dart';

/// Shown after submitting a test. Receives the [Certification] via `extra`.
class TestResultScreen extends StatelessWidget {
  const TestResultScreen({super.key, required this.certification});

  final Certification? certification;

  @override
  Widget build(BuildContext context) {
    final c = certification;
    final theme = Theme.of(context);
    final color = c?.passed == true ? AppAccent.green : AppAccent.red;

    return Scaffold(
      appBar: AppBar(title: const Text('Result'), automaticallyImplyLeading: false),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: c == null
              ? const Text('No result to show.')
              : Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          dimension: 176,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: c.score / 100,
                                strokeWidth: 14,
                                strokeCap: StrokeCap.round,
                                color: color,
                                backgroundColor: color.withValues(alpha: 0.12),
                              ),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${c.score}%',
                                      style: theme.textTheme.displaySmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: color,
                                      ),
                                    ),
                                    Text('Your score', style: theme.textTheme.labelMedium),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        PillTag(
                          c.passed ? 'Passed' : 'Not passed',
                          icon: c.passed ? Icons.verified : Icons.close_rounded,
                          color: color,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          c.passed ? 'Congratulations!' : 'Not this time',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          c.passed
                              ? '"${c.testTitle}" now appears as a certificate on your profile.'
                              : 'Review the topic and try "${c.testTitle}" again.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(onPressed: () => context.pop(), child: const Text('Back to tests')),
        ),
      ),
    );
  }
}

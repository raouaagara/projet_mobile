import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/models/skill_test.dart';
import '../../data/skill_test_repository.dart';
import '../../profile_paths.dart';
import '../widgets/ai_test_sheet.dart';
import '../widgets/test_category.dart';

/// Available tests + my certifications.
class SkillTestsScreen extends ConsumerWidget {
  const SkillTestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Skill tests'),
          actions: [
            IconButton(
              tooltip: 'Generate a test with AI',
              icon: const Icon(Icons.auto_awesome),
              onPressed: () => showAiTestSheet(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tests'),
              Tab(text: 'My certifications'),
            ],
          ),
        ),
        body: const TabBarView(children: [_TestsTab(), _CertificationsTab()]),
      ),
    );
  }
}

class _TestsTab extends ConsumerStatefulWidget {
  const _TestsTab();

  @override
  ConsumerState<_TestsTab> createState() => _TestsTabState();
}

class _TestsTabState extends ConsumerState<_TestsTab> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authControllerProvider).value?.userId;
    if (userId == null) return const Center(child: CircularProgressIndicator());
    final passedTestIds = {
      for (final c in ref.watch(certificationsProvider(userId)).value ?? <Certification>[])
        if (c.passed && c.skillTestId != null) c.skillTestId!,
    };

    return AsyncValueView(
      value: ref.watch(skillTestsProvider),
      onRetry: () => ref.invalidate(skillTestsProvider),
      data: (tests) {
        if (tests.isEmpty) return const EmptyView(message: 'No test available right now.');
        final categories = {for (final t in tests) t.category ?? 'Other'}.toList()..sort();
        final visible = _category == null ? tests : tests.where((t) => (t.category ?? 'Other') == _category).toList();

        return RefreshIndicator(
          onRefresh: () => ref.refresh(skillTestsProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _category == null,
                      onSelected: (_) => setState(() => _category = null),
                    ),
                    for (final c in categories)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(c),
                          selected: _category == c,
                          onSelected: (_) => setState(() => _category = c),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final test in visible)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TestCard(test: test, passed: passedTestIds.contains(test.id)),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({required this.test, required this.passed});

  final SkillTest test;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = categoryStyle(test.category);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(ProfilePaths.test(test.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBubble(icon: icon, color: color, size: 48, solid: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            test.title,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (passed) const Icon(Icons.verified, color: AppAccent.green, size: 20),
                      ],
                    ),
                    Text(
                      test.category ?? 'Other',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    if (test.description?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 6),
                      Text(test.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        PillTag('${test.durationMinutes} min', icon: Icons.timer_outlined, color: AppAccent.blue),
                        PillTag('Pass ${test.passScore}%', icon: Icons.flag_outlined),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _CertificationsTab extends ConsumerWidget {
  const _CertificationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userId = ref.watch(authControllerProvider).value?.userId;
    if (userId == null) return const Center(child: CircularProgressIndicator());
    return AsyncValueView(
      value: ref.watch(certificationsProvider(userId)),
      onRetry: () => ref.invalidate(certificationsProvider(userId)),
      data: (certifications) => certifications.isEmpty
          ? const EmptyView(
              icon: Icons.workspace_premium_outlined,
              message: 'Pass a test to earn your first certification.',
            )
          : RefreshIndicator(
              onRefresh: () => ref.refresh(certificationsProvider(userId).future),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: certifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final c = certifications[i];
                  final color = c.passed ? AppAccent.green : AppAccent.red;
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                      leading: IconBubble(
                        icon: c.passed ? Icons.workspace_premium_outlined : Icons.close_rounded,
                        color: color,
                        size: 44,
                      ),
                      title: Text(
                        c.testTitle,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        [
                          if (c.category != null) c.category!,
                          if (c.completedAt != null) DateFormat.yMMMd().format(c.completedAt!),
                        ].join(' · '),
                      ),
                      trailing: PillTag('${c.score}%', color: color),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

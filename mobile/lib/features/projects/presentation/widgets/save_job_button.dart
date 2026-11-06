import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../project_providers.dart';

/// Bookmark toggle for a freelancer's saved jobs.
class SaveJobButton extends ConsumerWidget {
  const SaveJobButton({super.key, required this.projectId});

  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedJobsProvider).value?.contains(projectId) ?? false;
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: saved ? 'Remove from saved' : 'Save job',
      isSelected: saved,
      icon: const Icon(Icons.bookmark_border),
      selectedIcon: Icon(Icons.bookmark, color: Theme.of(context).colorScheme.primary),
      onPressed: () => ref.read(savedJobsProvider.notifier).toggle(projectId),
    );
  }
}

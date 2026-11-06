import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/project.dart';
import '../../data/models/project_enums.dart';
import '../project_providers.dart';

/// Like / love / haha / support buttons with their counts. One reaction per user.
class ReactionBar extends ConsumerStatefulWidget {
  const ReactionBar({super.key, required this.project});

  final Project project;

  @override
  ConsumerState<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends ConsumerState<ReactionBar> {
  bool _busy = false;

  Future<void> _react(ProjectReaction reaction) async {
    setState(() => _busy = true);
    try {
      await ref.read(myReactionsProvider.notifier).react(widget.project, reaction);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mine = ref.watch(myReactionsProvider).value?[widget.project.id];
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final reaction in ProjectReaction.values)
          FilterChip(
            showCheckmark: false,
            selected: mine == reaction,
            selectedColor: colors.primaryContainer,
            tooltip: reaction.label,
            label: Text('${reaction.emoji}  ${widget.project.reactions(reaction)}'),
            onSelected: _busy ? null : (_) => _react(reaction),
          ),
      ],
    );
  }
}

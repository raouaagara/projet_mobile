import 'package:flutter/material.dart';

import '../../data/models/cv_extraction.dart';

/// Explains what the AI found in the CV: each skill with the text that proves it.
Future<void> showCvScanResult(BuildContext context, CvExtraction result, {required int newCount}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, controller) => _CvScanResult(result: result, newCount: newCount, controller: controller),
    ),
  );
}

class _CvScanResult extends StatelessWidget {
  const _CvScanResult({required this.result, required this.newCount, required this.controller});

  final CvExtraction result;
  final int newCount;
  final ScrollController controller;

  static const _languages = {'fr': 'French', 'en': 'English'};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final language = _languages[result.language];

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Text(
          result.skills.isEmpty ? 'No skill found' : '${result.skills.length} skills found in your CV',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text([
          if (language != null) 'CV in $language',
          if (newCount > 0) '$newCount added to your selection',
          if (!result.semanticEnabled) 'basic keyword search (AI service unavailable)',
        ].join(' · ')),
        const SizedBox(height: 16),
        for (final skill in result.skills) _MatchTile(skill: skill),
        if (result.otherSkills.isNotEmpty) ...[
          const Divider(height: 32),
          Text('Also in your CV (not in our catalog yet)', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final s in result.otherSkills) Chip(label: Text(s))],
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
      ],
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.skill});

  final CvSkillMatch skill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(skill.name, style: theme.textTheme.titleSmall)),
              if (skill.foundByAi)
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(Icons.auto_awesome, size: 16, color: colors.primary),
                  label: const Text('by AI'),
                ),
              const SizedBox(width: 8),
              Text('${(skill.confidence * 100).round()}%'),
            ],
          ),
          if (skill.evidence.isNotEmpty)
            Text('“${skill.evidence}”',
                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: skill.confidence.clamp(0, 1).toDouble(),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }
}

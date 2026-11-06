import 'package:flutter/material.dart';

import '../../data/models/project_enums.dart';
import '../project_providers.dart';

/// Bottom sheet to filter the job feed. Returns the new filter, or null if dismissed.
Future<FeedFilter?> showFeedFilterSheet(BuildContext context, FeedFilter initial) {
  return showModalBottomSheet<FeedFilter>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _FeedFilterSheet(initial: initial),
  );
}

class _FeedFilterSheet extends StatefulWidget {
  const _FeedFilterSheet({required this.initial});

  final FeedFilter initial;

  @override
  State<_FeedFilterSheet> createState() => _FeedFilterSheetState();
}

class _FeedFilterSheetState extends State<_FeedFilterSheet> {
  late ProjectCategory? _category = widget.initial.category;
  late JobType? _jobType = widget.initial.jobType;
  late String? _experience = widget.initial.experience;
  late BudgetRange _budget = widget.initial.budget;

  FeedFilter get _result => FeedFilter(
    query: widget.initial.query,
    sort: widget.initial.sort,
    category: _category,
    jobType: _jobType,
    experience: _experience,
    budget: _budget,
  );

  Widget _section(String title, List<Widget> chips) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    ),
  );

  Widget _chip(String label, bool selected, VoidCallback onSelected) =>
      ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onSelected());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                children: [
                  Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _section('Category', [
                    _chip('Any', _category == null, () => setState(() => _category = null)),
                    for (final c in ProjectCategory.values)
                      _chip(c.label, _category == c, () => setState(() => _category = c)),
                  ]),
                  _section('Job type', [
                    _chip('Any', _jobType == null, () => setState(() => _jobType = null)),
                    for (final t in JobType.values) _chip(t.label, _jobType == t, () => setState(() => _jobType = t)),
                  ]),
                  _section('Experience level', [
                    _chip('Any', _experience == null, () => setState(() => _experience = null)),
                    for (final level in ExperienceLevel.values)
                      _chip(level, _experience == level, () => setState(() => _experience = level)),
                  ]),
                  _section('Budget', [
                    for (final range in BudgetRange.values)
                      _chip(range.label, _budget == range, () => setState(() => _budget = range)),
                  ]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      onPressed: () =>
                          Navigator.pop(context, FeedFilter(query: widget.initial.query, sort: widget.initial.sort)),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, _result),
                      child: const Text('Show jobs'),
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

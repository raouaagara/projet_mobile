import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/async_value_view.dart';
import '../../data/skill_catalog.dart';

/// Pick skills from the catalog. Returns the new selection, or null if dismissed.
Future<Set<int>?> showSkillPicker(BuildContext context, Set<int> selected) {
  return showModalBottomSheet<Set<int>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _SkillPicker(initial: selected),
  );
}

class _SkillPicker extends ConsumerStatefulWidget {
  const _SkillPicker({required this.initial});

  final Set<int> initial;

  @override
  ConsumerState<_SkillPicker> createState() => _SkillPickerState();
}

class _SkillPickerState extends ConsumerState<_SkillPicker> {
  late final Set<int> _selected = {...widget.initial};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(skillCatalogProvider);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: false,
                onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search skills',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: AsyncValueView(
                value: catalog,
                onRetry: () => ref.invalidate(skillCatalogProvider),
                data: (catalog) {
                  final skills = catalog.values
                      .where((s) => _query.isEmpty || s.name.toLowerCase().contains(_query))
                      .toList();
                  if (skills.isEmpty) return const EmptyView(message: 'No skill found.');
                  return ListView.builder(
                    itemCount: skills.length,
                    itemBuilder: (context, i) {
                      final skill = skills[i];
                      return CheckboxListTile(
                        value: _selected.contains(skill.id),
                        title: Text(skill.name),
                        subtitle: skill.category == null ? null : Text(skill.category!),
                        onChanged: (checked) =>
                            setState(() => checked! ? _selected.add(skill.id) : _selected.remove(skill.id)),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _selected),
                child: Text(
                  _selected.isEmpty ? 'No skill' : 'Use ${_selected.length} skill${_selected.length == 1 ? '' : 's'}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

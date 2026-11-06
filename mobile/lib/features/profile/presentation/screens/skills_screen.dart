import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_paths.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/competence_repository.dart';
import '../../data/models/competence.dart';
import '../../data/profile_repository.dart';
import '../widgets/cv_scan_result_sheet.dart';
import '../widgets/test_category.dart';

/// The freelancer's skills grouped by category, a CV scan by AI, and the catalog to add more
/// (design: Figma "Workify – My skills redesign"). In [onboarding] mode, saving leads to the job feed.
class SkillsScreen extends ConsumerStatefulWidget {
  const SkillsScreen({super.key, this.onboarding = false});

  final bool onboarding;

  @override
  ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends ConsumerState<SkillsScreen> {
  Set<int>? _saved; // on the profile; null until the user is loaded
  Set<int>? _selected;
  final _foundByAi = <int>{}; // by the last CV scan
  String _query = '';
  String? _category; // null: all categories
  ({List<int> bytes, String name})? _cv;
  bool _scanning = false;
  bool _saving = false;

  int get _userId => ref.read(authControllerProvider).value!.userId;

  @override
  void initState() {
    super.initState();
    // The catalog changes on the server (seeded, or skills added by a CV scan): never show an old copy.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(competenceCatalogProvider);
    });
  }

  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  void _toggle(int id) => setState(() => _selected!.contains(id) ? _selected!.remove(id) : _selected!.add(id));

  Future<void> _scanCv() async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['pdf']);
    if (file == null) return;
    setState(() => _scanning = true);
    try {
      final bytes = await file.xFile.readAsBytes();
      _cv = (bytes: bytes, name: file.name);
      final result = await ref.read(competenceRepositoryProvider).parseCv(bytes: bytes, fileName: file.name);
      final ids = [
        for (final s in result.skills)
          if (s.id != null) s.id!,
      ];
      final added = ids.where((id) => !_selected!.contains(id)).length;
      // The scan can add skills to the catalog: reload it so their names show up.
      ref.invalidate(competenceCatalogProvider);
      setState(() {
        _selected!.addAll(ids);
        _foundByAi
          ..clear()
          ..addAll(ids);
        _scanning = false;
      });
      if (mounted) await showCvScanResult(context, result, newCount: added);
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _save() async {
    if (_selected!.isEmpty) {
      _snack('Select at least one skill.');
      return;
    }
    setState(() => _saving = true);
    final repository = ref.read(profileRepositoryProvider);
    try {
      await repository.updateCompetences(_userId, _selected!.toList());
      if (_cv != null) {
        await repository.uploadCv(_userId, bytes: _cv!.bytes, fileName: _cv!.name);
      }
      setState(() {
        _saved = {..._selected!};
        _cv = null;
      });
      ref.invalidate(userByIdProvider(_userId));
      ref.invalidate(currentUserProvider);
      ref.invalidate(competenceCatalogProvider);
      if (!mounted) return;
      _snack(widget.onboarding ? 'Your profile is ready!' : 'Skills saved');
      widget.onboarding ? context.go(AppPaths.projects) : context.pop();
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authControllerProvider).value?.userId;
    if (userId == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final user = ref.watch(userByIdProvider(userId));
    final catalog = ref.watch(competenceCatalogProvider);
    if (_selected == null && user.hasValue) {
      _saved = user.value!.competenceIds.toSet();
      _selected = {..._saved!};
    }
    final ready = _selected != null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.onboarding ? 'Your skills' : 'My skills')),
      body: AsyncValueView(
        value: catalog,
        onRetry: () => ref.invalidate(competenceCatalogProvider),
        data: (all) => ready ? _buildContent(all) : const Center(child: CircularProgressIndicator()),
      ),
      bottomNavigationBar: ready
          ? _SaveBar(
              added: _selected!.difference(_saved!).length,
              removed: _saved!.difference(_selected!).length,
              cvPending: _cv != null,
              total: _selected!.length,
              saving: _saving,
              onboarding: widget.onboarding,
              onSave: _save,
            )
          : null,
    );
  }

  Widget _buildContent(List<Competence> all) {
    final byId = {for (final c in all) c.id: c};
    final mine = [
      for (final id in _selected!)
        if (byId[id] != null) byId[id]!,
    ];
    final groups = <String, List<Competence>>{};
    for (final c in mine) {
      groups.putIfAbsent(_categoryOf(c), () => []).add(c);
    }
    for (final list in groups.values) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    final ordered = groups.entries.toList()
      ..sort((a, b) => a.value.length != b.value.length ? b.value.length - a.value.length : a.key.compareTo(b.key));
    final categories = {for (final c in all) _categoryOf(c)}.toList()..sort();
    final saved = _selected!.length == _saved!.length && _selected!.containsAll(_saved!);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (widget.onboarding) ...[const StepProgress(step: 2, total: 2), const SizedBox(height: 16)],
        _Summary(
          count: _selected!.length,
          categories: groups.length,
          foundByAi: _foundByAi.intersection(_selected!).length,
          saved: saved,
        ),
        const SizedBox(height: 12),
        _ScanCard(cvName: _cv?.name, scanning: _scanning, onScan: _scanning ? null : _scanCv),
        _SectionTitle('Your skills'),
        if (mine.isEmpty)
          Text(
            'No skill yet. Scan your CV above, or add skills below.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        for (final entry in ordered)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CategoryCard(
              name: entry.key,
              skills: entry.value,
              foundByAi: _foundByAi,
              onRemove: (c) => _toggle(c.id),
            ),
          ),
        _SectionTitle('Add skills'),
        SearchField(
          hintText: 'Search ${all.length} skills',
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        ),
        const SizedBox(height: 12),
        FilterPills<String?>(
          values: [null, ...categories],
          selected: _category,
          label: (c) => c ?? 'All',
          onSelected: (c) => setState(() => _category = c),
        ),
        const SizedBox(height: 12),
        _query.isEmpty && _category == null
            ? _Suggestions(all: all, selected: _selected!, myCategories: groups.keys.toSet(), onAdd: _toggle)
            : _Results(
                skills: [
                  for (final c in all)
                    if ((_category == null || _categoryOf(c) == _category) && c.name.toLowerCase().contains(_query)) c,
                ],
                selected: _selected!,
                onToggle: _toggle,
              ),
      ],
    );
  }
}

String _categoryOf(Competence c) => c.category?.trim().isNotEmpty == true ? c.category!.trim() : 'Other';

/// How many skills, set as type: the number large, the details muted under it.
class _Summary extends StatelessWidget {
  const _Summary({required this.count, required this.categories, required this.foundByAi, required this.saved});

  final int count;
  final int categories;
  final int foundByAi;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final details = [
      if (categories > 0) 'in $categories field${categories == 1 ? '' : 's'}',
      if (foundByAi > 0) '$foundByAi found in your CV by AI',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$count', style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800, height: 1)),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  saved ? 'skills on your profile' : 'skills selected',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(details.join(', '), style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
          ],
        ],
      ),
    );
  }
}

/// Purple card that scans a PDF CV with the AI.
class _ScanCard extends StatelessWidget {
  const _ScanCard({required this.cvName, required this.scanning, required this.onScan});

  final String? cvName;
  final bool scanning;
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppAccent.purple.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppAccent.purple.withValues(alpha: 0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onScan,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              scanning
                  ? const SizedBox.square(
                      dimension: 46,
                      child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2.5)),
                    )
                  : const IconBubble(icon: Icons.description_outlined, color: AppAccent.purple, size: 46, solid: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cvName == null ? 'Detect your skills with AI' : 'Update with your CV',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      scanning
                          ? 'Reading your CV…'
                          : cvName == null
                          ? 'Upload your CV (PDF, French or English)'
                          : '$cvName · uploaded when you save',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppAccent.purple, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      cvName == null ? 'Scan' : 'Rescan',
                      style: theme.textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 28, 2, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 19, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// One field of the user's skills: its name in a label column, the skills as removable chips beside it.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.name, required this.skills, required this.foundByAi, required this.onRemove});

  final String name;
  final List<Competence> skills;
  final Set<int> foundByAi;
  final ValueChanged<Competence> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (_, color) = categoryStyle(name, fallback: Icons.category_outlined);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Padding(
            padding: const EdgeInsets.only(top: 10, right: 8),
            child: Text(
              name,
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.25),
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final skill in skills)
                _SkillRow(
                  skill: skill,
                  color: color,
                  foundByAi: foundByAi.contains(skill.id),
                  onRemove: () => onRemove(skill),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One of my skills: the field color on its edge, a spark when the AI found it, and a remove button.
class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.skill, required this.color, required this.foundByAi, required this.onRemove});

  final Competence skill;
  final Color color;
  final bool foundByAi;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (foundByAi) ...[
            const Tooltip(
              message: 'Found in your CV by AI',
              child: Icon(Icons.auto_awesome, size: 13, color: AppAccent.purple),
            ),
            const SizedBox(width: 5),
          ],
          Text(skill.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(20),
            child: Tooltip(
              message: 'Remove ${skill.name}',
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 9, 10, 9),
                child: Icon(Icons.close, size: 15, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A catalog skill as a chip: tap to add it, or to remove it when it is already selected.
class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.skill, required this.selected, required this.onTap});

  final Competence skill;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: selected ? colors.primary : colors.surface,
      shape: StadiumBorder(side: BorderSide(color: selected ? colors.primary : colors.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? Icons.check : Icons.add, size: 16, color: selected ? colors.onPrimary : colors.primary),
              const SizedBox(width: 6),
              Text(
                skill.name,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? colors.onPrimary : colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Without a search: catalog skills from the categories the user already has (or the first ones to start with).
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.all, required this.selected, required this.myCategories, required this.onAdd});

  final List<Competence> all;
  final Set<int> selected;
  final Set<String> myCategories;
  final ValueChanged<int> onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final free = all.where((c) => !selected.contains(c.id));
    final related = free.where((c) => myCategories.contains(_categoryOf(c))).take(12).toList();
    final suggestions = related.isNotEmpty ? related : free.take(12).toList();
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 18, color: AppAccent.purple),
                const SizedBox(width: 8),
                Text('Suggested for you', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              related.isNotEmpty ? 'From the same categories as your skills' : 'Popular skills to start with',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final c in suggestions) _SkillChip(skill: c, selected: false, onTap: () => onAdd(c.id))],
            ),
          ],
        ),
      ),
    );
  }
}

/// Catalog skills matching the search and the category filter.
class _Results extends StatelessWidget {
  const _Results({required this.skills, required this.selected, required this.onToggle});

  final List<Competence> skills;
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (skills.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: EmptyView(icon: Icons.search_off, message: 'No skill matches your search.'),
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${skills.length} skill${skills.length == 1 ? '' : 's'}',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in skills)
                  _SkillChip(skill: c, selected: selected.contains(c.id), onTap: () => onToggle(c.id)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom bar: what is not saved yet, and the button to save it.
class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.added,
    required this.removed,
    required this.cvPending,
    required this.total,
    required this.saving,
    required this.onboarding,
    required this.onSave,
  });

  final int added;
  final int removed;
  final bool cvPending;
  final int total;
  final bool saving;
  final bool onboarding;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final changes = added + removed + (cvPending ? 1 : 0);
    final dirty = changes > 0;
    final detail = [
      if (added > 0) '+$added added',
      if (removed > 0) '−$removed removed',
      if (cvPending) 'CV to upload',
    ].join(' · ');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        dirty
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: AppAccent.amber, shape: BoxShape.circle),
                              )
                            : Icon(Icons.check_circle, size: 16, color: colors.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            dirty ? '$changes unsaved change${changes == 1 ? '' : 's'}' : 'All changes saved',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dirty ? detail : '$total skill${total == 1 ? '' : 's'} on your profile',
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                onPressed: saving ? null : (dirty || onboarding ? onSave : () => context.pop()),
                child: saving
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(onboarding ? 'Finish' : (dirty ? 'Save changes' : 'Done')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

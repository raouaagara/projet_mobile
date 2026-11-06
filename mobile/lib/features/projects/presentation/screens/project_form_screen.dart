import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/models/project.dart';
import '../../data/models/project_enums.dart';
import '../../data/project_repository.dart';
import '../../data/skill_catalog.dart';
import '../../project_paths.dart';
import '../project_providers.dart';
import '../widgets/category_style.dart';
import '../widgets/skill_picker_sheet.dart';

/// Post a project (client), or edit one when [projectId] is set.
class ProjectFormScreen extends ConsumerWidget {
  const ProjectFormScreen({super.key, this.projectId});

  final int? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).value;
    if (session == null || !session.isClient) {
      return Scaffold(
        appBar: AppBar(),
        body: const ErrorView(message: 'Only clients can post projects.'),
      );
    }
    if (projectId == null) return _ProjectForm(clientId: session.userId);

    final project = ref.watch(projectProvider(projectId!));
    if (project.value case final loaded?) {
      if (loaded.clientId != session.userId) {
        return Scaffold(
          appBar: AppBar(),
          body: const ErrorView(message: 'You can only edit your own projects.'),
        );
      }
      return _ProjectForm(clientId: session.userId, initial: loaded);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Edit project')),
      body: AsyncValueView(value: project, data: (_) => const SizedBox()),
    );
  }
}

class _ProjectForm extends ConsumerStatefulWidget {
  const _ProjectForm({required this.clientId, this.initial});

  final int clientId;
  final Project? initial;

  @override
  ConsumerState<_ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends ConsumerState<_ProjectForm> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _description = TextEditingController(text: widget.initial?.description);
  late final _budget = TextEditingController(
    text: widget.initial == null ? '' : widget.initial!.budget.toStringAsFixed(0),
  );
  final _idea = TextEditingController();
  late ProjectCategory _category = widget.initial?.category ?? ProjectCategory.webDevelopment;

  /// The default category isn't a choice: the AI isn't told about it until the client picks one.
  late bool _categoryChosen = widget.initial != null;
  late JobType _jobType = widget.initial?.jobType ?? JobType.fixedPrice;
  late String _experience = ExperienceLevel.values.contains(widget.initial?.experienceLevel)
      ? widget.initial!.experienceLevel!
      : ExperienceLevel.intermediate;
  late Set<int> _skills = {...?widget.initial?.requiredCompetenceIds};

  /// Data URI; '' when the user removed the image.
  late String? _image = widget.initial?.image;
  bool _saving = false;
  bool _writing = false;

  bool get _editing => widget.initial != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _budget.dispose();
    _idea.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 75,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final mimeType = file.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
    setState(() => _image = toDataUri(bytes, mimeType: mimeType));
  }

  Future<void> _pickSkills() async {
    final skills = await showSkillPicker(context, _skills);
    if (skills != null) setState(() => _skills = skills);
  }

  /// The AI writes the title, description and level from [idea], and adds the skills it finds.
  Future<void> _writeWithAi(String idea) async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    if (idea.trim().length + _title.text.trim().length < 10) {
      messenger.showSnackBar(const SnackBar(content: Text('Write a few words about your project first.')));
      return;
    }
    final before = (title: _title.text, description: _description.text, experience: _experience, skills: _skills);
    setState(() => _writing = true);
    try {
      final draft = await ref
          .read(projectRepositoryProvider)
          .draftProject(
            idea: idea.trim(),
            title: _title.text.trim(),
            category: _categoryChosen ? _category : null,
            jobType: _jobType,
          );
      if (!mounted) return;
      final added = draft.skillIds.where((id) => !_skills.contains(id)).length;
      setState(() {
        if (draft.title.isNotEmpty) _title.text = draft.title;
        _description.text = draft.description;
        if (ExperienceLevel.values.contains(draft.experienceLevel)) _experience = draft.experienceLevel!;
        _skills = {..._skills, ...draft.skillIds};
      });
      final skills = added == 0 ? '' : ' and added $added skill${added == 1 ? '' : 's'}';
      messenger.showSnackBar(
        SnackBar(
          content: Text('The AI wrote your post$skills. Check it before publishing.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              if (!mounted) return;
              setState(() {
                _title.text = before.title;
                _description.text = before.description;
                _experience = before.experience;
                _skills = before.skills;
              });
            },
          ),
        ),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);

    final initial = widget.initial;
    final project = Project(
      id: initial?.id,
      title: _title.text.trim(),
      description: _description.text.trim(),
      // On edit, '' clears the image (null means "keep it" for the backend).
      image: _editing || (_image?.isNotEmpty ?? false) ? _image : null,
      experienceLevel: _experience,
      budget: double.parse(_budget.text.replaceAll(',', '.')),
      postedAt: initial?.postedAt ?? DateTime.now(),
      status: initial?.status ?? ProjectStatus.open,
      category: _category,
      jobType: _jobType,
      clientId: widget.clientId,
      requiredCompetenceIds: _skills.toList(),
    );
    final controller = ref.read(projectsControllerProvider.notifier);
    try {
      if (_editing) {
        await controller.save(project);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project updated.')));
        context.pop();
      } else {
        final created = await controller.create(project);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Project posted. Freelancers can now send proposals.')));
        context.pushReplacement(ProjectPaths.details(created.id!));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalog = ref.watch(skillCatalogProvider).value ?? {};
    final image = imageFromApi(_image);

    const gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit project' : 'Post a project')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (!_editing) ...[
              _AiWriterCard(idea: _idea, busy: _writing, onWrite: () => _writeWithAi(_idea.text)),
              const SizedBox(height: 12),
            ],
            SectionCard(
              title: 'The job',
              child: Column(
                children: [
                  LabeledField(
                    label: 'Title',
                    child: TextFormField(
                      controller: _title,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 100,
                      decoration: const InputDecoration(hintText: 'e.g. Flutter app for a restaurant'),
                      validator: (v) => (v ?? '').trim().length < 5 ? 'At least 5 characters' : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LabeledField(
                    label: 'Description',
                    child: TextFormField(
                      controller: _description,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 4,
                      maxLines: 10,
                      decoration: const InputDecoration(hintText: 'What needs to be done, deliverables, deadline...'),
                      validator: (v) =>
                          (v ?? '').trim().length < 20 ? 'Describe the job in at least 20 characters' : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AiButton(
                      label: 'Improve with AI',
                      busy: _writing,
                      onPressed: () => _writeWithAi(_description.text),
                    ),
                  ),
                  gap,
                  LabeledField(
                    label: 'Category',
                    child: DropdownButtonFormField<ProjectCategory>(
                      initialValue: _category,
                      items: [
                        for (final c in ProjectCategory.values)
                          DropdownMenuItem(
                            value: c,
                            child: Row(
                              children: [
                                IconBubble(icon: c.icon, color: categoryColor(c), size: 28, solid: true),
                                const SizedBox(width: 12),
                                Text(c.label),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (c) => setState(() {
                        _category = c!;
                        _categoryChosen = true;
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Payment',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<JobType>(
                    segments: [for (final t in JobType.values) ButtonSegment(value: t, label: Text(t.label))],
                    selected: {_jobType},
                    onSelectionChanged: (s) => setState(() => _jobType = s.first),
                  ),
                  gap,
                  LabeledField(
                    label: _jobType == JobType.hourly ? 'Hourly rate' : 'Budget',
                    child: TextFormField(
                      controller: _budget,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                      decoration: InputDecoration(
                        hintText: 'e.g. 500',
                        prefixText: r'$ ',
                        suffixText: _jobType == JobType.hourly ? '/ hour' : 'USD',
                      ),
                      validator: (v) {
                        final amount = double.tryParse((v ?? '').replaceAll(',', '.'));
                        return amount == null || amount <= 0 ? 'Enter an amount' : null;
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Experience level',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final level in ExperienceLevel.values)
                    ChoiceChip(
                      label: Text(level),
                      selected: _experience == level,
                      onSelected: (_) => setState(() => _experience = level),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Required skills',
              action: TextButton.icon(
                onPressed: _pickSkills,
                icon: const Icon(Icons.add, size: 18),
                label: Text(_skills.isEmpty ? 'Add' : 'Change'),
              ),
              child: _skills.isEmpty
                  ? Text(
                      'Optional — helps the right freelancers find your project.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final id in _skills)
                          InputChip(
                            label: Text(catalog[id]?.name ?? 'Skill #$id'),
                            onDeleted: () => setState(() => _skills = {..._skills}..remove(id)),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Cover image',
              child: image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 7,
                            child: Image(image: image, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton.filledTonal(
                              tooltip: 'Remove image',
                              onPressed: () => setState(() => _image = ''),
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ],
                      ),
                    )
                  : OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Add an image (optional)'),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_editing ? 'Save changes' : 'Publish project'),
          ),
        ),
      ),
    );
  }
}

/// Light purple card on a new project: a few words, and the AI writes the post.
class _AiWriterCard extends StatelessWidget {
  const _AiWriterCard({required this.idea, required this.busy, required this.onWrite});

  final TextEditingController idea;
  final bool busy;
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppAccent.purple.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppAccent.purple.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const IconBubble(icon: Icons.auto_awesome, color: AppAccent.purple, size: 40, solid: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Write your post with AI',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Say what you need in a few words: the AI writes the post and picks the skills.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: idea,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.surface,
              hintText: 'e.g. An app for my restaurant so customers can order and pay online',
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppAccent.purple, foregroundColor: Colors.white),
            onPressed: busy ? null : onWrite,
            icon: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.auto_awesome, size: 18),
            label: Text(busy ? 'Writing…' : 'Write my post'),
          ),
        ],
      ),
    );
  }
}

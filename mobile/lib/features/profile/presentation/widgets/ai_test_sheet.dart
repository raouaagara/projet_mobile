import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/ai_access.dart';
import '../../data/skill_test_repository.dart';
import '../../profile_paths.dart';
import 'premium_required.dart';

/// Bottom sheet: generate a new skill test with AI (Premium), then open it.
Future<void> showAiTestSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _AiTestSheet(),
    );

class _AiTestSheet extends ConsumerStatefulWidget {
  const _AiTestSheet();

  @override
  ConsumerState<_AiTestSheet> createState() => _AiTestSheetState();
}

class _AiTestSheetState extends ConsumerState<_AiTestSheet> {
  final _custom = TextEditingController();
  String? _category;
  bool _generating = false;

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final category = _custom.text.trim().isNotEmpty ? _custom.text.trim() : _category;
    if (category == null) return;
    setState(() => _generating = true);
    final session = ref.read(authControllerProvider).value!;
    final user = ref.read(currentUserProvider).value;
    try {
      final test = await ref.read(skillTestRepositoryProvider).generateAiTest(
            userId: session.userId,
            userName: user?.fullName ?? session.email,
            category: category,
          );
      ref.invalidate(skillTestsProvider);
      if (!mounted) return;
      Navigator.pop(context);
      context.push(ProfilePaths.test(test.id));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _generating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(aiAccessProvider);
    final categories = ref.watch(skillCategoriesProvider).value ?? const <String>[];
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: switch (access) {
        AsyncData(value: false) => const SizedBox(height: 360, child: PremiumRequired(feature: 'AI-generated tests')),
        AsyncData() => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Generate a test with AI', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              const Text('A new set of questions on the topic you choose.'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in categories)
                    ChoiceChip(
                      label: Text(c),
                      selected: _category == c && _custom.text.isEmpty,
                      onSelected: (_) => setState(() {
                        _category = c;
                        _custom.clear();
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _custom,
                decoration: const InputDecoration(labelText: 'Or another topic', hintText: 'e.g. Flutter, Docker, SEO'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _generating || (_category == null && _custom.text.trim().isEmpty) ? null : _generate,
                icon: _generating
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: Text(_generating ? 'Generating…' : 'Generate'),
              ),
            ],
          ),
        _ => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      },
    );
  }
}

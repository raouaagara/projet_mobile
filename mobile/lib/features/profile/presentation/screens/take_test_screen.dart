import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/models/skill_test.dart';
import '../../data/skill_test_repository.dart';
import '../../profile_paths.dart';

class TakeTestScreen extends ConsumerWidget {
  const TakeTestScreen({super.key, required this.testId});

  final int testId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final test = ref.watch(skillTestProvider(testId));
    final questions = ref.watch(testQuestionsProvider(testId));

    if (test.hasValue && questions.hasValue) {
      return _TestRunner(test: test.value!, questions: questions.value!);
    }
    final error = test.error ?? questions.error;
    return Scaffold(
      appBar: AppBar(),
      body: error != null
          ? ErrorView(
              message: ApiException.from(error).message,
              onRetry: () {
                ref.invalidate(skillTestProvider(testId));
                ref.invalidate(testQuestionsProvider(testId));
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _TestRunner extends ConsumerStatefulWidget {
  const _TestRunner({required this.test, required this.questions});

  final SkillTest test;
  final List<TestQuestion> questions;

  @override
  ConsumerState<_TestRunner> createState() => _TestRunnerState();
}

class _TestRunnerState extends ConsumerState<_TestRunner> {
  final Map<int, String> _answers = {};
  int _index = 0;
  late int _secondsLeft = widget.test.durationMinutes * 60;
  Timer? _timer;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) {
        _timer?.cancel();
        setState(() => _secondsLeft = 0);
        _submit(timeUp: true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _submit({bool timeUp = false}) async {
    if (_submitting) return;
    final unanswered = widget.questions.length - _answers.length;
    if (!timeUp && unanswered > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Submit now?'),
          content: Text('$unanswered question${unanswered == 1 ? ' is' : 's are'} not answered.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep going')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final session = ref.read(authControllerProvider).value;
    if (session == null) return; // logged out meanwhile: the router leaves this page
    setState(() => _submitting = true);
    _timer?.cancel();
    final user = ref.read(currentUserProvider).value;
    try {
      final certification = await ref
          .read(skillTestRepositoryProvider)
          .submit(
            userId: session.userId,
            testId: widget.test.id,
            userName: user?.fullName ?? session.email,
            answers: _answers,
          );
      ref.invalidate(certificationsProvider(session.userId));
      if (mounted) context.pushReplacement(ProfilePaths.testResult, extra: certification);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          action: SnackBarAction(label: 'Retry', onPressed: () => _submit(timeUp: true)),
        ),
      );
    }
  }

  Future<bool> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave the test?'),
        content: const Text('Your answers will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave')),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = widget.questions[_index];
    final isLast = _index == widget.questions.length - 1;
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    final lowTime = _secondsLeft <= 60;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _submitting) return;
        if (await _confirmLeave() && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.test.title),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: PillTag(
                '$minutes:$seconds',
                icon: Icons.timer_outlined,
                color: lowTime ? AppAccent.red : AppAccent.blue,
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                Text(
                  'Question ${_index + 1} of ${widget.questions.length}',
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                ),
                const Spacer(),
                Text('${_answers.length} answered', style: theme.textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_index + 1) / widget.questions.length,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  question.questionText,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final (letter, text) in question.options)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OptionCard(
                  letter: letter,
                  text: text,
                  selected: _answers[question.id] == letter,
                  onTap: _submitting ? null : () => setState(() => _answers[question.id] = letter),
                ),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_index > 0)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      onPressed: _submitting ? null : () => setState(() => _index--),
                      child: const Text('Previous'),
                    ),
                  ),
                if (_index > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting ? null : () => isLast ? _submit() : setState(() => _index++),
                    child: _submitting
                        ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(isLast ? 'Submit' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.letter, required this.text, required this.selected, this.onTap});

  final String letter;
  final String text;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: selected ? colors.primaryContainer.withValues(alpha: 0.45) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? colors.primary : colors.outlineVariant, width: selected ? 1.6 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: selected ? colors.primary : colors.surfaceContainerHighest,
                foregroundColor: selected ? colors.onPrimary : colors.onSurface,
                child: Text(letter),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(text)),
              if (selected) ...[const SizedBox(width: 8), Icon(Icons.check_circle, color: colors.primary)],
            ],
          ),
        ),
      ),
    );
  }
}

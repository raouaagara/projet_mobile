import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/app_user.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_paths.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/profile_repository.dart';
import '../../profile_paths.dart';
import '../widgets/ai_bio_button.dart';

/// Freelancer onboarding, step 1/2: about you. Step 2 is [SkillsScreen].
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authControllerProvider).value?.userId;
    if (userId == null) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your profile'),
        actions: [TextButton(onPressed: () => context.go(AppPaths.projects), child: const Text('Skip'))],
      ),
      body: AsyncValueView(
        value: ref.watch(userByIdProvider(userId)),
        onRetry: () => ref.invalidate(userByIdProvider(userId)),
        data: (user) => _AboutYouForm(user: user),
      ),
    );
  }
}

class _AboutYouForm extends ConsumerStatefulWidget {
  const _AboutYouForm({required this.user});

  final AppUser user;

  @override
  ConsumerState<_AboutYouForm> createState() => _AboutYouFormState();
}

class _AboutYouFormState extends ConsumerState<_AboutYouForm> {
  late final _bio = TextEditingController(text: widget.user.bio);
  late final _location = TextEditingController(text: widget.user.location);
  bool _saving = false;

  @override
  void dispose() {
    _bio.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(widget.user.id, {
        ...widget.user.toJson(),
        'bio': _bio.text.trim().isEmpty ? null : _bio.text.trim(),
        'location': _location.text.trim().isEmpty ? null : _location.text.trim(),
      });
      ref.invalidate(userByIdProvider(widget.user.id));
      if (mounted) context.pushReplacement('${ProfilePaths.skills}?onboarding=1');
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const StepProgress(step: 1, total: 2),
              const SizedBox(height: 20),
              Row(
                children: [
                  const IconBubble(icon: Icons.waving_hand_outlined, color: AppAccent.amber, size: 52, solid: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Hi ${widget.user.firstName}!',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Tell clients who you are. A complete profile gets more proposals accepted.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 24),
              LabeledField(
                label: 'About me',
                child: TextField(
                  controller: _bio,
                  minLines: 4,
                  maxLines: 6,
                  maxLength: 255,
                  decoration: const InputDecoration(hintText: 'Flutter developer with 3 years of experience in…'),
                ),
              ),
              AiBioButton(controller: _bio, user: widget.user),
              const SizedBox(height: 8),
              LabeledField(
                label: 'Location',
                child: TextField(
                  controller: _location,
                  decoration: const InputDecoration(hintText: 'Tunis, Tunisia', prefixIcon: Icon(Icons.place_outlined)),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton(
              onPressed: _saving ? null : _next,
              child: _saving
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Next: my skills'),
            ),
          ),
        ),
      ],
    );
  }
}

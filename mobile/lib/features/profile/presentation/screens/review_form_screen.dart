import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/user_role.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/models/review.dart';
import '../../data/profile_repository.dart';
import '../../data/review_repository.dart';
import '../widgets/rating_stars.dart';

/// Review about [targetUserId]: a client reviews a freelancer, a freelancer reviews a client.
/// Opened with `context.push(ProfilePaths.review(userId: ..., projectId: ...))`;
/// pops `true` when the review was published.
class ReviewFormScreen extends ConsumerStatefulWidget {
  const ReviewFormScreen({super.key, required this.targetUserId, this.projectId});

  final int targetUserId;
  final int? projectId;

  @override
  ConsumerState<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends ConsumerState<ReviewFormScreen> {
  final _text = TextEditingController();
  int _rating = 0;
  bool _enhancing = false;
  bool _sending = false;

  static const _labels = ['', 'Poor', 'Fair', 'Good', 'Very good', 'Excellent'];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _snack(String message, {SnackBarAction? action}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), action: action));

  Future<void> _enhance() async {
    if (_text.text.trim().length < 5 || _rating == 0) {
      _snack('Write a few words and pick a rating first.');
      return;
    }
    setState(() => _enhancing = true);
    final original = _text.text;
    try {
      final improved = await ref.read(reviewRepositoryProvider).enhance(original, _rating);
      _text.text = improved;
      _snack(
        'Text improved with AI',
        action: SnackBarAction(label: 'Undo', onPressed: () => _text.text = original),
      );
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _enhancing = false);
    }
  }

  Future<void> _submit() async {
    final text = _text.text.trim();
    final problem = _rating == 0
        ? 'Pick a rating.'
        : text.length < 5
        ? 'Your review must be at least 5 characters.'
        : null;
    if (problem != null) {
      _snack(problem);
      return;
    }

    final session = ref.read(authControllerProvider).value!;
    final iAmClient = session.role == UserRole.client;
    final me = '${session.userId}';
    final target = '${widget.targetUserId}';

    setState(() => _sending = true);
    try {
      await ref
          .read(reviewRepositoryProvider)
          .add(
            Review(
              description: text,
              rating: _rating,
              projectId: widget.projectId,
              clientId: iAmClient ? me : target,
              freelancerId: iAmClient ? target : me,
              reviewerRole: session.role.apiValue,
            ),
          );
      ref.invalidate(reviewsAboutProvider);
      ref.invalidate(allReviewsProvider);
      if (!mounted) return;
      _snack('Thanks, your review is published!');
      context.pop(true);
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = ref.watch(userByIdProvider(widget.targetUserId)).value;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Leave a review')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
              child: Column(
                children: [
                  UserAvatar(user: target, radius: 38),
                  const SizedBox(height: 12),
                  Text(
                    target == null ? 'How was your experience?' : 'How was working with ${target.firstName}?',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  RatingInput(value: _rating, onChanged: (v) => setState(() => _rating = v)),
                  const SizedBox(height: 8),
                  AnimatedOpacity(
                    opacity: _rating == 0 ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: PillTag(
                      _labels[_rating].isEmpty ? ' ' : _labels[_rating],
                      icon: Icons.star_rounded,
                      color: AppAccent.amber,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Your review',
            child: TextField(
              controller: _text,
              minLines: 5,
              maxLines: 10,
              maxLength: 5000,
              decoration: const InputDecoration(hintText: 'Communication, quality, deadlines…'),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppAccent.purple),
              onPressed: _enhancing ? null : _enhance,
              icon: _enhancing
                  ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome_outlined),
              label: const Text('Improve with AI'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 16, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Reviews are checked automatically for inappropriate language.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _sending ? null : _submit,
            child: _sending
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Publish review'),
          ),
        ),
      ),
    );
  }
}

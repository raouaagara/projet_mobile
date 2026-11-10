import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/app_user.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/theme/brand.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../messaging/messaging_paths.dart';
import '../../data/competence_repository.dart';
import '../../data/learning_tracker.dart';
import '../../data/models/competence.dart';
import '../../data/models/review.dart';
import '../../data/models/skill_test.dart';
import '../../data/profile_repository.dart';
import '../../data/review_repository.dart';
import '../../data/skill_test_repository.dart';
import '../../profile_paths.dart';
import '../widgets/profile_section.dart';
import '../widgets/rating_stars.dart';
import '../widgets/review_tile.dart';
import '../widgets/skills_to_learn.dart';
import '../widgets/test_category.dart';

/// My profile when [userId] is null, otherwise the public profile of [userId].
///
/// A storefront rather than a stack of cards: the cover runs edge to edge, the person's own words
/// (their bio) are the largest text after their name, and proof (rating, certificates, skills,
/// reviews) follows as plain sections on the page.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.userId});

  final int? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).value;
    final id = userId ?? session?.userId;
    if (id == null) return const Scaffold(body: ErrorView(message: 'Not logged in.'));
    final isMe = id == session?.userId;
    final userAsync = ref.watch(userByIdProvider(id));

    Future<void> refresh() async {
      ref.invalidate(userByIdProvider(id));
      ref.invalidate(reviewsAboutProvider);
      ref.invalidate(certificationsProvider(id));
      await ref.read(userByIdProvider(id).future);
    }

    final user = userAsync.value;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: AsyncValueView(
          value: userAsync,
          onRetry: () => ref.invalidate(userByIdProvider(id)),
          data: (_) => const SizedBox(),
        ),
      );
    }

    final freelancer = user.role == UserRole.freelancer;
    const between = SizedBox(height: 32);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Header(user: user, isMe: isMe),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isMe && freelancer && user.competenceIds.isEmpty) ...[const _CompleteProfileBanner(), between],
                  if (freelancer) ...[
                    _SkillsSection(user: user, isMe: isMe),
                    if (isMe && user.competenceIds.isNotEmpty) SkillsToLearnCard(user: user),
                    between,
                    _CertificationsSection(userId: user.id, isMe: isMe),
                    between,
                  ],
                  _ReviewsSection(user: user),
                  if (isMe) ...[between, _Shortcuts(freelancer: freelancer)],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A titled part of the page. No card: the spacing and the title carry the structure.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 19, fontWeight: FontWeight.w800),
                ),
              ),
              ?action,
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  const _Header({required this.user, required this.isMe});

  final AppUser user;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cover = imageFromApi(user.coverPictureUrl);
    final top = MediaQuery.paddingOf(context).top;
    final canPop = Navigator.of(context).canPop();
    final bio = user.bio?.trim() ?? '';
    final links = [
      if (user.website?.isNotEmpty ?? false) (Icons.language, 'Website', user.website!),
      if (user.linkedinUrl?.isNotEmpty ?? false) (Icons.business, 'LinkedIn', user.linkedinUrl!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              width: double.infinity,
              height: 150 + top,
              child: cover != null ? Image(image: cover, fit: BoxFit.cover) : const _GreenCover(),
            ),
            Positioned(
              top: top + 8,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  if (canPop) _RoundButton(icon: Icons.arrow_back, tooltip: 'Back', onPressed: () => context.pop()),
                  const Spacer(),
                  if (isMe)
                    _RoundButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit profile',
                      onPressed: () => context.push(ProfilePaths.edit),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              bottom: -44,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, shape: BoxShape.circle),
                child: UserAvatar(user: user, radius: 44),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.fullName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _Fact(
                    icon: user.role == UserRole.client ? Icons.business_center_outlined : Icons.laptop_mac_outlined,
                    text: user.role == UserRole.client ? 'Client' : 'Freelancer',
                  ),
                  if (user.location?.isNotEmpty ?? false) _Fact(icon: Icons.place_outlined, text: user.location!),
                  if (user.createdAt != null)
                    _Fact(icon: Icons.event_outlined, text: 'Joined in ${user.createdAt!.year}'),
                ],
              ),
              if (bio.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  bio,
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.45, color: colors.onSurface),
                ),
              ] else if (isMe) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => context.push(ProfilePaths.edit),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add a few words about you'),
                ),
              ],
              const SizedBox(height: 20),
              _Credentials(user: user),
              const SizedBox(height: 20),
              if (!isMe)
                FilledButton.icon(
                  onPressed: () => context.push(MessagingPaths.chatWith(user.id)),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text('Message ${user.firstName}'),
                ),
              if (links.isNotEmpty || user.cvFileName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 4,
                    children: [
                      for (final (icon, label, url) in links)
                        TextButton.icon(
                          onPressed: () => openExternalUrl(context, url),
                          icon: Icon(icon, size: 18),
                          label: Text(label),
                        ),
                      if (user.cvFileName != null)
                        TextButton.icon(
                          onPressed: () => openExternalUrl(
                            context,
                            ref.read(profileRepositoryProvider).cvDownloadUrl(user.cvFileName!),
                          ),
                          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                          label: const Text('View CV'),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Icon and short text, muted: role, place, year joined.
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: muted),
        const SizedBox(width: 5),
        Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
      ],
    );
  }
}

/// White round button over the cover, so it reads on any photo.
class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      icon: Icon(icon),
    );
  }
}

/// The brand green, when the user has no cover photo.
class _GreenCover extends StatelessWidget {
  const _GreenCover();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Brand.green, Theme.of(context).colorScheme.primary],
        ),
      ),
    );
  }
}

/// Rating and certificates as one line of proof, set in type rather than in tiles.
class _Credentials extends ConsumerWidget {
  const _Credentials({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final reviews = ref.watch(reviewsAboutProvider((userId: user.id, role: user.role))).value;
    final freelancer = user.role == UserRole.freelancer;
    final certificates = freelancer
        ? ref.watch(certificationsProvider(user.id)).value?.where((c) => c.passed).length
        : null;
    final big = theme.textTheme.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w800, height: 1);
    final small = theme.textTheme.bodySmall?.copyWith(color: muted);

    Widget figure(String value, Widget below) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: big),
        const SizedBox(height: 6),
        below,
      ],
    );

    final rated = reviews != null && reviews.isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        figure(
          reviews == null ? '…' : (rated ? averageRating(reviews).toStringAsFixed(1) : 'New'),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (rated) ...[RatingStars(rating: averageRating(reviews), size: 14), const SizedBox(width: 6)],
              Text(
                reviews == null
                    ? 'reviews'
                    : rated
                    ? '${reviews.length} review${reviews.length == 1 ? '' : 's'}'
                    : 'No reviews yet',
                style: small,
              ),
            ],
          ),
        ),
        const SizedBox(width: 36),
        if (freelancer)
          figure(
            certificates == null ? '…' : '$certificates',
            Text(certificates == 1 ? 'certificate' : 'certificates', style: small),
          ),
      ],
    );
  }
}

class _CompleteProfileBanner extends StatelessWidget {
  const _CompleteProfileBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Clients search by skill', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            'Add your skills and your CV so they can find you.',
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onPrimaryContainer),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.push(ProfilePaths.onboarding),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
            child: const Text('Add my skills'),
          ),
        ],
      ),
    );
  }
}

// ── Skills ─────────────────────────────────────────────────────────

/// Skills grouped by field, each field with its color.
class _SkillsSection extends ConsumerWidget {
  const _SkillsSection({required this.user, required this.isMe});

  final AppUser user;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final catalog = ref.watch(competenceCatalogProvider);
    return _Section(
      title: 'Skills',
      action: isMe ? TextButton(onPressed: () => context.push(ProfilePaths.skills), child: const Text('Edit')) : null,
      child: catalog.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => const Text('Could not load skills.'),
        data: (all) {
          final skills = all.where((c) => user.competenceIds.contains(c.id)).toList();
          if (skills.isEmpty) {
            return Text('No skills added yet.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant));
          }
          final byField = <String, List<Competence>>{};
          for (final s in skills) {
            (byField[s.category?.trim().isNotEmpty ?? false ? s.category!.trim() : 'Other'] ??= []).add(s);
          }
          final fields = byField.keys.toList()..sort((a, b) => byField[b]!.length.compareTo(byField[a]!.length));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final field in fields) ...[
                _FieldSkills(field: field, skills: byField[field]!),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FieldSkills extends StatelessWidget {
  const _FieldSkills({required this.field, required this.skills});

  final String field;
  final List<Competence> skills;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (_, color) = categoryStyle(field);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Padding(
            padding: const EdgeInsets.only(top: 9, right: 8),
            child: Text(
              field,
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.25),
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in skills)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border(left: BorderSide(color: color, width: 3)),
                  ),
                  child: Text(s.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Certificates ───────────────────────────────────────────────────

class _CertificationsSection extends ConsumerWidget {
  const _CertificationsSection({required this.userId, required this.isMe});

  final int userId;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final certifications = ref.watch(certificationsProvider(userId));
    return _Section(
      title: 'Certificates',
      action: isMe
          ? TextButton(onPressed: () => context.push(ProfilePaths.skillTests), child: const Text('Take a test'))
          : null,
      child: certifications.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => const Text('Could not load certificates.'),
        data: (all) {
          final passed = all.where((c) => c.passed).toList();
          if (passed.isEmpty) {
            return Text(
              isMe ? 'Pass a skill test to show a certificate here.' : 'No certificate yet.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            );
          }
          return SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: passed.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _Certificate(certification: passed[i]),
            ),
          );
        },
      ),
    );
  }
}

/// A certificate as a small seal: the score in a ring, then the test.
class _Certificate extends StatelessWidget {
  const _Certificate({required this.certification});

  final Certification certification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (_, color) = categoryStyle(certification.category, fallback: Icons.workspace_premium_outlined);
    return Container(
      width: 156,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, color: color, size: 26),
              const Spacer(),
              Text(
                '${certification.score}%',
                style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const Spacer(),
          Text(
            certification.testTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
          ),
          if (certification.category != null)
            Text(
              certification.category!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

// ── Reviews ────────────────────────────────────────────────────────

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reviews = ref.watch(reviewsAboutProvider((userId: user.id, role: user.role)));
    return _Section(
      title: 'Reviews',
      child: reviews.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => const Text('Could not load reviews.'),
        data: (list) {
          if (list.isEmpty) {
            return Text('No reviews yet.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RatingSummary(reviews: list),
              const SizedBox(height: 12),
              for (final review in list)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                  decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16)),
                  child: ReviewTile(review: review),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// One bar per number of stars, the average beside them.
class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.reviews});

  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final average = averageRating(reviews);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              average.toStringAsFixed(1),
              style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, height: 1),
            ),
            const SizedBox(height: 6),
            RatingStars(rating: average, size: 14),
          ],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: [
              for (var stars = 5; stars >= 1; stars--)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Row(
                    children: [
                      SizedBox(width: 12, child: Text('$stars', style: theme.textTheme.labelMedium)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: reviews.where((r) => r.rating == stars).length / reviews.length,
                            minHeight: 6,
                            color: AppAccent.amber,
                            backgroundColor: colors.surfaceContainerHigh,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── My shortcuts ───────────────────────────────────────────────────

class _Shortcuts extends ConsumerWidget {
  const _Shortcuts({required this.freelancer});

  final bool freelancer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracked = freelancer
        ? ref.watch(trackedSkillsProvider).value ?? const <TrackedSkill>[]
        : const <TrackedSkill>[];
    final steps = tracked.fold<int>(0, (n, t) => n + t.steps.length);
    final done = tracked.fold<int>(0, (n, t) => n + t.done);
    return Card(
      child: Column(
        children: [
          if (freelancer) ...[
            MenuTile(
              icon: Icons.school_outlined,
              color: AppAccent.blue,
              title: 'My learning',
              subtitle: tracked.isEmpty
                  ? 'Track the skills you learn, step by step'
                  : '${tracked.length} skill${tracked.length == 1 ? '' : 's'}, $done of $steps steps done',
              onTap: () => context.push(ProfilePaths.learning),
            ),
            const Divider(indent: 72, height: 1),
            MenuTile(
              icon: Icons.auto_awesome,
              color: AppAccent.purple,
              title: 'AI CV assistant',
              subtitle: 'Improve your CV for the jobs you want',
              onTap: () => context.push(ProfilePaths.cvAssistant),
            ),
            const Divider(indent: 72, height: 1),
          ],
          MenuTile(
            icon: Icons.emoji_events_outlined,
            color: AppAccent.orange,
            title: 'Top freelancers',
            subtitle: 'Leaderboard by client ratings',
            onTap: () => context.push(ProfilePaths.leaderboard),
          ),
        ],
      ),
    );
  }
}

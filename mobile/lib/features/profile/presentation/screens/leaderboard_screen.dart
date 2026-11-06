import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/brand.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../data/leaderboard.dart';
import '../../data/profile_repository.dart';
import '../../data/review_repository.dart';
import '../../profile_paths.dart';
import '../widgets/rating_stars.dart';

/// Freelancers ranked by client ratings: a podium for the top 3, then a grid.
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> refresh() async {
      ref.invalidate(allUsersProvider);
      ref.invalidate(allReviewsProvider);
      await ref.read(leaderboardProvider.future);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Top freelancers')),
      body: AsyncValueView(
        value: ref.watch(leaderboardProvider),
        onRetry: refresh,
        data: (entries) => entries.isEmpty
            ? const EmptyView(
                icon: Icons.emoji_events_outlined,
                message: 'No ratings yet. Freelancers appear here once clients review them.',
              )
            : RefreshIndicator(
                onRefresh: refresh,
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      sliver: SliverToBoxAdapter(child: _Podium(top: entries.take(3).toList())),
                    ),
                    if (entries.length > 3)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverGrid.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            mainAxisExtent: 196,
                          ),
                          itemCount: entries.length - 3,
                          itemBuilder: (context, i) => _EntryCard(rank: i + 4, entry: entries[i + 3]),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

const _medals = {1: Color(0xFFFFC107), 2: Color(0xFFB0BEC5), 3: Color(0xFFCD7F32)};

/// The first three on a green card: 2nd, 1st (bigger, with a crown), 3rd.
class _Podium extends StatelessWidget {
  const _Podium({required this.top});

  final List<LeaderboardEntry> top;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final order = [if (top.length > 1) 1, 0, if (top.length > 2) 2];
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Brand.green, primary]),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final i in order)
            Expanded(
              child: _PodiumPlace(rank: i + 1, entry: top[i]),
            ),
        ],
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  const _PodiumPlace({required this.rank, required this.entry});

  final int rank;
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = rank == 1;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push(ProfilePaths.user(entry.user.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (first) const Icon(Icons.workspace_premium, color: Color(0xFFFFD54F), size: 30),
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _medals[rank]),
                  child: UserAvatar(user: entry.user, radius: first ? 38 : 30),
                ),
                Positioned(
                  bottom: -10,
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _medals[rank]),
                    child: Text(
                      '$rank',
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              entry.user.fullName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFD54F)),
                const SizedBox(width: 2),
                Text(
                  entry.averageRating.toStringAsFixed(1),
                  style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// From the 4th on: a card like a seller card, with the rank.
class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.rank, required this.entry});

  final int rank;
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reviews = '${entry.reviewCount} review${entry.reviewCount == 1 ? '' : 's'}';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(ProfilePaths.user(entry.user.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Align(alignment: Alignment.topLeft, child: PillTag('#$rank')),
              UserAvatar(user: entry.user, radius: 32),
              const SizedBox(height: 10),
              Text(
                entry.user.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              RatingStars(rating: entry.averageRating, size: 14),
              const SizedBox(height: 2),
              Text(
                '${entry.averageRating.toStringAsFixed(1)} · $reviews',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

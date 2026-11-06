import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/user_role.dart';
import 'models/review.dart';
import 'profile_repository.dart';
import 'review_repository.dart';

class LeaderboardEntry {
  const LeaderboardEntry({required this.user, required this.averageRating, required this.reviewCount});

  final AppUser user;
  final double averageRating;
  final int reviewCount;
}

/// Freelancers ranked by average client rating, then by number of reviews.
/// Freelancers without reviews are not ranked.
final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final (users, reviews) = await (
    ref.watch(allUsersProvider.future),
    ref.watch(allReviewsProvider.future),
  ).wait;
  return buildLeaderboard(users, reviews);
});

List<LeaderboardEntry> buildLeaderboard(List<AppUser> users, List<Review> reviews) {
  final byFreelancer = <String, List<Review>>{};
  for (final review in reviews) {
    final id = review.freelancerId;
    if (id == null || review.reviewerRole == 'FREELANCER') continue;
    byFreelancer.putIfAbsent(id, () => []).add(review);
  }

  final entries = [
    for (final user in users)
      if (user.role == UserRole.freelancer && byFreelancer[user.id.toString()] != null)
        LeaderboardEntry(
          user: user,
          averageRating: averageRating(byFreelancer[user.id.toString()]!),
          reviewCount: byFreelancer[user.id.toString()]!.length,
        ),
  ];
  entries.sort((a, b) {
    final byRating = b.averageRating.compareTo(a.averageRating);
    return byRating != 0 ? byRating : b.reviewCount.compareTo(a.reviewCount);
  });
  return entries;
}

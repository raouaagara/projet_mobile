import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_paths.dart';
import '../../../../core/theme/brand.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../data/models/review.dart';
import '../../data/profile_repository.dart';
import 'rating_stars.dart';

/// One review with its author's name and avatar.
class ReviewTile extends ConsumerWidget {
  const ReviewTile({super.key, required this.review});

  final Review review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorId = review.authorId;
    final author = authorId == null ? null : ref.watch(userByIdProvider(authorId)).value;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: authorId == null ? null : () => context.push('${AppPaths.profile}/$authorId'),
            child: UserAvatar(user: author, radius: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(author?.fullName ?? '${Brand.name} user',
                          style: theme.textTheme.titleSmall, overflow: TextOverflow.ellipsis),
                    ),
                    if (review.createdAt != null)
                      Text(DateFormat.yMMMd().format(review.createdAt!),
                          style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 2),
                RatingStars(rating: review.rating.toDouble(), size: 16),
                const SizedBox(height: 4),
                Text(review.description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

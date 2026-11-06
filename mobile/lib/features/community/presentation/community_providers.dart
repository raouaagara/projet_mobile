import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/community_repository.dart';
import '../data/models/community_models.dart';

Future<int> _userId(Ref ref) async => (await ref.watch(authControllerProvider.future))!.userId;

// ── Groups ─────────────────────────────────────────────────────────

final groupsProvider = FutureProvider<List<CommunityGroup>>(
  (ref) => ref.watch(communityRepositoryProvider).fetchGroups(),
);

final groupProvider = FutureProvider.autoDispose.family<CommunityGroup, int>(
  (ref, id) => ref.watch(communityRepositoryProvider).fetchGroup(id),
);

final groupMembersProvider = FutureProvider.autoDispose.family<List<GroupMembership>, int>(
  (ref, id) => ref.watch(communityRepositoryProvider).fetchMembers(id),
);

/// The groups the user belongs to, with their role. Joining/leaving updates it.
final myMembershipsProvider = AsyncNotifierProvider<MyMembershipsController, List<GroupMembership>>(
  MyMembershipsController.new,
);

class MyMembershipsController extends AsyncNotifier<List<GroupMembership>> {
  CommunityRepository get _repository => ref.read(communityRepositoryProvider);

  @override
  Future<List<GroupMembership>> build() async {
    final session = await ref.watch(authControllerProvider.future);
    if (session == null) return [];
    return ref.watch(communityRepositoryProvider).fetchMemberships(session.userId);
  }

  GroupMembership? of(int groupId) => state.value?.where((m) => m.group?.id == groupId).firstOrNull;

  Future<void> join(int groupId) async {
    final membership = await _repository.join(groupId, userId: ref.read(authControllerProvider).value!.userId);
    state = AsyncData([...?state.value, membership]);
    ref.invalidate(groupMembersProvider(groupId));
  }

  Future<void> leave(GroupMembership membership) async {
    await _repository.removeMembership(membership.id);
    state = AsyncData([...?state.value?.where((m) => m.id != membership.id)]);
    if (membership.group != null) ref.invalidate(groupMembersProvider(membership.group!.id));
  }

  /// A new group: the user is its admin.
  Future<CommunityGroup> create({required String name, required String description, required GroupType type}) async {
    final group = await _repository.createGroup(
      name: name,
      description: description,
      type: type,
      creatorId: ref.read(authControllerProvider).value!.userId,
    );
    ref.invalidate(groupsProvider);
    ref.invalidateSelf();
    return group;
  }
}

// ── Feeds & posts ──────────────────────────────────────────────────

/// A group's or a club's feed.
typedef FeedKey = ({int? groupId, int? clubId});

final feedProvider = AsyncNotifierProvider.autoDispose.family<FeedController, List<FeedPost>, FeedKey>(
  FeedController.new,
);

class FeedController extends AsyncNotifier<List<FeedPost>> {
  FeedController(this.key);

  final FeedKey key;

  CommunityRepository get _repository => ref.read(communityRepositoryProvider);

  @override
  Future<List<FeedPost>> build() async {
    final userId = await _userId(ref);
    return ref.watch(communityRepositoryProvider).fetchFeed(groupId: key.groupId, clubId: key.clubId, userId: userId);
  }

  Future<void> publish(String content, {bool announcement = false}) async {
    final userId = ref.read(authControllerProvider).value!.userId;
    await _repository.createPost(
      authorId: userId,
      content: content,
      groupId: key.groupId,
      clubId: key.clubId,
      announcement: announcement,
    );
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(FeedPost post) async {
    await _repository.deletePost(post.id);
    state = AsyncData([...?state.value?.where((p) => p.id != post.id)]);
  }

  /// Picks [reaction], or removes it when it's already the user's. Shown at once; undone if it fails.
  Future<void> react(FeedPost post, ReactionKind reaction) async {
    final updated = post.withReaction(post.userReaction == reaction ? null : reaction);
    _replace(updated);
    try {
      await reactOnServer(_repository, ref.read(authControllerProvider).value!.userId, post, reaction);
    } on ApiException {
      _replace(post);
      rethrow;
    }
  }

  void _replace(FeedPost post) =>
      state = AsyncData([for (final p in state.value ?? <FeedPost>[]) p.id == post.id ? post : p]);
}

/// Same rule everywhere: tapping your current reaction removes it.
Future<void> reactOnServer(CommunityRepository repository, int userId, FeedPost post, ReactionKind reaction) =>
    post.userReaction == reaction
    ? repository.removeReaction(post.id, userId: userId)
    : repository.react(post.id, userId: userId, reaction: reaction);

/// One post and its comments.
final postDetailProvider = AsyncNotifierProvider.autoDispose
    .family<PostDetailController, (FeedPost, List<PostComment>), int>(PostDetailController.new);

class PostDetailController extends AsyncNotifier<(FeedPost, List<PostComment>)> {
  PostDetailController(this.postId);

  final int postId;

  CommunityRepository get _repository => ref.read(communityRepositoryProvider);
  int get _me => ref.read(authControllerProvider).value!.userId;

  @override
  Future<(FeedPost, List<PostComment>)> build() async {
    final userId = await _userId(ref);
    return ref.watch(communityRepositoryProvider).fetchPost(postId, userId: userId);
  }

  void _invalidateFeeds(FeedPost post) {
    if (post.groupId != null) ref.invalidate(feedProvider((groupId: post.groupId, clubId: null)));
    if (post.clubId != null) ref.invalidate(feedProvider((groupId: null, clubId: post.clubId)));
  }

  Future<void> comment(String content) async {
    final (post, comments) = state.requireValue;
    final added = await _repository.addComment(postId, userId: _me, content: content);
    state = AsyncData((post.withCommentsCount(post.commentsCount + 1), [...comments, added]));
    _invalidateFeeds(post);
  }

  Future<void> editComment(PostComment comment, String content) async {
    final (post, comments) = state.requireValue;
    final updated = await _repository.editComment(comment.id, content);
    state = AsyncData((post, [for (final c in comments) c.id == comment.id ? updated : c]));
  }

  Future<void> deleteComment(PostComment comment) async {
    final (post, comments) = state.requireValue;
    await _repository.deleteComment(comment.id);
    state = AsyncData((
      post.withCommentsCount(post.commentsCount - 1),
      comments.where((c) => c.id != comment.id).toList(),
    ));
    _invalidateFeeds(post);
  }

  Future<void> react(ReactionKind reaction) async {
    final (post, comments) = state.requireValue;
    state = AsyncData((post.withReaction(post.userReaction == reaction ? null : reaction), comments));
    try {
      await reactOnServer(_repository, _me, post, reaction);
      _invalidateFeeds(post);
    } on ApiException {
      state = AsyncData((post, comments));
      rethrow;
    }
  }
}

// ── Events & clubs ─────────────────────────────────────────────────

final eventsProvider = FutureProvider<List<CommunityEvent>>(
  (ref) => ref.watch(communityRepositoryProvider).fetchEvents(),
);

final eventProvider = FutureProvider.autoDispose.family<CommunityEvent, int>(
  (ref, id) => ref.watch(communityRepositoryProvider).fetchEvent(id),
);

final clubsProvider = FutureProvider<List<Club>>((ref) => ref.watch(communityRepositoryProvider).fetchClubs());

final clubProvider = FutureProvider.autoDispose.family<Club, int>(
  (ref, id) => ref.watch(communityRepositoryProvider).fetchClub(id),
);

// ── People ─────────────────────────────────────────────────────────

final communityUserProvider = FutureProvider.family<AppUser, int>(
  (ref, id) => ref.watch(authRepositoryProvider).fetchUser(id),
);

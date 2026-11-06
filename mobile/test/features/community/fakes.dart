import 'package:catchopp_mobile/core/models/app_user.dart';
import 'package:catchopp_mobile/core/models/user_role.dart';
import 'package:catchopp_mobile/core/network/api_exception.dart';
import 'package:catchopp_mobile/features/auth/domain/auth_session.dart';
import 'package:catchopp_mobile/features/auth/presentation/auth_controller.dart';
import 'package:catchopp_mobile/features/community/community_routes.dart';
import 'package:catchopp_mobile/features/community/data/community_repository.dart';
import 'package:catchopp_mobile/features/community/data/models/community_models.dart';
import 'package:catchopp_mobile/features/community/presentation/community_providers.dart';
import 'package:catchopp_mobile/features/profile/data/competence_repository.dart';
import 'package:catchopp_mobile/features/profile/data/models/competence.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const me = 7;
const flutterGroup = CommunityGroup(id: 1, name: 'Flutter devs', description: 'Tips and jobs', type: GroupType.public);
const designGroup = CommunityGroup(id: 2, name: 'Designers', description: 'UI/UX', type: GroupType.public);
const coreTeam = CommunityGroup(id: 3, name: 'Core team', type: GroupType.private);

/// In-memory CommunityMicroService.
class FakeCommunityRepository extends CommunityRepository {
  FakeCommunityRepository({List<GroupMembership>? memberships, List<CommunityEvent>? events, List<Club>? clubs})
      : memberships = memberships ?? [],
        events = events ?? [],
        clubs = clubs ?? [],
        super(Dio());

  final groups = [flutterGroup, designGroup, coreTeam];
  final List<GroupMembership> memberships;
  final List<CommunityEvent> events;
  final List<Club> clubs;
  final posts = <FeedPost>[];
  final comments = <int, List<PostComment>>{};
  final reactions = <(int, int), ReactionKind>{}; // (post, user) → reaction

  @override
  Future<List<CommunityGroup>> fetchGroups() async => [...groups];

  @override
  Future<CommunityGroup> fetchGroup(int id) async => groups.firstWhere((g) => g.id == id);

  @override
  Future<List<GroupMembership>> fetchMemberships(int userId) async => memberships.where((m) => m.userId == userId).toList();

  @override
  Future<List<GroupMembership>> fetchMembers(int groupId) async => memberships.where((m) => m.group?.id == groupId).toList();

  @override
  Future<GroupMembership> join(int groupId, {required int userId}) async {
    final group = groups.firstWhere((g) => g.id == groupId);
    if (!group.isPublic) throw const ApiException('This group is private: ask one of its admins to add you.', statusCode: 403);
    final membership = GroupMembership(id: 100 + memberships.length, userId: userId, group: group);
    memberships.add(membership);
    return membership;
  }

  @override
  Future<void> removeMembership(int membershipId) async => memberships.removeWhere((m) => m.id == membershipId);

  FeedPost _withCounts(FeedPost post, int userId) {
    final counts = <ReactionKind, int>{};
    for (final entry in reactions.entries.where((e) => e.key.$1 == post.id)) {
      counts[entry.value] = (counts[entry.value] ?? 0) + 1;
    }
    return FeedPost(
      id: post.id,
      content: post.content,
      authorId: post.authorId,
      groupId: post.groupId,
      groupName: post.groupName,
      clubId: post.clubId,
      clubName: post.clubName,
      isAnnouncement: post.isAnnouncement,
      createdAt: post.createdAt,
      reactionCounts: counts,
      commentsCount: comments[post.id]?.length ?? 0,
      userReaction: reactions[(post.id, userId)],
    );
  }

  @override
  Future<List<FeedPost>> fetchFeed({int? groupId, int? clubId, required int userId}) async => posts
      .where((p) => (groupId == null || p.groupId == groupId) && (clubId == null || p.clubId == clubId))
      .map((p) => _withCounts(p, userId))
      .toList()
      .reversed
      .toList();

  @override
  Future<(FeedPost, List<PostComment>)> fetchPost(int postId, {required int userId}) async =>
      (_withCounts(posts.firstWhere((p) => p.id == postId), userId), [...?comments[postId]]);

  /// Like the server's AI moderation: a scam is refused with its reason.
  @override
  Future<void> createPost({required int authorId, required String content, int? groupId, int? clubId, bool announcement = false}) async {
    if (content.contains('crypto')) {
      throw const ApiException('Keep payments on Workify: they are protected by escrow.', statusCode: 422);
    }
    if (groupId != null && !memberships.any((m) => m.group?.id == groupId && m.userId == authorId)) {
      throw const ApiException('Join the group to post in it.', statusCode: 403);
    }
    posts.add(FeedPost(
      id: posts.length + 1,
      content: content,
      authorId: authorId,
      groupId: groupId,
      clubId: clubId,
      isAnnouncement: announcement,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<void> deletePost(int postId) async => posts.removeWhere((p) => p.id == postId);

  String? draftWhere;

  @override
  Future<String> draftPost(String notes, {String? where}) async {
    draftWhere = where;
    return 'Hi everyone! Has anyone tried Riverpod 3 in a real app? I would love your tips.';
  }

  List<String>? recommendedFor;

  @override
  Future<List<CommunityPick>> recommend({required int userId, String? role, List<String> skills = const [], String? bio}) async {
    recommendedFor = skills;
    return const [
      CommunityPick(kind: 'GROUP', id: 1, name: 'Flutter devs', reason: 'Flutter is your main skill.'),
      CommunityPick(kind: 'EVENT', id: 4, name: 'Flutter meetup Tunis', reason: 'Meet other mobile developers.'),
    ];
  }

  @override
  Future<void> react(int postId, {required int userId, required ReactionKind reaction}) async =>
      reactions[(postId, userId)] = reaction;

  @override
  Future<void> removeReaction(int postId, {required int userId}) async => reactions.remove((postId, userId));

  @override
  Future<PostComment> addComment(int postId, {required int userId, required String content}) async {
    final comment = PostComment(id: 500 + (comments[postId]?.length ?? 0), content: content, authorId: userId, createdAt: DateTime.now());
    (comments[postId] ??= []).add(comment);
    return comment;
  }

  @override
  Future<void> deleteComment(int commentId) async {
    for (final list in comments.values) {
      list.removeWhere((c) => c.id == commentId);
    }
  }

  @override
  Future<List<CommunityEvent>> fetchEvents() async => [...events];

  @override
  Future<CommunityEvent> fetchEvent(int id) async => events.firstWhere((e) => e.id == id);

  @override
  Future<List<Club>> fetchClubs() async => [...clubs];

  @override
  Future<Club> fetchClub(int id) async => clubs.firstWhere((c) => c.id == id);
}

AppUser user(int id) => AppUser(
    id: id, firstName: id == me ? 'Sara' : 'Karim', lastName: 'B', email: 'u$id@mail.com',
    role: id == me ? UserRole.freelancer : UserRole.client);

extension on AppUser {
  AppUser copyWithSkills(List<int> ids) =>
      AppUser(id: id, firstName: firstName, lastName: lastName, email: email, role: role, competenceIds: ids);
}

class _LoggedIn extends AuthController {
  @override
  Future<AuthSession?> build() async =>
      AuthSession(token: 't', userId: me, email: 'sara@mail.com', role: UserRole.freelancer, expiresAt: DateTime(2100));
}

Future<void> pumpCommunityApp(WidgetTester tester, {required FakeCommunityRepository repository, String location = '/community'}) async {
  final router = GoRouter(initialLocation: location, routes: [communityTab, ...communityRoutes]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(_LoggedIn.new),
      communityRepositoryProvider.overrideWithValue(repository),
      communityUserProvider.overrideWith((ref, id) async => user(id)),
      currentUserProvider.overrideWith((ref) async => user(me).copyWithSkills(const [1])),
      competenceCatalogProvider.overrideWith((ref) async => const [Competence(id: 1, name: 'Flutter')]),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

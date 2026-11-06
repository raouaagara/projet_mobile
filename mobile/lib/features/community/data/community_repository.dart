import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import 'models/community_models.dart';

final communityRepositoryProvider = Provider((ref) => CommunityRepository(ref.watch(dioProvider)));

/// A group, club or event the AI picked for the user, and why.
class CommunityPick {
  const CommunityPick({required this.kind, required this.id, required this.name, this.reason = ''});

  /// GROUP, CLUB or EVENT.
  final String kind;
  final int id;
  final String name;
  final String reason;

  factory CommunityPick.fromJson(Map<String, dynamic> json) => CommunityPick(
    kind: json['kind'] as String? ?? '',
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
    reason: json['reason'] as String? ?? '',
  );
}

/// Groups, posts, comments, reactions, events and clubs (CommunityMicroService).
/// Every method throws [ApiException] on failure.
class CommunityRepository {
  CommunityRepository(this._dio);

  final Dio _dio;

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  List<T> _list<T>(Object? data, T Function(Map<String, dynamic>) fromJson) =>
      (data as List<dynamic>).map((e) => fromJson(e as Map<String, dynamic>)).toList();

  String? _dateTime(DateTime? value) => value?.toIso8601String().split('.').first;

  // ── Groups ───────────────────────────────────────────────────────

  Future<List<CommunityGroup>> fetchGroups() => _call(() async {
    final res = await _dio.get<List<dynamic>>('/api/groups');
    return _list(res.data, CommunityGroup.fromJson);
  });

  Future<CommunityGroup> fetchGroup(int id) => _call(() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/groups/$id');
    return CommunityGroup.fromJson(res.data!);
  });

  /// The creator becomes the group's first admin.
  Future<CommunityGroup> createGroup({
    required String name,
    required String description,
    required GroupType type,
    required int creatorId,
  }) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/groups',
      queryParameters: {'creatorId': creatorId},
      data: {'name': name, 'description': description, 'type': type == GroupType.private ? 'PRIVATE' : 'PUBLIC'},
    );
    return CommunityGroup.fromJson(res.data!);
  });

  /// Groups the user belongs to (with their role).
  Future<List<GroupMembership>> fetchMemberships(int userId) => _call(() async {
    final res = await _dio.get<List<dynamic>>('/api/group-members/user/$userId');
    return _list(res.data, GroupMembership.fromJson);
  });

  Future<List<GroupMembership>> fetchMembers(int groupId) => _call(() async {
    final res = await _dio.get<List<dynamic>>('/api/group-members/group/$groupId');
    return _list(res.data, GroupMembership.fromJson);
  });

  Future<GroupMembership> join(int groupId, {required int userId}) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/group-members/join',
      data: {'groupId': groupId, 'userId': userId},
    );
    return GroupMembership.fromJson(res.data!);
  });

  /// Leave a group, or (admins) remove someone.
  Future<void> removeMembership(int membershipId) => _call(() => _dio.delete<void>('/api/group-members/$membershipId'));

  // ── Posts ────────────────────────────────────────────────────────

  /// Posts of a group or a club, newest first, with counts and the user's reaction.
  Future<List<FeedPost>> fetchFeed({int? groupId, int? clubId, required int userId}) => _call(() async {
    final res = await _dio.get<List<dynamic>>(
      '/api/posts/feed',
      queryParameters: {'groupId': ?groupId, 'clubId': ?clubId, 'userId': userId},
    );
    return _list(res.data, FeedPost.fromFeedJson);
  });

  /// One post with its comments (oldest first).
  Future<(FeedPost, List<PostComment>)> fetchPost(int postId, {required int userId}) => _call(() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/posts/$postId');
    final comments =
        (res.data!['comments'] as List<dynamic>? ?? const [])
            .map((e) => PostComment.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
    return (FeedPost.fromPostJson(res.data!, userId: userId), comments);
  });

  Future<void> createPost({
    required int authorId,
    required String content,
    int? groupId,
    int? clubId,
    bool announcement = false,
  }) => _call(
    () => _dio.post<void>(
      '/api/posts',
      data: {
        'authorId': authorId,
        'content': content,
        'isAnnouncement': announcement,
        if (groupId != null) 'group': {'id': groupId},
        if (clubId != null) 'club': {'id': clubId},
      },
    ),
  );

  Future<void> deletePost(int postId) => _call(() => _dio.delete<void>('/api/posts/$postId'));

  // ── AI ───────────────────────────────────────────────────────────

  /// A post written by the AI from the user's [notes]; [where]: the group or club name.
  Future<String> draftPost(String notes, {String? where}) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>('/api/posts/ai/draft', data: {'idea': notes, 'where': ?where});
    return res.data!['text'] as String? ?? '';
  });

  /// Groups, clubs and upcoming events picked by the AI for this user.
  Future<List<CommunityPick>> recommend({
    required int userId,
    String? role,
    List<String> skills = const [],
    String? bio,
  }) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/groups/ai/recommend',
      data: {'userId': userId, 'role': ?role, 'skills': skills, 'bio': ?bio},
    );
    return [
      for (final p in res.data!['picks'] as List<dynamic>? ?? []) CommunityPick.fromJson(p as Map<String, dynamic>),
    ];
  });

  /// One reaction per user per post: sending another type replaces it.
  Future<void> react(int postId, {required int userId, required ReactionKind reaction}) => _call(
    () => _dio.post<void>('/api/reactions', data: {'postId': postId, 'authorId': userId, 'type': reaction.apiName}),
  );

  Future<void> removeReaction(int postId, {required int userId}) =>
      _call(() => _dio.delete<void>('/api/reactions/post/$postId/user/$userId'));

  // ── Comments ─────────────────────────────────────────────────────

  Future<PostComment> addComment(int postId, {required int userId, required String content}) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/comments',
      data: {'postId': postId, 'authorId': userId, 'content': content},
    );
    return PostComment.fromJson(res.data!);
  });

  Future<PostComment> editComment(int commentId, String content) => _call(() async {
    final res = await _dio.put<Map<String, dynamic>>('/api/comments/$commentId', data: {'content': content});
    return PostComment.fromJson(res.data!);
  });

  Future<void> deleteComment(int commentId) => _call(() => _dio.delete<void>('/api/comments/$commentId'));

  // ── Events ───────────────────────────────────────────────────────

  Future<List<CommunityEvent>> fetchEvents() => _call(() async {
    final res = await _dio.get<List<dynamic>>('/api/events');
    return _list(res.data, CommunityEvent.fromJson)
      ..sort((a, b) => (a.startDate ?? DateTime(9999)).compareTo(b.startDate ?? DateTime(9999)));
  });

  Future<CommunityEvent> fetchEvent(int id) => _call(() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/events/$id');
    return CommunityEvent.fromJson(res.data!);
  });

  /// Waits for an admin's approval before others see it.
  Future<CommunityEvent> createEvent({
    required int creatorId,
    required String title,
    required String description,
    required String location,
    required DateTime start,
    required DateTime end,
    int? groupId,
    int? clubId,
  }) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/events',
      data: {
        'creatorId': creatorId,
        'title': title,
        'description': description,
        'location': location,
        'startDate': _dateTime(start),
        'endDate': _dateTime(end),
        if (groupId != null) 'group': {'id': groupId},
        if (clubId != null) 'club': {'id': clubId},
      },
    );
    return CommunityEvent.fromJson(res.data!);
  });

  // ── Clubs ────────────────────────────────────────────────────────

  Future<List<Club>> fetchClubs() => _call(() async {
    final res = await _dio.get<List<dynamic>>('/api/clubs');
    return _list(res.data, Club.fromJson);
  });

  Future<Club> fetchClub(int id) => _call(() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/clubs/$id');
    return Club.fromJson(res.data!);
  });

  Future<List<Club>> searchClubs(String interest) => _call(() async {
    final res = await _dio.get<List<dynamic>>('/api/clubs/search', queryParameters: {'interest': interest});
    return _list(res.data, Club.fromJson);
  });

  Future<Club> saveClub(Club club) => _call(() async {
    final data = club.toJson();
    final res = club.id == 0
        ? await _dio.post<Map<String, dynamic>>('/api/clubs', data: data..remove('id'))
        : await _dio.put<Map<String, dynamic>>('/api/clubs/${club.id}', data: data);
    return Club.fromJson(res.data!);
  });

  Future<Club> setClubPaused(int clubId, {required bool paused}) => _call(() async {
    final res = await _dio.put<Map<String, dynamic>>('/api/clubs/$clubId/${paused ? 'pause' : 'unpause'}');
    return Club.fromJson(res.data!);
  });
}

import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/json_utils.dart';

part 'community_models.g.dart';

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum GroupType {
  public('Public'),
  private('Private'),
  inviteOnly('Invite only'),
  unknown('Group');

  const GroupType(this.label);

  final String label;
}

/// A group (CommunityMicroService `Group`): members post and meet in it.
@JsonSerializable(createToJson: false)
class CommunityGroup {
  const CommunityGroup({
    required this.id,
    required this.name,
    this.description,
    this.bannerUrl,
    this.type = GroupType.public,
  });

  final int id;
  @JsonKey(defaultValue: '')
  final String name;
  final String? description;
  final String? bannerUrl;
  @JsonKey(unknownEnumValue: GroupType.unknown)
  final GroupType type;

  bool get isPublic => type == GroupType.public;

  factory CommunityGroup.fromJson(Map<String, dynamic> json) => _$CommunityGroupFromJson(json);
}

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum MemberRole {
  admin('Admin'),
  moderator('Moderator'),
  member('Member'),
  unknown('Member');

  const MemberRole(this.label);

  final String label;
}

@JsonSerializable(createToJson: false)
class GroupMembership {
  const GroupMembership({
    required this.id,
    required this.userId,
    this.group,
    this.role = MemberRole.member,
    this.joinedAt,
  });

  final int id;
  final int userId;
  final CommunityGroup? group;
  @JsonKey(unknownEnumValue: MemberRole.unknown)
  final MemberRole role;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? joinedAt;

  factory GroupMembership.fromJson(Map<String, dynamic> json) => _$GroupMembershipFromJson(json);
}

/// Reactions on posts (ReactionType).
enum ReactionKind {
  like('LIKE', '👍'),
  love('LOVE', '❤️'),
  happy('HAPPY', '😄'),
  wow('WOW', '😮'),
  sad('SAD', '😢'),
  angry('ANGRY', '😠');

  const ReactionKind(this.apiName, this.emoji);

  final String apiName;
  final String emoji;

  static ReactionKind? fromApi(Object? value) => values.where((r) => r.apiName == value).firstOrNull;
}

/// A post as shown in a feed: content, counts and the user's own reaction.
/// Built from `GET /api/posts/feed` (flat) or from a `Post` entity (`GET /api/posts/{id}`).
class FeedPost {
  const FeedPost({
    required this.id,
    required this.content,
    this.authorId,
    this.isAnnouncement = false,
    this.createdAt,
    this.groupId,
    this.groupName,
    this.clubId,
    this.clubName,
    this.reactionCounts = const {},
    this.commentsCount = 0,
    this.userReaction,
  });

  final int id;
  final String content;
  final int? authorId;
  final bool isAnnouncement;
  final DateTime? createdAt;
  final int? groupId;
  final String? groupName;
  final int? clubId;
  final String? clubName;
  final Map<ReactionKind, int> reactionCounts;
  final int commentsCount;
  final ReactionKind? userReaction;

  int get totalReactions => reactionCounts.values.fold(0, (a, b) => a + b);

  /// Where it was posted.
  String? get placeName => groupName ?? clubName;

  factory FeedPost.fromFeedJson(Map<String, dynamic> json) {
    final counts = <ReactionKind, int>{};
    (json['reactionCounts'] as Map<String, dynamic>? ?? const {}).forEach((key, value) {
      final kind = ReactionKind.fromApi(key);
      if (kind != null && (value as num) > 0) counts[kind] = value.toInt();
    });
    return FeedPost(
      id: (json['id'] as num).toInt(),
      content: json['content'] as String? ?? '',
      authorId: (json['authorId'] as num?)?.toInt(),
      isAnnouncement: json['isAnnouncement'] == true,
      createdAt: parseApiDate(json['createdAt']),
      groupId: (json['groupId'] as num?)?.toInt(),
      groupName: json['groupName'] as String?,
      clubId: (json['clubId'] as num?)?.toInt(),
      clubName: json['clubName'] as String?,
      reactionCounts: counts,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      userReaction: ReactionKind.fromApi(json['userReaction']),
    );
  }

  /// From the `Post` entity, which embeds its group/club, comments and reactions.
  factory FeedPost.fromPostJson(Map<String, dynamic> json, {int? userId}) {
    final reactions = (json['reactions'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
    final counts = <ReactionKind, int>{};
    ReactionKind? mine;
    for (final reaction in reactions) {
      final kind = ReactionKind.fromApi(reaction['type']);
      if (kind == null) continue;
      counts[kind] = (counts[kind] ?? 0) + 1;
      if (userId != null && (reaction['authorId'] as num?)?.toInt() == userId) mine = kind;
    }
    final group = json['group'] as Map<String, dynamic>?;
    final club = json['club'] as Map<String, dynamic>?;
    return FeedPost(
      id: (json['id'] as num).toInt(),
      content: json['content'] as String? ?? '',
      authorId: (json['authorId'] as num?)?.toInt(),
      isAnnouncement: json['isAnnouncement'] == true,
      createdAt: parseApiDate(json['createdAt']),
      groupId: (group?['id'] as num?)?.toInt(),
      groupName: group?['name'] as String?,
      clubId: (club?['id'] as num?)?.toInt(),
      clubName: club?['name'] as String?,
      reactionCounts: counts,
      commentsCount: (json['comments'] as List<dynamic>? ?? const []).length,
      userReaction: mine,
    );
  }

  /// The same post after the user reacted (or removed their reaction) — shown before the server answers.
  FeedPost withReaction(ReactionKind? reaction) {
    final counts = {...reactionCounts};
    if (userReaction != null) {
      counts[userReaction!] = (counts[userReaction!] ?? 1) - 1;
      if (counts[userReaction!]! <= 0) counts.remove(userReaction);
    }
    if (reaction != null) counts[reaction] = (counts[reaction] ?? 0) + 1;
    return _copy(reactionCounts: counts, userReaction: reaction, clearReaction: reaction == null);
  }

  FeedPost withCommentsCount(int count) => _copy(commentsCount: count);

  FeedPost _copy({
    Map<ReactionKind, int>? reactionCounts,
    int? commentsCount,
    ReactionKind? userReaction,
    bool clearReaction = false,
  }) => FeedPost(
    id: id,
    content: content,
    authorId: authorId,
    isAnnouncement: isAnnouncement,
    createdAt: createdAt,
    groupId: groupId,
    groupName: groupName,
    clubId: clubId,
    clubName: clubName,
    reactionCounts: reactionCounts ?? this.reactionCounts,
    commentsCount: commentsCount ?? this.commentsCount,
    userReaction: clearReaction ? null : (userReaction ?? this.userReaction),
  );
}

@JsonSerializable(createToJson: false)
class PostComment {
  const PostComment({required this.id, required this.content, this.authorId, this.createdAt});

  final int id;
  @JsonKey(defaultValue: '')
  final String content;
  final int? authorId;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? createdAt;

  factory PostComment.fromJson(Map<String, dynamic> json) => _$PostCommentFromJson(json);
}

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum EventStatus {
  pending('Waiting for approval'),
  approved('Approved'),
  rejected('Not approved'),
  unknown('Unknown');

  const EventStatus(this.label);

  final String label;
}

/// An event of a group or a club. Members' events are shown to others once an admin approved them.
@JsonSerializable(createToJson: false)
class CommunityEvent {
  const CommunityEvent({
    required this.id,
    required this.title,
    this.description,
    this.location,
    this.startDate,
    this.endDate,
    this.group,
    this.club,
    this.creatorId,
    this.status = EventStatus.pending,
  });

  final int id;
  @JsonKey(defaultValue: '')
  final String title;
  final String? description;
  final String? location;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? startDate;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? endDate;
  final CommunityGroup? group;
  final Club? club;
  final int? creatorId;
  @JsonKey(unknownEnumValue: EventStatus.unknown)
  final EventStatus status;

  String? get hostName => group?.name ?? club?.name;

  bool isPast([DateTime? now]) => (endDate ?? startDate)?.isBefore(now ?? DateTime.now()) ?? false;

  factory CommunityEvent.fromJson(Map<String, dynamic> json) => _$CommunityEventFromJson(json);
}

/// A club around shared interests; its creator posts and organizes events.
@JsonSerializable(includeIfNull: false)
class Club {
  const Club({
    required this.id,
    required this.name,
    this.description,
    this.bannerUrl,
    this.interestsText,
    this.creatorId,
    this.createdAt,
    this.status = 'ACTIVE',
  });

  final int id;
  @JsonKey(defaultValue: '')
  final String name;
  final String? description;
  final String? bannerUrl;

  /// Comma-separated on the backend, e.g. "design,figma,ux".
  @JsonKey(name: 'interests')
  final String? interestsText;
  final int? creatorId;
  @JsonKey(fromJson: parseApiDate, includeToJson: false)
  final DateTime? createdAt;
  @JsonKey(defaultValue: 'ACTIVE')
  final String status;

  bool get isPaused => status == 'PAUSED';

  List<String> get interests =>
      (interestsText ?? '').split(',').map((i) => i.trim()).where((i) => i.isNotEmpty).toList();

  factory Club.fromJson(Map<String, dynamic> json) => _$ClubFromJson(json);
  Map<String, dynamic> toJson() => _$ClubToJson(this);
}

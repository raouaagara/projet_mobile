// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommunityGroup _$CommunityGroupFromJson(Map<String, dynamic> json) => CommunityGroup(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String? ?? '',
  description: json['description'] as String?,
  bannerUrl: json['bannerUrl'] as String?,
  type: $enumDecodeNullable(_$GroupTypeEnumMap, json['type'], unknownValue: GroupType.unknown) ?? GroupType.public,
);

const _$GroupTypeEnumMap = {
  GroupType.public: 'PUBLIC',
  GroupType.private: 'PRIVATE',
  GroupType.inviteOnly: 'INVITE_ONLY',
  GroupType.unknown: 'UNKNOWN',
};

GroupMembership _$GroupMembershipFromJson(Map<String, dynamic> json) => GroupMembership(
  id: (json['id'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  group: json['group'] == null ? null : CommunityGroup.fromJson(json['group'] as Map<String, dynamic>),
  role: $enumDecodeNullable(_$MemberRoleEnumMap, json['role'], unknownValue: MemberRole.unknown) ?? MemberRole.member,
  joinedAt: parseApiDate(json['joinedAt']),
);

const _$MemberRoleEnumMap = {
  MemberRole.admin: 'ADMIN',
  MemberRole.moderator: 'MODERATOR',
  MemberRole.member: 'MEMBER',
  MemberRole.unknown: 'UNKNOWN',
};

PostComment _$PostCommentFromJson(Map<String, dynamic> json) => PostComment(
  id: (json['id'] as num).toInt(),
  content: json['content'] as String? ?? '',
  authorId: (json['authorId'] as num?)?.toInt(),
  createdAt: parseApiDate(json['createdAt']),
);

CommunityEvent _$CommunityEventFromJson(Map<String, dynamic> json) => CommunityEvent(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String? ?? '',
  description: json['description'] as String?,
  location: json['location'] as String?,
  startDate: parseApiDate(json['startDate']),
  endDate: parseApiDate(json['endDate']),
  group: json['group'] == null ? null : CommunityGroup.fromJson(json['group'] as Map<String, dynamic>),
  club: json['club'] == null ? null : Club.fromJson(json['club'] as Map<String, dynamic>),
  creatorId: (json['creatorId'] as num?)?.toInt(),
  status:
      $enumDecodeNullable(_$EventStatusEnumMap, json['status'], unknownValue: EventStatus.unknown) ??
      EventStatus.pending,
);

const _$EventStatusEnumMap = {
  EventStatus.pending: 'PENDING',
  EventStatus.approved: 'APPROVED',
  EventStatus.rejected: 'REJECTED',
  EventStatus.unknown: 'UNKNOWN',
};

Club _$ClubFromJson(Map<String, dynamic> json) => Club(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String? ?? '',
  description: json['description'] as String?,
  bannerUrl: json['bannerUrl'] as String?,
  interestsText: json['interests'] as String?,
  creatorId: (json['creatorId'] as num?)?.toInt(),
  createdAt: parseApiDate(json['createdAt']),
  status: json['status'] as String? ?? 'ACTIVE',
);

Map<String, dynamic> _$ClubToJson(Club instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': ?instance.description,
  'bannerUrl': ?instance.bannerUrl,
  'interests': ?instance.interestsText,
  'creatorId': ?instance.creatorId,
  'status': instance.status,
};

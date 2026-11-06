// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppUser _$AppUserFromJson(Map<String, dynamic> json) => AppUser(
  id: (json['id'] as num).toInt(),
  firstName: json['firstName'] as String? ?? '',
  lastName: json['lastName'] as String? ?? '',
  email: json['email'] as String? ?? '',
  role: $enumDecode(
    _$UserRoleEnumMap,
    json['role'],
    unknownValue: UserRole.unknown,
  ),
  location: json['location'] as String?,
  bio: json['bio'] as String?,
  profilePictureUrl: json['profilePictureUrl'] as String?,
  coverPictureUrl: json['coverPictureUrl'] as String?,
  linkedinUrl: json['linkedinUrl'] as String?,
  website: json['website'] as String?,
  cvFileName: json['cvFileName'] as String?,
  competenceIds:
      (json['competenceIds'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      [],
  createdAt: parseApiDate(json['createdAt']),
);

Map<String, dynamic> _$AppUserToJson(AppUser instance) => <String, dynamic>{
  'id': instance.id,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'email': instance.email,
  'role': _$UserRoleEnumMap[instance.role]!,
  'location': instance.location,
  'bio': instance.bio,
  'profilePictureUrl': instance.profilePictureUrl,
  'coverPictureUrl': instance.coverPictureUrl,
  'linkedinUrl': instance.linkedinUrl,
  'website': instance.website,
  'cvFileName': instance.cvFileName,
  'competenceIds': instance.competenceIds,
};

const _$UserRoleEnumMap = {
  UserRole.client: 'CLIENT',
  UserRole.freelancer: 'FREELANCER',
  UserRole.admin: 'ADMIN',
  UserRole.unknown: 'unknown',
};

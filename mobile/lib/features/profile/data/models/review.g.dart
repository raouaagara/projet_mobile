// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Review _$ReviewFromJson(Map<String, dynamic> json) => Review(
  id: (json['id'] as num?)?.toInt(),
  description: json['description'] as String? ?? '',
  rating: (json['rating'] as num?)?.toInt() ?? 0,
  projectId: (json['projectId'] as num?)?.toInt(),
  clientId: _idToString(json['clientId']),
  freelancerId: _idToString(json['freelancerId']),
  reviewerRole: json['reviewerRole'] as String?,
  createdAt: parseApiDate(json['createdAt']),
);

Map<String, dynamic> _$ReviewToJson(Review instance) => <String, dynamic>{
  'id': ?instance.id,
  'description': instance.description,
  'rating': instance.rating,
  'projectId': ?instance.projectId,
  'clientId': ?instance.clientId,
  'freelancerId': ?instance.freelancerId,
  'reviewerRole': ?instance.reviewerRole,
};

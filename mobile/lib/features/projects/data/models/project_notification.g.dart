// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectNotification _$ProjectNotificationFromJson(Map<String, dynamic> json) => ProjectNotification(
  id: (json['id'] as num).toInt(),
  message: json['message'] as String? ?? '',
  read: _readFlag(json, 'read') as bool? ?? false,
  createdAt: parseApiDate(json['createdAt']),
  projectId: (json['projectId'] as num?)?.toInt(),
);

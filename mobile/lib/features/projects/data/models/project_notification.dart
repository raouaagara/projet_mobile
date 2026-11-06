import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/json_utils.dart';

part 'project_notification.g.dart';

/// "New proposal on your project", "Your proposal was accepted"...
/// (ProjectMicroService `Notification`).
@JsonSerializable(createToJson: false)
class ProjectNotification {
  const ProjectNotification({
    required this.id,
    required this.message,
    this.read = false,
    this.createdAt,
    this.projectId,
  });

  final int id;
  @JsonKey(defaultValue: '')
  final String message;
  @JsonKey(readValue: _readFlag)
  final bool read;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? createdAt;
  final int? projectId;

  ProjectNotification markedRead() =>
      ProjectNotification(id: id, message: message, read: true, createdAt: createdAt, projectId: projectId);

  factory ProjectNotification.fromJson(Map<String, dynamic> json) => _$ProjectNotificationFromJson(json);
}

// Jackson names the `isRead` field "read"; accept both.
Object? _readFlag(Map<dynamic, dynamic> json, String key) => json['read'] ?? json['isRead'];

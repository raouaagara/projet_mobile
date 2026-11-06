import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/json_utils.dart';

part 'support_models.g.dart';

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum TicketStatus {
  open('Open', Icons.mark_email_unread_outlined),
  inProgress('In progress', Icons.support_agent),
  pendingUser('Waiting for you', Icons.reply),
  resolved('Resolved', Icons.check_circle_outline),
  closed('Closed', Icons.lock_outline),
  escalated('Escalated', Icons.priority_high),
  unknown('Unknown', Icons.help_outline);

  const TicketStatus(this.label, this.icon);

  final String label;
  final IconData icon;

  bool get isDone => this == resolved || this == closed;
}

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum TicketPriority {
  low('Low'),
  medium('Medium'),
  high('High'),
  critical('Critical'),
  unknown('—');

  const TicketPriority(this.label);

  final String label;
}

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum TicketCategory {
  technicalIssue('Technical issue', Icons.build_outlined),
  paymentIssue('Payment', Icons.payments_outlined),
  accountIssue('Account', Icons.person_outline),
  contractDispute('Contract dispute', Icons.gavel_outlined),
  fraudReport('Fraud report', Icons.report_outlined),
  featureRequest('Feature request', Icons.lightbulb_outline),
  bugReport('Bug report', Icons.bug_report_outlined),
  other('Other', Icons.help_outline);

  const TicketCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// A support ticket (TechnicalSupportMS `Ticket`). Category, priority and department
/// are detected by the backend when not given.
@JsonSerializable(createToJson: false)
class Ticket {
  const Ticket({
    required this.id,
    required this.title,
    required this.description,
    this.userId,
    this.status = TicketStatus.open,
    this.priority,
    this.category,
    this.department,
    this.enhancedDescription,
    this.aiSummary,
    this.assignedToName,
    this.escalated = false,
    this.slaBreached = false,
    this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.slaDeadline,
  });

  final int id;
  final int? userId;
  @JsonKey(defaultValue: '')
  final String title;
  @JsonKey(defaultValue: '')
  final String description;
  @JsonKey(unknownEnumValue: TicketStatus.unknown)
  final TicketStatus status;
  @JsonKey(unknownEnumValue: TicketPriority.unknown)
  final TicketPriority? priority;
  @JsonKey(unknownEnumValue: TicketCategory.other)
  final TicketCategory? category;
  final String? department;
  final String? enhancedDescription;
  final String? aiSummary;
  final String? assignedToName;
  @JsonKey(defaultValue: false)
  final bool escalated;
  @JsonKey(defaultValue: false)
  final bool slaBreached;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? createdAt;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? updatedAt;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? resolvedAt;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? slaDeadline;

  factory Ticket.fromJson(Map<String, dynamic> json) => _$TicketFromJson(json);
}

/// A message in a ticket thread, from the user or from the support team.
@JsonSerializable(createToJson: false)
class TicketReply {
  const TicketReply({
    required this.id,
    required this.message,
    this.responderId,
    this.responderName,
    this.staff = false,
    this.createdAt,
  });

  final int id;
  @JsonKey(defaultValue: '')
  final String message;
  final int? responderId;
  final String? responderName;

  /// Jackson names the `isStaff` field "staff"; accept both.
  @JsonKey(readValue: _readStaff)
  final bool staff;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? createdAt;

  factory TicketReply.fromJson(Map<String, dynamic> json) => _$TicketReplyFromJson(json);
}

Object? _readStaff(Map<dynamic, dynamic> json, String key) => json['staff'] ?? json['isStaff'] ?? false;

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Ticket _$TicketFromJson(Map<String, dynamic> json) => Ticket(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String? ?? '',
  description: json['description'] as String? ?? '',
  userId: (json['userId'] as num?)?.toInt(),
  status:
      $enumDecodeNullable(_$TicketStatusEnumMap, json['status'], unknownValue: TicketStatus.unknown) ??
      TicketStatus.open,
  priority: $enumDecodeNullable(_$TicketPriorityEnumMap, json['priority'], unknownValue: TicketPriority.unknown),
  category: $enumDecodeNullable(_$TicketCategoryEnumMap, json['category'], unknownValue: TicketCategory.other),
  department: json['department'] as String?,
  enhancedDescription: json['enhancedDescription'] as String?,
  aiSummary: json['aiSummary'] as String?,
  assignedToName: json['assignedToName'] as String?,
  escalated: json['escalated'] as bool? ?? false,
  slaBreached: json['slaBreached'] as bool? ?? false,
  createdAt: parseApiDate(json['createdAt']),
  updatedAt: parseApiDate(json['updatedAt']),
  resolvedAt: parseApiDate(json['resolvedAt']),
  slaDeadline: parseApiDate(json['slaDeadline']),
);

const _$TicketStatusEnumMap = {
  TicketStatus.open: 'OPEN',
  TicketStatus.inProgress: 'IN_PROGRESS',
  TicketStatus.pendingUser: 'PENDING_USER',
  TicketStatus.resolved: 'RESOLVED',
  TicketStatus.closed: 'CLOSED',
  TicketStatus.escalated: 'ESCALATED',
  TicketStatus.unknown: 'UNKNOWN',
};

const _$TicketPriorityEnumMap = {
  TicketPriority.low: 'LOW',
  TicketPriority.medium: 'MEDIUM',
  TicketPriority.high: 'HIGH',
  TicketPriority.critical: 'CRITICAL',
  TicketPriority.unknown: 'UNKNOWN',
};

const _$TicketCategoryEnumMap = {
  TicketCategory.technicalIssue: 'TECHNICAL_ISSUE',
  TicketCategory.paymentIssue: 'PAYMENT_ISSUE',
  TicketCategory.accountIssue: 'ACCOUNT_ISSUE',
  TicketCategory.contractDispute: 'CONTRACT_DISPUTE',
  TicketCategory.fraudReport: 'FRAUD_REPORT',
  TicketCategory.featureRequest: 'FEATURE_REQUEST',
  TicketCategory.bugReport: 'BUG_REPORT',
  TicketCategory.other: 'OTHER',
};

TicketReply _$TicketReplyFromJson(Map<String, dynamic> json) => TicketReply(
  id: (json['id'] as num).toInt(),
  message: json['message'] as String? ?? '',
  responderId: (json['responderId'] as num?)?.toInt(),
  responderName: json['responderName'] as String?,
  staff: _readStaff(json, 'staff') as bool? ?? false,
  createdAt: parseApiDate(json['createdAt']),
);

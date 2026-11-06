// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Contract _$ContractFromJson(Map<String, dynamic> json) => Contract(
  id: (json['id'] as num).toInt(),
  projectTitle: json['projectTitle'] as String? ?? '',
  rate: (json['rate'] as num?)?.toDouble() ?? 0,
  projectId: (json['projectId'] as num?)?.toInt(),
  proposalId: (_readProposalId(json, 'proposalId') as num?)?.toInt(),
  freelancerId: (json['freelancerId'] as num?)?.toInt(),
  clientId: (json['clientId'] as num?)?.toInt(),
  freelancerName: json['freelancerName'] as String?,
  clientName: json['clientName'] as String?,
  startDate: parseApiDate(json['startDate']),
  deadline: parseApiDate(json['deadline']),
  status:
      $enumDecodeNullable(
        _$ContractStatusEnumMap,
        json['status'],
        unknownValue: ContractStatus.unknown,
      ) ??
      ContractStatus.sent,
  terms: json['terms'] as String?,
  clientSignature: json['clientSignature'] as String?,
  freelancerSignature: json['freelancerSignature'] as String?,
  createdAt: parseApiDate(json['createdAt']),
  jobType: _readJobType(json, 'jobType') as String?,
);

const _$ContractStatusEnumMap = {
  ContractStatus.draft: 'DRAFT',
  ContractStatus.sent: 'SENT',
  ContractStatus.active: 'ACTIVE',
  ContractStatus.closed: 'CLOSED',
  ContractStatus.rejected: 'REJECTED',
  ContractStatus.completed: 'COMPLETED',
  ContractStatus.cancelled: 'CANCELLED',
  ContractStatus.unknown: 'UNKNOWN',
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proposal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Proposal _$ProposalFromJson(Map<String, dynamic> json) => Proposal(
  id: (json['id'] as num?)?.toInt(),
  bidAmount: (json['bidAmount'] as num?)?.toDouble() ?? 0,
  estimationEndDate: parseApiDate(json['estimationEndDate']),
  status:
      $enumDecodeNullable(_$ProposalStatusEnumMap, json['status'], unknownValue: ProposalStatus.unknown) ??
      ProposalStatus.pending,
  freelancerId: (json['freelancerId'] as num?)?.toInt(),
  coverLetter: json['coverLetter'] as String?,
  project: json['project'] == null ? null : Project.fromJson(json['project'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ProposalToJson(Proposal instance) => <String, dynamic>{
  'id': ?instance.id,
  'bidAmount': instance.bidAmount,
  'estimationEndDate': ?formatApiDate(instance.estimationEndDate),
  'status': _$ProposalStatusEnumMap[instance.status]!,
  'freelancerId': ?instance.freelancerId,
  'coverLetter': ?instance.coverLetter,
};

const _$ProposalStatusEnumMap = {
  ProposalStatus.pending: 'PENDING',
  ProposalStatus.accepted: 'ACCEPTED',
  ProposalStatus.rejected: 'REJECTED',
  ProposalStatus.unknown: 'UNKNOWN',
};

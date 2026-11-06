import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/json_utils.dart';

part 'contract.g.dart';

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum ContractStatus {
  draft('Draft', Icons.edit_note),
  sent('Waiting for signature', Icons.draw_outlined),
  active('In progress', Icons.play_circle_outline),
  closed('Closed', Icons.lock_outline),
  rejected('Declined', Icons.cancel_outlined),
  completed('Completed', Icons.verified_outlined),
  cancelled('Cancelled', Icons.block),
  unknown('Unknown', Icons.help_outline);

  const ContractStatus(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// A contract between a client and a freelancer, made from an accepted proposal
/// (ProjectMicroService `Contract`). The client signs when sending it; the freelancer's
/// signature locks the payment in escrow.
@JsonSerializable(createToJson: false)
class Contract {
  const Contract({
    required this.id,
    required this.projectTitle,
    required this.rate,
    this.projectId,
    this.proposalId,
    this.freelancerId,
    this.clientId,
    this.freelancerName,
    this.clientName,
    this.startDate,
    this.deadline,
    this.status = ContractStatus.sent,
    this.terms,
    this.clientSignature,
    this.freelancerSignature,
    this.createdAt,
    this.jobType,
  });

  final int id;
  final int? projectId;

  /// The backend embeds the whole proposal; only its id is kept.
  @JsonKey(readValue: _readProposalId)
  final int? proposalId;
  final int? freelancerId;
  final int? clientId;
  @JsonKey(defaultValue: '')
  final String projectTitle;

  /// Set when the freelancer signs; before that, fetch the name from the user id.
  final String? freelancerName;
  final String? clientName;

  /// Amount locked in escrow when the freelancer signs (the accepted bid).
  @JsonKey(defaultValue: 0)
  final double rate;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? startDate;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? deadline;
  @JsonKey(unknownEnumValue: ContractStatus.unknown)
  final ContractStatus status;
  final String? terms;

  /// PNG data URIs drawn on the signature pads.
  final String? clientSignature;
  final String? freelancerSignature;
  @JsonKey(fromJson: parseApiDate)
  final DateTime? createdAt;

  /// `HOURLY` / `FIXED_PRICE`, read from the embedded project.
  @JsonKey(readValue: _readJobType)
  final String? jobType;

  bool get isHourly => jobType == 'HOURLY';

  /// The person on the other side of the contract.
  int? otherPartyOf(int userId) => userId == clientId ? freelancerId : clientId;

  int? get durationDays =>
      startDate == null || deadline == null ? null : deadline!.difference(startDate!).inDays;

  factory Contract.fromJson(Map<String, dynamic> json) => _$ContractFromJson(json);
}

Object? _readProposalId(Map<dynamic, dynamic> json, String key) =>
    json['proposalId'] ?? (json['proposal'] as Map?)?['id'];

Object? _readJobType(Map<dynamic, dynamic> json, String key) =>
    json['jobType'] ?? ((json['proposal'] as Map?)?['project'] as Map?)?['jobType'];

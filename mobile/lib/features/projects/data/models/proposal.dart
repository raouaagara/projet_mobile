import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/json_utils.dart';
import 'project.dart';
import 'project_enums.dart';

part 'proposal.g.dart';

/// A freelancer's bid on a project (ProjectMicroService `Proposal`).
/// The backend embeds the whole [project] when reading.
@JsonSerializable(includeIfNull: false)
class Proposal {
  const Proposal({
    this.id,
    required this.bidAmount,
    this.estimationEndDate,
    this.status = ProposalStatus.pending,
    this.freelancerId,
    this.coverLetter,
    this.project,
  });

  final int? id;
  @JsonKey(defaultValue: 0)
  final double bidAmount;
  @JsonKey(fromJson: parseApiDate, toJson: formatApiDate)
  final DateTime? estimationEndDate;
  @JsonKey(unknownEnumValue: ProposalStatus.unknown)
  final ProposalStatus status;
  final int? freelancerId;

  /// Optional letter to the client, written by the freelancer or with the AI.
  final String? coverLetter;
  @JsonKey(includeToJson: false)
  final Project? project;

  /// "$1,100", or "$22/h" on an hourly project.
  String get bidLabel => formatMoney(bidAmount) + (project?.jobType == JobType.hourly ? '/h' : '');

  Proposal copyWith({ProposalStatus? status}) => Proposal(
    id: id,
    bidAmount: bidAmount,
    estimationEndDate: estimationEndDate,
    status: status ?? this.status,
    freelancerId: freelancerId,
    coverLetter: coverLetter,
    project: project,
  );

  factory Proposal.fromJson(Map<String, dynamic> json) => _$ProposalFromJson(json);
  Map<String, dynamic> toJson() => _$ProposalToJson(this);
}

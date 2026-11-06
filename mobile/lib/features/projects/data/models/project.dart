import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/image_utils.dart';
import '../../../../core/utils/json_utils.dart';
import 'project_enums.dart';

part 'project.g.dart';

/// A job posted by a client (ProjectMicroService `Project`).
@JsonSerializable(includeIfNull: false)
class Project {
  Project({
    this.id,
    required this.title,
    required this.description,
    this.image,
    this.experienceLevel,
    required this.budget,
    this.postedAt,
    this.status = ProjectStatus.open,
    this.category,
    this.jobType,
    this.clientId,
    this.likes = 0,
    this.loves = 0,
    this.hahas = 0,
    this.supports = 0,
    this.requiredCompetenceIds = const [],
  });

  final int? id;
  @JsonKey(defaultValue: '')
  final String title;
  @JsonKey(defaultValue: '')
  final String description;

  /// Base64 data URI (what the web app sends) or http URL.
  final String? image;

  /// The backend's JSON key really starts with a capital E.
  @JsonKey(name: 'ExperienceLevel')
  final String? experienceLevel;
  @JsonKey(defaultValue: 0)
  final double budget;
  @JsonKey(fromJson: parseApiDate, toJson: formatApiDate)
  final DateTime? postedAt;
  @JsonKey(unknownEnumValue: ProjectStatus.unknown)
  final ProjectStatus status;
  @JsonKey(unknownEnumValue: ProjectCategory.other)
  final ProjectCategory? category;
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final JobType? jobType;
  final int? clientId;
  @JsonKey(includeToJson: false)
  final int likes;
  @JsonKey(includeToJson: false)
  final int loves;
  @JsonKey(includeToJson: false)
  final int hahas;
  @JsonKey(includeToJson: false)
  final int supports;
  final List<int> requiredCompetenceIds;

  /// Decoded once per project, so scrolling a list doesn't decode base64 again.
  @JsonKey(includeFromJson: false, includeToJson: false)
  late final ImageProvider? imageProvider = imageFromApi(image);

  bool get isOpen => status == ProjectStatus.open;

  int reactions(ProjectReaction reaction) => switch (reaction) {
    ProjectReaction.like => likes,
    ProjectReaction.love => loves,
    ProjectReaction.haha => hahas,
    ProjectReaction.support => supports,
  };

  int get totalReactions => likes + loves + hahas + supports;

  /// "$1,200" or "$35/h".
  String get budgetLabel => formatMoney(budget) + (jobType == JobType.hourly ? '/h' : '');

  Project copyWith({ProjectStatus? status}) => Project(
    id: id,
    title: title,
    description: description,
    image: image,
    experienceLevel: experienceLevel,
    budget: budget,
    postedAt: postedAt,
    status: status ?? this.status,
    category: category,
    jobType: jobType,
    clientId: clientId,
    likes: likes,
    loves: loves,
    hahas: hahas,
    supports: supports,
    requiredCompetenceIds: requiredCompetenceIds,
  );

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectToJson(this);
}

final _money = NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 0);

/// Amounts are in USD, like on the web app.
String formatMoney(num amount) => _money.format(amount);

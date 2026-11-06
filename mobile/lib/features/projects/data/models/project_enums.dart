import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

/// `Status` of a project in ProjectMicroService.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum ProjectStatus {
  open('Open', Icons.lock_open),
  active('In progress', Icons.play_circle_outline),
  closed('Closed', Icons.lock_outline),
  unknown('Unknown', Icons.help_outline);

  const ProjectStatus(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Statuses a client can pick.
  static const choices = [open, active, closed];
}

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum ProposalStatus {
  pending('Pending'),
  accepted('Accepted'),
  rejected('Declined'),
  unknown('Unknown');

  const ProposalStatus(this.label);

  final String label;
}

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum JobType {
  fixedPrice('Fixed price'),
  hourly('Hourly');

  const JobType(this.label);

  final String label;
}

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum ProjectCategory {
  webDevelopment('Web development', Icons.language),
  mobileDevelopment('Mobile development', Icons.phone_android),
  uiUxDesign('UI/UX design', Icons.brush_outlined),
  digitalMarketing('Digital marketing', Icons.campaign_outlined),
  dataScienceAi('Data science & AI', Icons.insights),
  writingTranslation('Writing & translation', Icons.translate),
  videoAnimation('Video & animation', Icons.movie_outlined),
  customerSupport('Customer support', Icons.support_agent),
  financeAccounting('Finance & accounting', Icons.account_balance_outlined),
  other('Other', Icons.category_outlined);

  const ProjectCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Reactions on a project, sent as `?type=LIKE`.
enum ProjectReaction {
  like('LIKE', '👍', 'Like'),
  love('LOVE', '❤️', 'Love'),
  haha('HAHA', '😂', 'Haha'),
  support('SUPPORT', '🙌', 'Support');

  const ProjectReaction(this.apiName, this.emoji, this.label);

  final String apiName;
  final String emoji;
  final String label;

  static ProjectReaction? fromApi(String? value) => values.where((r) => r.apiName == value).firstOrNull;
}

/// Free-text on the backend; these are the values the web app offers.
abstract final class ExperienceLevel {
  static const entry = 'Entry Level';
  static const intermediate = 'Intermediate';
  static const expert = 'Expert';
  static const values = [entry, intermediate, expert];
}

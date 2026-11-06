import 'package:flutter/material.dart';

import '../../../../shared/widgets/ui_kit.dart';
import '../../data/models/project_enums.dart';

/// The color of a project category, for its round icon.
Color categoryColor(ProjectCategory? category) => switch (category) {
  ProjectCategory.webDevelopment => AppAccent.blue,
  ProjectCategory.mobileDevelopment => AppAccent.green,
  ProjectCategory.uiUxDesign => AppAccent.pink,
  ProjectCategory.digitalMarketing => AppAccent.orange,
  ProjectCategory.dataScienceAi => AppAccent.purple,
  ProjectCategory.writingTranslation => AppAccent.cyan,
  ProjectCategory.videoAnimation => AppAccent.red,
  ProjectCategory.customerSupport => AppAccent.amber,
  ProjectCategory.financeAccounting => const Color(0xFF2E7D6B),
  _ => const Color(0xFF6E7A6B),
};

/// The color of a project status: open (green), in progress (blue), closed (grey).
Color statusColor(ProjectStatus status) => switch (status) {
  ProjectStatus.open => AppAccent.green,
  ProjectStatus.active => AppAccent.blue,
  _ => const Color(0xFF6E7A6B),
};

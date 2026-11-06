import 'package:flutter/material.dart';

import '../../../../shared/widgets/ui_kit.dart';
import '../../data/models/project_enums.dart';
import 'category_style.dart';

class ProjectStatusChip extends StatelessWidget {
  const ProjectStatusChip({super.key, required this.status});

  final ProjectStatus status;

  @override
  Widget build(BuildContext context) => PillTag(status.label, icon: status.icon, color: statusColor(status));
}

class ProposalStatusChip extends StatelessWidget {
  const ProposalStatusChip({super.key, required this.status});

  final ProposalStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      ProposalStatus.accepted => (AppAccent.green, Icons.check_circle_outline),
      ProposalStatus.rejected => (AppAccent.red, Icons.cancel_outlined),
      _ => (AppAccent.amber, Icons.hourglass_empty),
    };
    return PillTag(status.label, icon: icon, color: color);
  }
}

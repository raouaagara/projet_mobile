import 'package:flutter/material.dart';

import '../../../../shared/widgets/ui_kit.dart';
import '../../data/models/contract.dart';
import 'contract_style.dart';

class ContractStatusChip extends StatelessWidget {
  const ContractStatusChip({super.key, required this.status, this.actionNeeded = false});

  final ContractStatus status;

  /// Highlights a contract waiting for this user (e.g. a freelancer who must sign).
  final bool actionNeeded;

  @override
  Widget build(BuildContext context) {
    if (!actionNeeded) return PillTag(status.label, icon: status.icon, color: contractStatusColor(status));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppAccent.orange, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.draw, size: 15, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            'Sign now',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

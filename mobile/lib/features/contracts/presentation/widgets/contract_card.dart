import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/ui_kit.dart';
import '../../data/models/contract.dart';
import '../contract_providers.dart';
import '../format.dart';
import 'contract_status_chip.dart';
import 'contract_style.dart';

/// A contract in a list: project, other party, dates, status and amount.
class ContractCard extends ConsumerWidget {
  const ContractCard({super.key, required this.contract, required this.viewerId, required this.onTap});

  final Contract contract;
  final int viewerId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final isClient = viewerId == contract.clientId;
    final actionNeeded = !isClient && contract.status == ContractStatus.sent;
    final otherId = contract.otherPartyOf(viewerId);
    final storedName = isClient ? contract.freelancerName : contract.clientName;
    final otherName =
        storedName ?? (otherId == null ? null : ref.watch(contractUserProvider(otherId)).value?.fullName) ?? '…';

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: actionNeeded
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppAccent.orange, width: 1.5),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBubble(icon: contract.status.icon, color: contractStatusColor(contract.status), size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contract.projectTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${isClient ? 'Freelancer' : 'Client'}: $otherName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                        ),
                        if (contract.startDate != null || contract.deadline != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.event_outlined, size: 15, color: muted),
                              const SizedBox(width: 4),
                              Text(
                                [
                                  contract.startDate,
                                  contract.deadline,
                                ].map((d) => d == null ? '?' : formatDay(d)).join(' – '),
                                style: theme.textTheme.labelMedium?.copyWith(color: muted),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
              Row(
                children: [
                  ContractStatusChip(status: contract.status, actionNeeded: actionNeeded),
                  const Spacer(),
                  Text(
                    formatMoney(contract.rate) + (contract.isHourly ? '/h' : ''),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

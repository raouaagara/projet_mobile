import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../contract_paths.dart';
import '../../data/models/payment_models.dart';
import '../contract_providers.dart';
import '../format.dart';

/// Disputes the user opened, or that were opened about their contracts.
class DisputesScreen extends ConsumerWidget {
  const DisputesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authControllerProvider).value?.userId;
    return Scaffold(
      appBar: AppBar(title: const Text('Disputes')),
      body: AsyncValueView(
        value: ref.watch(myDisputesProvider),
        onRetry: () => ref.invalidate(myDisputesProvider),
        data: (disputes) {
          final open = disputes.where((d) => d.status.isOpen).length;
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myDisputesProvider.future),
            child: disputes.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      EmptyView(
                        icon: Icons.handshake_outlined,
                        message: 'No dispute.\nIf a contract goes wrong, use "Report a problem" on it.',
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: StatTile(icon: Icons.gavel, color: AppAccent.red, value: '$open', label: 'Open'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatTile(
                              icon: Icons.check_rounded,
                              color: AppAccent.green,
                              value: '${disputes.length - open}',
                              label: 'Resolved',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const InfoBanner(
                        'While a dispute is open, the money stays in escrow. An admin reviews the case and '
                        'pays the freelancer, refunds the client, or splits the amount.',
                        icon: Icons.shield_outlined,
                      ),
                      const SizedBox(height: 12),
                      for (final dispute in disputes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DisputeCard(dispute: dispute, userId: userId),
                        ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _DisputeCard extends StatelessWidget {
  const _DisputeCard({required this.dispute, required this.userId});

  final Dispute dispute;
  final int? userId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final open = dispute.status.isOpen;
    final color = switch (dispute.status) {
      DisputeStatus.open => AppAccent.red,
      DisputeStatus.inReview => AppAccent.amber,
      _ => AppAccent.green,
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(ContractPaths.details(dispute.contractId)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBubble(icon: open ? Icons.gavel : Icons.check_rounded, color: color, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contract #${dispute.contractId}',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          [
                            dispute.raisedByUserId == userId ? 'You opened it' : 'Opened by the other party',
                            if (dispute.createdAt != null) formatDay(dispute.createdAt!),
                          ].join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                  PillTag(open ? dispute.status.label : 'Resolved', color: color),
                ],
              ),
              const SizedBox(height: 12),
              Text(dispute.reason, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.4)),
              if (!open) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 15, color: muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(dispute.status.label, style: theme.textTheme.labelMedium?.copyWith(color: muted)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

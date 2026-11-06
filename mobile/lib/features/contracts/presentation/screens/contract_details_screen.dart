import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../contract_paths.dart';
import '../../data/models/contract.dart';
import '../../data/models/payment_models.dart';
import '../contract_providers.dart';
import '../format.dart';
import '../widgets/contract_status_chip.dart';
import '../widgets/contract_style.dart';
import '../widgets/dispute_sheet.dart';
import '../widgets/module_link.dart';
import '../widgets/party_tile.dart';
import '../widgets/signature_pad.dart';

/// A contract for its client or freelancer: terms, signatures, escrow, and the next step.
class ContractDetailsScreen extends ConsumerWidget {
  const ContractDetailsScreen({super.key, required this.contractId});

  final int contractId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contract = ref.watch(contractProvider(contractId));
    final userId = ref.watch(authControllerProvider).value?.userId;
    if (contract.value case final loaded?) {
      if (userId != loaded.clientId && userId != loaded.freelancerId) {
        return Scaffold(
          appBar: AppBar(),
          body: const ErrorView(message: 'This contract is not yours.'),
        );
      }
      return _Details(contract: loaded, userId: userId!);
    }
    return Scaffold(
      appBar: AppBar(),
      body: AsyncValueView(
        value: contract,
        onRetry: () => ref.invalidate(myContractsProvider),
        data: (_) => const SizedBox(),
      ),
    );
  }
}

class _Details extends ConsumerWidget {
  const _Details({required this.contract, required this.userId});

  final Contract contract;
  final int userId;

  bool get _isClient => userId == contract.clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherId = contract.otherPartyOf(userId);
    final showPayment = contract.status == ContractStatus.active || contract.status == ContractStatus.completed;
    const gap = SizedBox(height: 12);

    return Scaffold(
      appBar: AppBar(
        title: Text('Contract #${contract.id}'),
        actions: [
          if (otherId != null)
            IconButton(
              tooltip: 'Message',
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => openModuleLink(
                context,
                LinkedPaths.chatWith(otherId),
                comingSoon: 'Chat arrives with module 4 (messaging).',
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          ref.refresh(myContractsProvider.future),
          ref.refresh(escrowProvider(contract.id).future),
          ref.refresh(myDisputesProvider.future),
        ]),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _Header(contract: contract, actionNeeded: !_isClient && contract.status == ContractStatus.sent),
            gap,
            _Facts(contract: contract),
            gap,
            SectionCard(
              title: 'Parties',
              child: Column(
                children: [
                  if (contract.clientId != null)
                    PartyTile(userId: contract.clientId!, role: 'Client', fallbackName: contract.clientName),
                  if (contract.freelancerId != null)
                    PartyTile(
                      userId: contract.freelancerId!,
                      role: 'Freelancer',
                      fallbackName: contract.freelancerName,
                    ),
                ],
              ),
            ),
            gap,
            SectionCard(
              title: 'Progress',
              child: _Timeline(contract: contract),
            ),
            if (showPayment) ...[
              gap,
              SectionCard(
                title: 'Payment',
                child: _Payment(contract: contract),
              ),
            ],
            gap,
            SectionCard(
              title: 'Terms',
              child: SelectableText(
                (contract.terms ?? '').trim().isEmpty ? 'No specific terms.' : contract.terms!.trim(),
                style: const TextStyle(height: 1.5),
              ),
            ),
            gap,
            SectionCard(
              title: 'Signatures',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SignatureImage(
                      label: 'Client',
                      dataUri: contract.clientSignature,
                      name: contract.clientName,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SignatureImage(
                      label: 'Freelancer',
                      dataUri: contract.freelancerSignature,
                      name: contract.freelancerName,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _Actions(contract: contract, userId: userId),
    );
  }
}

/// Status, project title, amount and a link to the project.
class _Header extends StatelessWidget {
  const _Header({required this.contract, required this.actionNeeded});

  final Contract contract;
  final bool actionNeeded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = contractStatusColor(contract.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBubble(icon: contract.status.icon, color: color, size: 48, solid: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    contract.isHourly ? 'Hourly contract' : 'Fixed-price contract',
                    style: theme.textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
                ContractStatusChip(status: contract.status, actionNeeded: actionNeeded),
              ],
            ),
            const SizedBox(height: 14),
            Text(contract.projectTitle, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              formatMoney(contract.rate) + (contract.isHourly ? ' / hour' : ''),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
            if (contract.projectId != null && contract.projectId != 0)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => openModuleLink(
                    context,
                    LinkedPaths.project(contract.projectId!),
                    comingSoon: 'Project pages arrive with module 2 (projects).',
                  ),
                  icon: const Icon(Icons.work_outline, size: 18),
                  label: const Text('View the project'),
                ),
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// The dates at a glance.
class _Facts extends StatelessWidget {
  const _Facts({required this.contract});

  final Contract contract;

  @override
  Widget build(BuildContext context) {
    final days = contract.durationDays;
    return Row(
      children: [
        Expanded(
          child: StatTile(
            icon: Icons.play_arrow_rounded,
            color: AppAccent.blue,
            value: contract.startDate == null ? '—' : formatDay(contract.startDate!),
            label: 'Start',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatTile(
            icon: Icons.flag_outlined,
            color: AppAccent.orange,
            value: contract.deadline == null ? '—' : formatDay(contract.deadline!),
            label: 'Deadline',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatTile(
            icon: Icons.timelapse,
            color: AppAccent.purple,
            value: days == null ? '—' : '$days day${days == 1 ? '' : 's'}',
            label: 'Duration',
          ),
        ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.contract});

  final Contract contract;

  @override
  Widget build(BuildContext context) {
    final status = contract.status;
    final signed = status == ContractStatus.active || status == ContractStatus.completed;
    final declined = status == ContractStatus.rejected || status == ContractStatus.cancelled;
    final steps = <(String, String?, bool, bool)>[
      // (title, detail, done, failed)
      ('Sent by the client', contract.createdAt == null ? null : formatDay(contract.createdAt!), true, false),
      (
        declined ? 'Declined by the freelancer' : 'Signed by the freelancer',
        signed ? 'The payment is locked in escrow' : null,
        signed,
        declined,
      ),
      (
        'Work done & paid',
        status == ContractStatus.completed ? 'The freelancer received the payment' : null,
        status == ContractStatus.completed,
        false,
      ),
    ];
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      children: [
        for (final (i, (title, detail, done, failed)) in steps.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    if (done || failed)
                      IconBubble(
                        icon: failed ? Icons.close_rounded : Icons.check_rounded,
                        color: failed ? AppAccent.red : AppAccent.green,
                        size: 28,
                        solid: true,
                      )
                    else
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.outlineVariant, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text('${i + 1}', style: theme.textTheme.labelMedium?.copyWith(color: colors.outline)),
                      ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          color: done ? AppAccent.green : colors.outlineVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: done || failed ? FontWeight.w700 : FontWeight.normal,
                            color: done || failed ? null : colors.outline,
                          ),
                        ),
                        if (detail != null)
                          Text(detail, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The escrow of the contract: what is paid, what is still held, and the dispute if any.
class _Payment extends ConsumerWidget {
  const _Payment({required this.contract});

  final Contract contract;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final escrow = ref.watch(escrowProvider(contract.id));
    final dispute = ref.watch(contractDisputeProvider(contract.id)).value;

    return escrow.when(
      loading: () => const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
      error: (e, _) => Text(ApiException.from(e).message),
      data: (escrow) {
        if (escrow == null) return const Text('No payment is locked for this contract.');
        final color = escrowStatusColor(escrow.status);
        Widget line(String label, double amount, {bool strong = false}) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Text(label, style: strong ? const TextStyle(fontWeight: FontWeight.w700) : null),
              const Spacer(),
              Text(
                formatMoney(amount),
                style: strong
                    ? TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)
                    : const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
        final paid = escrow.totalAmount <= 0 ? 0.0 : (escrow.releasedAmount / escrow.totalAmount).clamp(0.0, 1.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBubble(icon: escrow.status.icon, color: color, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    escrow.status.label,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: paid,
                minHeight: 8,
                color: AppAccent.green,
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
              ),
            ),
            const SizedBox(height: 4),
            line('Total', escrow.totalAmount),
            line('Paid to the freelancer', escrow.releasedAmount),
            line('Still in escrow', escrow.remainingAmount, strong: true),
            if (dispute != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppAccent.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const IconBubble(icon: Icons.gavel, color: AppAccent.red, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dispute: ${dispute.status.label}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            dispute.status.isOpen
                                ? 'The money stays in escrow until an admin decides.'
                                : dispute.reason,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// The next step for this user, at the bottom of the page.
class _Actions extends ConsumerStatefulWidget {
  const _Actions({required this.contract, required this.userId});

  final Contract contract;
  final int userId;

  @override
  ConsumerState<_Actions> createState() => _ActionsState();
}

class _ActionsState extends ConsumerState<_Actions> {
  bool _busy = false;

  Contract get _contract => widget.contract;
  bool get _isClient => widget.userId == _contract.clientId;

  Future<bool> _confirm(String title, String message, String action, {bool destructive = false}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              backgroundColor: destructive ? Theme.of(context).colorScheme.error : null,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  /// Runs [action] with a spinner; shows the error, if any. Returns whether it worked.
  Future<bool> _run(Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline() async {
    if (!await _confirm(
      'Decline this contract?',
      'The client will be notified. This cannot be undone.',
      'Decline',
      destructive: true,
    )) {
      return;
    }
    if (!mounted) return;
    await _run(() => ref.read(myContractsProvider.notifier).reject(_contract));
  }

  Future<void> _release() async {
    final amount = formatMoney(_contract.rate);
    if (!await _confirm(
      'Approve the work and pay?',
      '$amount goes from escrow to the freelancer and the contract is completed. This cannot be undone.',
      'Pay $amount',
    )) {
      return;
    }
    if (!mounted) return;
    // The page rebuilds when the contract completes: keep a context that stays.
    final navigator = Navigator.of(context);
    final ok = await _run(() => ref.read(myContractsProvider.notifier).release(_contract, clientId: widget.userId));
    if (ok && navigator.mounted) await _offerReview(navigator.context);
  }

  /// Next step after paying: module 1's review form about the freelancer.
  Future<void> _offerReview(BuildContext context) async {
    final review = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.celebration_outlined),
        title: const Text('Payment sent'),
        content: const Text('The contract is completed. How did it go? A review helps other clients.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Later')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave a review'),
          ),
        ],
      ),
    );
    if (review == true && context.mounted) _openReview(context);
  }

  void _openReview(BuildContext context) {
    final otherId = _contract.otherPartyOf(widget.userId);
    if (otherId == null) return;
    openModuleLink(
      context,
      LinkedPaths.review(userId: otherId, projectId: _contract.projectId),
      comingSoon: 'Reviews arrive with module 1 (profile).',
    );
  }

  Future<void> _dispute() async {
    final reason = await showDisputeSheet(
      context,
      contractId: _contract.id,
      role: _contract.clientId == widget.userId ? 'CLIENT' : 'FREELANCER',
    );
    if (reason == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _run(() => raiseDispute(ref, contractId: _contract.id, reason: reason));
    if (ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Dispute opened. The money stays in escrow until an admin decides.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _contract.status;
    final escrow = ref.watch(escrowProvider(_contract.id)).value;
    final dispute = ref.watch(contractDisputeProvider(_contract.id)).value;
    final disputeOpen = dispute?.status.isOpen ?? false;
    final escrowOpen = escrow != null && !escrow.status.isClosed && escrow.status != EscrowStatus.disputed;
    final error = Theme.of(context).colorScheme.error;
    final danger = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      foregroundColor: error,
      side: BorderSide(color: error.withValues(alpha: 0.5)),
    );

    final List<Widget> buttons;
    if (status == ContractStatus.sent && !_isClient) {
      buttons = [
        Expanded(
          child: OutlinedButton(style: danger, onPressed: _busy ? null : _decline, child: const Text('Decline')),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _busy ? null : () => context.push(ContractPaths.sign(_contract.id)),
            icon: const Icon(Icons.draw),
            label: const Text('Review & sign'),
          ),
        ),
      ];
    } else if (status == ContractStatus.sent) {
      buttons = [
        const Expanded(
          child: InfoBanner('Waiting for the freelancer to sign.', icon: Icons.hourglass_top, color: AppAccent.amber),
        ),
      ];
    } else if (status == ContractStatus.active && escrowOpen && !disputeOpen) {
      buttons = [
        Expanded(
          child: OutlinedButton(
            style: danger,
            onPressed: _busy ? null : _dispute,
            child: const Text('Report a problem'),
          ),
        ),
        if (_isClient) ...[
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _busy ? null : _release,
              icon: _busy
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.verified),
              label: const Text('Approve & pay'),
            ),
          ),
        ],
      ];
    } else if (status == ContractStatus.completed) {
      buttons = [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _openReview(context),
            icon: const Icon(Icons.star_outline),
            label: Text(_isClient ? 'Review the freelancer' : 'Review the client'),
          ),
        ),
      ];
    } else {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(children: buttons),
      ),
    );
  }
}

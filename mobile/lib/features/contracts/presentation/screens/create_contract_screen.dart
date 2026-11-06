import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../contract_paths.dart';
import '../../data/contract_repository.dart';
import '../contract_providers.dart';
import '../format.dart';
import '../widgets/party_tile.dart';
import '../widgets/signature_pad.dart';

/// What the form needs: the accepted proposal, and the contract if it already exists.
final _proposalForContractProvider = FutureProvider.autoDispose.family<(ProposalSummary, int?), int>((
  ref,
  proposalId,
) async {
  final repository = ref.watch(contractRepositoryProvider);
  final (proposal, existing) = await (
    repository.fetchProposal(proposalId),
    repository.fetchByProposal(proposalId),
  ).wait;
  return (proposal, existing?.id);
});

const _defaultTerms =
    '1. Scope of work\n'
    'The freelancer delivers the work described in the project and in their proposal.\n\n'
    '2. Payment\n'
    'The amount is locked in escrow when the freelancer signs, and paid to the freelancer '
    'when the client approves the work.\n\n'
    '3. Confidentiality\n'
    'Both parties keep the information shared during the project confidential.';

/// Client: turn an accepted proposal into a contract, sign it and send it to the freelancer.
/// Opened by module 2 after accepting a proposal: `/contracts/new/:proposalId`.
class CreateContractScreen extends ConsumerWidget {
  const CreateContractScreen({super.key, required this.proposalId});

  final int proposalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).value;
    final data = ref.watch(_proposalForContractProvider(proposalId));

    Widget page(Widget body) => Scaffold(
      appBar: AppBar(title: const Text('New contract')),
      body: body,
    );

    if (session == null || !session.isClient) return page(const ErrorView(message: 'Only clients create contracts.'));
    return data.when(
      loading: () => page(const Center(child: CircularProgressIndicator())),
      error: (e, _) => page(
        ErrorView(
          message: ApiException.from(e).message,
          onRetry: () => ref.invalidate(_proposalForContractProvider(proposalId)),
        ),
      ),
      data: (data) {
        final (proposal, existingId) = data;
        if (existingId != null) {
          return page(_AlreadyCreated(contractId: existingId));
        }
        if (!proposal.isAccepted) {
          return page(const ErrorView(message: 'Accept this proposal before creating its contract.'));
        }
        return _ContractForm(proposal: proposal, clientId: session.userId);
      },
    );
  }
}

class _AlreadyCreated extends StatelessWidget {
  const _AlreadyCreated({required this.contractId});

  final int contractId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBubble(icon: Icons.task_outlined, color: theme.colorScheme.primary, size: 88),
            const SizedBox(height: 20),
            Text(
              'The contract for this proposal was already sent.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.pushReplacement(ContractPaths.details(contractId)),
              child: const Text('Open the contract'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractForm extends ConsumerStatefulWidget {
  const _ContractForm({required this.proposal, required this.clientId});

  final ProposalSummary proposal;
  final int clientId;

  @override
  ConsumerState<_ContractForm> createState() => _ContractFormState();
}

class _ContractFormState extends ConsumerState<_ContractForm> {
  final _terms = TextEditingController(text: _defaultTerms);
  final _signature = SignaturePadController();
  final _signatureCard = GlobalKey();
  DateTime _startDate = DateUtils.dateOnly(DateTime.now());
  bool _signatureMissing = false;
  bool _sending = false;
  bool _writing = false;

  @override
  void dispose() {
    _terms.dispose();
    _signature.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final deadline = widget.proposal.estimationEndDate;
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: today,
      lastDate: deadline != null && deadline.isAfter(today) ? deadline : today.add(const Duration(days: 365)),
      helpText: 'Start date',
    );
    if (date != null) setState(() => _startDate = date);
  }

  /// The AI drafts the terms from the job and the proposal. What the client typed (if it isn't the
  /// default text) goes along as their own points to include.
  Future<void> _writeTerms() async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final before = _terms.text;
    final notes = before.trim() == _defaultTerms.trim() ? '' : before.trim();
    setState(() => _writing = true);
    try {
      final terms = await ref.read(contractRepositoryProvider).draftTerms(
            proposalId: widget.proposal.id,
            startDate: _startDate,
            notes: notes.isEmpty ? null : notes,
          );
      if (!mounted) return;
      _terms.text = terms;
      messenger.showSnackBar(SnackBar(
        content: const Text('The AI wrote the terms. Read them and change anything before you sign.'),
        action: SnackBarAction(label: 'Undo', onPressed: () => _terms.text = before),
      ));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    final signature = await _signature.exportDataUri();
    setState(() => _signatureMissing = signature == null);
    if (signature == null) {
      showSignatureCard(_signatureCard);
      return;
    }

    setState(() => _sending = true);
    try {
      final contract = await ref
          .read(myContractsProvider.notifier)
          .create(
            proposalId: widget.proposal.id,
            clientId: widget.clientId,
            clientName: await myContractName(ref),
            clientSignature: signature,
            startDate: _startDate,
            terms: _terms.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Contract sent. The freelancer is notified to sign it.')));
      context.pushReplacement(ContractPaths.details(contract.id));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final proposal = widget.proposal;
    final hourly = proposal.jobType == 'HOURLY';

    return Scaffold(
      appBar: AppBar(title: const Text('New contract')),
      // Not lazy: the signature card must exist to scroll to it.
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const IconBubble(
                          icon: Icons.description_outlined,
                          color: AppAccent.green,
                          size: 48,
                          solid: true,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                proposal.projectTitle ?? 'Project',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Contract for the accepted proposal',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (proposal.freelancerId != null) ...[
                      const Divider(height: 24),
                      PartyTile(userId: proposal.freelancerId!, role: 'Freelancer'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    icon: Icons.payments_outlined,
                    color: AppAccent.green,
                    value: formatMoney(proposal.bidAmount) + (hourly ? '/h' : ''),
                    label: 'Accepted bid',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    icon: Icons.flag_outlined,
                    color: AppAccent.orange,
                    value: proposal.estimationEndDate == null ? '—' : formatDay(proposal.estimationEndDate!),
                    label: 'Deadline',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InfoBanner(
              'When the freelancer signs, ${formatMoney(proposal.bidAmount)} is taken from your wallet '
              'and kept in escrow until you approve the work.',
              icon: Icons.lock_outline,
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Start date',
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  alignment: Alignment.centerLeft,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  foregroundColor: theme.colorScheme.onSurface,
                ),
                onPressed: _pickStartDate,
                icon: Icon(Icons.event_outlined, color: theme.colorScheme.primary),
                label: Text(formatDay(_startDate)),
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Terms',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _terms,
                    minLines: 6,
                    maxLines: 14,
                    textCapitalization: TextCapitalization.sentences,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AiButton(label: 'Write the terms with AI', busy: _writing, onPressed: _writeTerms),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Built from the job, the proposal and your dates. Type your own points first to include them.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              key: _signatureCard,
              title: 'Your signature',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SignaturePad(controller: _signature, error: _signatureMissing),
                  if (_signatureMissing)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        'Sign the contract to send it',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: const Text('Sign & send to the freelancer'),
          ),
        ),
      ),
    );
  }
}

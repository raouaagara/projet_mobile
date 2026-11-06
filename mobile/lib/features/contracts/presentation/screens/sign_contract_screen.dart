import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/models/contract.dart';
import '../contract_providers.dart';
import '../format.dart';
import '../widgets/contract_explainer.dart';
import '../widgets/signature_pad.dart';

/// Freelancer: read the contract, agree and sign. Signing locks the client's payment in escrow.
class SignContractScreen extends ConsumerWidget {
  const SignContractScreen({super.key, required this.contractId});

  final int contractId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).value;
    final contract = ref.watch(contractProvider(contractId));

    Widget blocked(String message) => Scaffold(
      appBar: AppBar(title: const Text('Sign the contract')),
      body: ErrorView(message: message),
    );

    if (contract.value case final loaded?) {
      if (session?.userId != loaded.freelancerId) return blocked('Only the freelancer of this contract can sign it.');
      if (loaded.status != ContractStatus.sent) {
        return blocked('This contract is ${loaded.status.label.toLowerCase()}.');
      }
      return _SignForm(contract: loaded);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Sign the contract')),
      body: AsyncValueView(value: contract, data: (_) => const SizedBox()),
    );
  }
}

class _SignForm extends ConsumerStatefulWidget {
  const _SignForm({required this.contract});

  final Contract contract;

  @override
  ConsumerState<_SignForm> createState() => _SignFormState();
}

class _SignFormState extends ConsumerState<_SignForm> {
  final _signature = SignaturePadController();
  final _signatureCard = GlobalKey();
  bool _agreed = false;
  bool _signatureMissing = false;
  bool _signing = false;

  @override
  void dispose() {
    _signature.dispose();
    super.dispose();
  }

  Future<void> _sign() async {
    final signature = await _signature.exportDataUri();
    setState(() => _signatureMissing = signature == null);
    if (signature == null) showSignatureCard(_signatureCard);
    if (signature == null || !_agreed) return;

    setState(() => _signing = true);
    try {
      await ref
          .read(myContractsProvider.notifier)
          .sign(widget.contract, signature: signature, freelancerName: await myContractName(ref));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signed! The client's payment is locked in escrow: you can start the work.")),
      );
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _signing = false);
      // E.g. the client's wallet is too low: explain it in a dialog, not a short snackbar.
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Not signed'),
          content: Text(e.message),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contract = widget.contract;

    final muted = theme.colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: const Text('Sign the contract')),
      // Not lazy: the signature card must exist to scroll to it.
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const IconBubble(icon: Icons.draw_outlined, color: AppAccent.orange, size: 48, solid: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contract.projectTitle,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Client: ${contract.clientName ?? '—'}',
                            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ),
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
                    value: formatMoney(contract.rate) + (contract.isHourly ? '/h' : ''),
                    label: 'Your pay',
                  ),
                ),
                const SizedBox(width: 10),
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
              ],
            ),
            const SizedBox(height: 12),
            const InfoBanner(
              "When you sign, the client's payment is locked in escrow. "
              'You receive it when the client approves your work.',
              icon: Icons.verified_user_outlined,
            ),
            const SizedBox(height: 12),
            ContractExplainer(contractId: contract.id),
            SectionCard(
              title: 'Terms',
              child: SelectableText(
                (contract.terms ?? '').trim().isEmpty ? 'No specific terms.' : contract.terms!,
                style: const TextStyle(height: 1.5),
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Signed by the client',
              child: SignatureImage(dataUri: contract.clientSignature, name: contract.clientName),
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
                        'Sign in the box above',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 4),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                    title: const Text('I have read the terms and I agree to them'),
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
            onPressed: _signing || !_agreed ? null : _sign,
            icon: _signing
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.draw),
            label: const Text('Sign the contract'),
          ),
        ),
      ),
    );
  }
}

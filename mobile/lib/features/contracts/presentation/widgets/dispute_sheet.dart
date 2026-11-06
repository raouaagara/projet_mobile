import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../data/contract_repository.dart';

/// Asks why the user opens a dispute on [contractId] ([role]: CLIENT or FREELANCER).
/// Returns the reason, or null if cancelled.
Future<String?> showDisputeSheet(BuildContext context, {required int contractId, required String role}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _DisputeSheet(contractId: contractId, role: role),
  );
}

class _DisputeSheet extends ConsumerStatefulWidget {
  const _DisputeSheet({required this.contractId, required this.role});

  final int contractId;
  final String role;

  @override
  ConsumerState<_DisputeSheet> createState() => _DisputeSheetState();
}

class _DisputeSheetState extends ConsumerState<_DisputeSheet> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  bool _writing = false;
  String? _aiError;

  /// The AI rewrites the message calmly and factually, with the contract's dates and amount.
  Future<void> _clarify() async {
    final before = _reason.text.trim();
    if (before.length < 10) {
      setState(() => _aiError = 'Write in a few words what went wrong first.');
      return;
    }
    setState(() {
      _writing = true;
      _aiError = null;
    });
    try {
      final text = await ref
          .read(contractRepositoryProvider)
          .draftDispute(contractId: widget.contractId, role: widget.role, text: before);
      if (mounted) _reason.text = text;
    } on ApiException catch (e) {
      if (mounted) setState(() => _aiError = e.message);
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      // Stay above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              Row(
                children: [
                  const IconBubble(icon: Icons.report_problem_outlined, color: AppAccent.red, size: 44, solid: true),
                  const SizedBox(width: 12),
                  Text('Report a problem', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'The payment stays locked in escrow and an admin reviews the case: '
                'they can pay the freelancer or refund the client.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text('What went wrong?', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reason,
                autofocus: true,
                minLines: 4,
                maxLines: 8,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Missed deadline, work not delivered, unpaid extra work…'),
                validator: (v) => (v ?? '').trim().length < 20 ? 'Explain the problem in at least 20 characters' : null,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: AiButton(label: 'Make it clear with AI', busy: _writing, onPressed: _clarify),
              ),
              if (_aiError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_aiError!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                onPressed: () {
                  if (_form.currentState!.validate()) Navigator.pop(context, _reason.text.trim());
                },
                child: const Text('Open a dispute'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

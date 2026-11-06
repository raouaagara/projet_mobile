import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/models/project.dart';
import '../../data/models/project_enums.dart';
import '../../data/models/proposal.dart';
import '../../data/project_repository.dart';
import '../format.dart';
import '../widgets/category_style.dart';
import '../project_providers.dart';

/// Freelancer: send a proposal (bid, delivery date, cover letter written or AI-drafted) on an open project.
class SubmitProposalScreen extends ConsumerWidget {
  const SubmitProposalScreen({super.key, required this.projectId});

  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).value;
    final project = ref.watch(projectProvider(projectId));
    final existing = ref.watch(myProposalForProvider(projectId));

    Widget blocked(String message) => Scaffold(
      appBar: AppBar(title: const Text('Submit a proposal')),
      body: ErrorView(message: message),
    );

    if (session == null || !session.isFreelancer) return blocked('Only freelancers can send proposals.');
    if (existing.value != null) return blocked('You already sent a proposal for this project.');
    if (project.value case final loaded?) {
      if (!loaded.isOpen) return blocked('This project is not accepting proposals anymore.');
      return _ProposalForm(project: loaded, freelancerId: session.userId);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Submit a proposal')),
      body: AsyncValueView(value: project, data: (_) => const SizedBox()),
    );
  }
}

class _ProposalForm extends ConsumerStatefulWidget {
  const _ProposalForm({required this.project, required this.freelancerId});

  final Project project;
  final int freelancerId;

  @override
  ConsumerState<_ProposalForm> createState() => _ProposalFormState();
}

class _ProposalFormState extends ConsumerState<_ProposalForm> {
  final _form = GlobalKey<FormState>();
  late final _bid = TextEditingController(text: widget.project.budget.toStringAsFixed(0));
  final _letter = TextEditingController();
  DateTime? _deliveryDate;
  bool _dateMissing = false;
  bool _sending = false;
  bool _writing = false;

  bool get _hourly => widget.project.jobType == JobType.hourly;

  @override
  void dispose() {
    _bid.dispose();
    _letter.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final tomorrow = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: _deliveryDate ?? tomorrow.add(const Duration(days: 13)),
      firstDate: tomorrow,
      lastDate: tomorrow.add(const Duration(days: 730)),
      helpText: 'Delivery date',
    );
    if (date == null) return;
    setState(() {
      _deliveryDate = date;
      _dateMissing = false;
    });
  }

  /// The AI writes the letter from the job, my profile, my bid and date, and what I typed as notes.
  Future<void> _writeWithAi() async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final notes = _letter.text.trim();
    setState(() => _writing = true);
    try {
      // Name, bio and skills for the letter (loaded here if no screen has needed them yet).
      final me = await ref.read(currentUserProvider.future);
      final letter = await ref
          .read(projectRepositoryProvider)
          .draftCoverLetter(
            projectId: widget.project.id!,
            freelancerName: me?.fullName,
            bio: me?.bio,
            skillIds: me?.competenceIds ?? const [],
            bidAmount: double.tryParse(_bid.text.replaceAll(',', '.')),
            deliveryDate: _deliveryDate,
            notes: notes.isEmpty ? null : notes,
          );
      if (!mounted) return;
      _letter.text = letter;
      messenger.showSnackBar(
        SnackBar(
          content: const Text('The AI wrote your letter. Read it and change anything before sending.'),
          action: SnackBarAction(label: 'Undo', onPressed: () => _letter.text = notes),
        ),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    final valid = _form.currentState!.validate();
    setState(() => _dateMissing = _deliveryDate == null);
    if (!valid || _deliveryDate == null) return;

    setState(() => _sending = true);
    try {
      await ref
          .read(projectRepositoryProvider)
          .submitProposal(
            widget.project.id!,
            Proposal(
              bidAmount: double.parse(_bid.text.replaceAll(',', '.')),
              estimationEndDate: _deliveryDate,
              freelancerId: widget.freelancerId,
              coverLetter: _letter.text.trim().isEmpty ? null : _letter.text.trim(),
            ),
          );
      ref.invalidate(myProposalsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Proposal sent. You'll be notified when the client answers.")));
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final project = widget.project;

    final category = project.category ?? ProjectCategory.other;
    return Scaffold(
      appBar: AppBar(title: const Text('Submit a proposal')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    IconBubble(icon: category.icon, color: categoryColor(category), size: 48, solid: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              PillTag('Budget: ${project.budgetLabel}', icon: Icons.payments_outlined),
                              if (project.jobType != null)
                                PillTag(project.jobType!.label, icon: Icons.schedule, color: AppAccent.blue),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            LabeledField(
              label: 'Your bid',
              child: TextFormField(
                controller: _bid,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: InputDecoration(
                  prefixText: r'$ ',
                  suffixText: _hourly ? '/ hour' : 'USD',
                  helperText: 'What you will charge for the whole job${_hourly ? ' (per hour)' : ''}.',
                ),
                validator: (v) {
                  final amount = double.tryParse((v ?? '').replaceAll(',', '.'));
                  return amount == null || amount <= 0 ? 'Enter your price' : null;
                },
              ),
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Delivery date',
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  alignment: Alignment.centerLeft,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: _dateMissing ? theme.colorScheme.error : theme.colorScheme.outlineVariant),
                  foregroundColor: theme.colorScheme.onSurface,
                ),
                onPressed: _pickDate,
                icon: Icon(Icons.event_outlined, color: theme.colorScheme.primary),
                label: Text(_deliveryDate == null ? 'When will it be done?' : formatDay(_deliveryDate!)),
              ),
            ),
            if (_dateMissing)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 6),
                child: Text(
                  'Pick a delivery date',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Cover letter (optional)',
              child: TextFormField(
                controller: _letter,
                minLines: 5,
                maxLines: 14,
                maxLength: 3000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Why you? Or jot a few notes (similar work, when you can start) and let the AI write it.',
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: AiButton(label: 'Write with AI', busy: _writing, onPressed: _sending ? null : _writeWithAi),
            ),
            const SizedBox(height: 20),
            const InfoBanner('The client is notified right away. You can follow the answer in "My proposals".'),
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
            label: const Text('Send proposal'),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/models/support_models.dart';
import '../../data/support_repository.dart';
import '../../messaging_paths.dart';
import '../format.dart';
import '../messaging_providers.dart';
import '../widgets/common.dart';

Color _statusColor(TicketStatus status) => switch (status) {
  TicketStatus.open => AppAccent.blue,
  TicketStatus.inProgress => AppAccent.purple,
  TicketStatus.pendingUser => AppAccent.orange,
  TicketStatus.resolved || TicketStatus.closed => AppAccent.green,
  TicketStatus.escalated => AppAccent.red,
  TicketStatus.unknown => AppAccent.grey,
};

Color _categoryColor(TicketCategory category) => switch (category) {
  TicketCategory.technicalIssue => AppAccent.blue,
  TicketCategory.paymentIssue => AppAccent.green,
  TicketCategory.accountIssue => AppAccent.purple,
  TicketCategory.contractDispute => AppAccent.red,
  TicketCategory.fraudReport => AppAccent.orange,
  TicketCategory.featureRequest => AppAccent.amber,
  TicketCategory.bugReport => AppAccent.pink,
  TicketCategory.other => AppAccent.grey,
};

Color _priorityColor(TicketPriority priority) => switch (priority) {
  TicketPriority.low => AppAccent.green,
  TicketPriority.medium => AppAccent.amber,
  TicketPriority.high => AppAccent.orange,
  TicketPriority.critical => AppAccent.red,
  TicketPriority.unknown => AppAccent.grey,
};

class TicketStatusChip extends StatelessWidget {
  const TicketStatusChip({super.key, required this.status});

  final TicketStatus status;

  @override
  Widget build(BuildContext context) => PillTag(status.label, icon: status.icon, color: _statusColor(status));
}

/// The way in to the AI assistant: most questions don't need a request.
class _AskAssistantCard extends StatelessWidget {
  const _AskAssistantCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppAccent.purple.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(MessagingPaths.assistant),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const IconBubble(icon: Icons.auto_awesome, color: AppAccent.purple, size: 46, solid: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ask the assistant',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Answers right away. If the team is needed, it writes the request for you.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

// ── My tickets ─────────────────────────────────────────────────────

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & support')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(MessagingPaths.newTicket),
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add),
        label: const Text('New request'),
      ),
      body: AsyncValueView(
        value: ref.watch(myTicketsProvider),
        onRetry: () => ref.invalidate(myTicketsProvider),
        data: (tickets) {
          final done = tickets.where((t) => t.status.isDone).length;
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myTicketsProvider.future),
            child: tickets.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: const [
                      _AskAssistantCard(),
                      SizedBox(height: 80),
                      EmptyView(
                        icon: Icons.support_agent,
                        message: 'No request yet.\nA problem with a payment, a contract or the app? Tell us.',
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: [
                      const _AskAssistantCard(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: StatTile(
                              icon: Icons.forum_outlined,
                              color: AppAccent.blue,
                              value: '${tickets.length - done}',
                              label: 'Open requests',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatTile(
                              icon: Icons.check_rounded,
                              color: AppAccent.green,
                              value: '$done',
                              label: 'Solved',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      for (final ticket in tickets)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TicketCard(ticket: ticket),
                        ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final category = ticket.category ?? TicketCategory.other;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(MessagingPaths.ticket(ticket.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBubble(icon: category.icon, color: _categoryColor(category), size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '#${ticket.id} · ${category.label}',
                          style: theme.textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ticket.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted, height: 1.4),
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
              Row(
                children: [
                  TicketStatusChip(status: ticket.status),
                  const Spacer(),
                  if (ticket.createdAt != null) ...[
                    Icon(Icons.access_time, size: 14, color: muted),
                    const SizedBox(width: 4),
                    Text(ago(ticket.createdAt), style: theme.textTheme.labelSmall?.copyWith(color: muted)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── New ticket ─────────────────────────────────────────────────────

class NewTicketScreen extends ConsumerStatefulWidget {
  const NewTicketScreen({super.key, this.initialTitle, this.initialDescription});

  /// Written by the help assistant, when it sends the user here.
  final String? initialTitle;
  final String? initialDescription;

  @override
  ConsumerState<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends ConsumerState<NewTicketScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initialTitle);
  late final _description = TextEditingController(text: widget.initialDescription);
  TicketCategory? _category; // null: detected by the server
  bool _enhancing = false;
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _enhance() async {
    final text = _description.text.trim();
    if (text.length < 10) {
      _snack('Write a few words first.');
      return;
    }
    setState(() => _enhancing = true);
    try {
      final enhanced = await ref.read(supportRepositoryProvider).enhance(title: _title.text.trim(), description: text);
      if (!mounted) return;
      if (enhanced.trim() == text) {
        _snack('Your text is already clear: the AI kept it as it is.');
      } else {
        _description.text = enhanced;
        _snack('Text improved. Check it before sending.');
      }
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _enhancing = false);
    }
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() => _sending = true);
    final session = ref.read(authControllerProvider).value!;
    final user = ref.read(currentUserProvider).value;
    try {
      final ticket = await ref
          .read(supportRepositoryProvider)
          .create(
            userId: session.userId,
            userName: user?.fullName ?? session.email,
            userEmail: session.email,
            title: _title.text.trim(),
            description: _description.text.trim(),
            category: _category,
          );
      ref.invalidate(myTicketsProvider);
      if (!mounted) return;
      _snack('Request sent. We answer in this app.');
      context.pushReplacement(MessagingPaths.ticket(ticket.id));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      _snack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('New request')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const InfoBanner(
              'Tell us what happened: the support team answers in this app, usually within a day.',
              icon: Icons.support_agent,
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Your request',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LabeledField(
                    label: 'Subject',
                    child: TextFormField(
                      controller: _title,
                      maxLength: 120,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: 'e.g. Payment not received'),
                      validator: (v) => (v ?? '').trim().length < 5 ? 'At least 5 characters' : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LabeledField(
                    label: 'What happened?',
                    child: TextFormField(
                      controller: _description,
                      minLines: 5,
                      maxLines: 12,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Steps, contract or project number, screenshots described…',
                      ),
                      validator: (v) =>
                          (v ?? '').trim().length < 20 ? 'Describe the problem in at least 20 characters' : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppAccent.purple,
                        side: BorderSide(color: AppAccent.purple.withValues(alpha: 0.4)),
                      ),
                      onPressed: _enhancing ? null : _enhance,
                      icon: _enhancing
                          ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Improve with AI'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Topic',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilterPills<TicketCategory?>(
                    wrap: true,
                    values: [null, ...TicketCategory.values],
                    selected: _category,
                    label: (category) => category?.label ?? 'Not sure',
                    icon: (category) => category?.icon ?? Icons.auto_awesome,
                    onSelected: (category) => setState(() => _category = category),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '"Not sure": we pick the topic and the priority from your text.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                : const Icon(Icons.send_rounded),
            label: const Text('Send'),
          ),
        ),
      ),
    );
  }
}

// ── One ticket ─────────────────────────────────────────────────────

/// A ticket and its conversation with the support team. Refreshes every few seconds
/// (the support server can't push to users yet).
class TicketScreen extends ConsumerStatefulWidget {
  const TicketScreen({super.key, required this.ticketId});

  final int ticketId;

  @override
  ConsumerState<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends ConsumerState<TicketScreen> {
  static const refreshEvery = Duration(seconds: 10);
  final _reply = TextEditingController();
  Timer? _timer;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(refreshEvery, (_) {
      ref.invalidate(ticketProvider(widget.ticketId));
      ref.invalidate(ticketRepliesProvider(widget.ticketId));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _reply.dispose();
    super.dispose();
  }

  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final session = ref.read(authControllerProvider).value!;
    final user = ref.read(currentUserProvider).value;
    try {
      await ref
          .read(supportRepositoryProvider)
          .reply(widget.ticketId, userId: session.userId, userName: user?.fullName ?? session.email, message: text);
      _reply.clear();
      ref.invalidate(ticketRepliesProvider(widget.ticketId));
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _escalate() async {
    try {
      await ref.read(supportRepositoryProvider).escalate(widget.ticketId);
      ref.invalidate(ticketProvider(widget.ticketId));
      ref.invalidate(myTicketsProvider);
      _snack('Escalated: a senior agent will take over.');
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ticket = ref.watch(ticketProvider(widget.ticketId));
    final replies = ref.watch(ticketRepliesProvider(widget.ticketId));
    final me = ref.watch(authControllerProvider).value?.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Request #${widget.ticketId}'),
        actions: [
          if (ticket.value case final t? when !t.escalated && !t.status.isDone)
            PopupMenuButton<String>(
              onSelected: (_) => _escalate(),
              itemBuilder: (context) => const [PopupMenuItem(value: 'escalate', child: Text('Escalate (urgent)'))],
            ),
        ],
      ),
      body: AsyncValueView(
        value: ticket,
        onRetry: () => ref.invalidate(ticketProvider(widget.ticketId)),
        data: (ticket) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _TicketHeader(ticket: ticket),
                  const SizedBox(height: 16),
                  _Message(author: 'You', text: ticket.description, time: ticket.createdAt, mine: true),
                  ...replies.when(
                    loading: () => [const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator())],
                    error: (e, _) => [Text(ApiException.from(e).message)],
                    data: (replies) => [
                      for (final reply in replies)
                        _Message(
                          author: reply.staff ? (reply.responderName ?? 'Support') : 'You',
                          text: reply.message,
                          time: reply.createdAt,
                          mine: !reply.staff && reply.responderId == me,
                          staff: reply.staff,
                        ),
                    ],
                  ),
                  if (!ticket.status.isDone && (replies.value?.every((r) => !r.staff) ?? false))
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: InfoBanner(
                        ticket.slaDeadline == null
                            ? 'The support team will answer here.'
                            : 'The support team will answer here, by ${dateTime(ticket.slaDeadline!)} at the latest.',
                        icon: Icons.schedule,
                        color: AppAccent.blue,
                      ),
                    ),
                ],
              ),
            ),
            if (!ticket.status.isDone)
              ChatComposer(controller: _reply, sending: _sending, onSend: _send, hintText: 'Add a message')
            else
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: InfoBanner(
                    'This request is closed.',
                    icon: Icons.lock_outline,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TicketHeader extends StatelessWidget {
  const _TicketHeader({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = ticket.category ?? TicketCategory.other;
    final color = _categoryColor(category);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBubble(icon: category.icon, color: color, size: 48, solid: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.label,
                    style: theme.textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
                TicketStatusChip(status: ticket.status),
              ],
            ),
            const SizedBox(height: 14),
            Text(ticket.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            if (ticket.priority != null || ticket.department != null || ticket.escalated) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (ticket.priority != null)
                    PillTag(
                      '${ticket.priority!.label} priority',
                      icon: Icons.flag_outlined,
                      color: _priorityColor(ticket.priority!),
                    ),
                  if (ticket.department != null)
                    PillTag(ticket.department!, icon: Icons.apartment_outlined, color: AppAccent.blue),
                  if (ticket.escalated) const PillTag('Escalated', icon: Icons.priority_high, color: AppAccent.red),
                ],
              ),
            ],
            if ((ticket.aiSummary ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              InfoBanner('Summary: ${ticket.aiSummary}', icon: Icons.auto_awesome, color: AppAccent.purple),
            ],
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.author,
    required this.text,
    required this.time,
    required this.mine,
    this.staff = false,
  });

  final String author;
  final String text;
  final DateTime? time;
  final bool mine;
  final bool staff;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = mine ? colors.onPrimary : colors.onSurface;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: mine ? colors.primary : colors.surface,
          border: mine ? null : Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(mine ? 20 : 6),
            bottomRight: Radius.circular(mine ? 6 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (staff) ...[
                  const IconBubble(icon: Icons.support_agent, color: AppAccent.green, size: 24, solid: true),
                  const SizedBox(width: 6),
                ],
                Text(
                  author,
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: foreground),
                ),
                if (time != null)
                  Text(
                    '  ·  ${dateTime(time!)}',
                    style: theme.textTheme.labelSmall?.copyWith(color: foreground.withValues(alpha: 0.75)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(text, style: TextStyle(color: foreground, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

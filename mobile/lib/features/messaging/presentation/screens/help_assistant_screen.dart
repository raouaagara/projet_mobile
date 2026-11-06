import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../data/support_repository.dart';
import '../../messaging_paths.dart';
import '../widgets/common.dart';

const _starters = [
  'How do I get paid for a contract?',
  'How do I add money to my wallet?',
  'What happens if there is a problem with a contract?',
];

/// "Ask the assistant": answers from the Workify help guide (AI, on the server). When the support team
/// has to act, it offers a request already written from the conversation.
class HelpAssistantScreen extends ConsumerStatefulWidget {
  const HelpAssistantScreen({super.key});

  @override
  ConsumerState<HelpAssistantScreen> createState() => _HelpAssistantScreenState();
}

class _HelpAssistantScreenState extends ConsumerState<HelpAssistantScreen> {
  final _input = TextEditingController();
  final _turns = <AssistantTurn>[];
  AssistantAnswer? _last;
  bool _asking = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _ask([String? starter]) async {
    final question = (starter ?? _input.text).trim();
    if (question.isEmpty || _asking) return;
    final history = [..._turns];
    setState(() {
      _turns.add(AssistantTurn(fromUser: true, text: question));
      _asking = true;
      _last = null;
    });
    _input.clear();
    try {
      final answer = await ref.read(supportRepositoryProvider).ask(question, history: history);
      if (!mounted) return;
      setState(() {
        _turns.add(AssistantTurn(fromUser: false, text: answer.answer));
        _last = answer;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _turns.add(AssistantTurn(fromUser: false, text: e.message, failed: true)));
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  void _openRequest(AssistantAnswer answer) =>
      context.push(MessagingPaths.newTicket, extra: (title: answer.ticketTitle, description: answer.ticketDescription));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = _last;
    return Scaffold(
      appBar: AppBar(title: const Text('Ask the assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              reverse: true,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              children: [
                if (last != null && last.needsTicket) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                      onPressed: () => _openRequest(last),
                      icon: const Icon(Icons.support_agent),
                      label: const Text('Send it to the support team'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_asking)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ),
                for (final turn in _turns.reversed) _TurnBubble(turn: turn),
                if (_turns.isEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final q in _starters)
                        ActionChip(
                          label: Text(q),
                          side: BorderSide(color: AppAccent.purple.withValues(alpha: 0.3)),
                          backgroundColor: theme.colorScheme.surface,
                          onPressed: () => _ask(q),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ask anything about Workify: payments, contracts, your profile. It answers from the Workify '
                    'help guide, and writes a request to the team when they need to step in.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppAccent.purple),
                      const SizedBox(width: 8),
                      Text(
                        'How can I help?',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          ChatComposer(controller: _input, sending: _asking, onSend: _ask, hintText: 'Ask a question'),
        ],
      ),
    );
  }
}

class _TurnBubble extends StatelessWidget {
  const _TurnBubble({required this.turn});

  final AssistantTurn turn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mine = turn.fromUser;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine
              ? colors.primary
              : turn.failed
              ? colors.errorContainer
              : AppAccent.purple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          turn.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.45,
            color: mine ? colors.onPrimary : (turn.failed ? colors.onErrorContainer : colors.onSurface),
          ),
        ),
      ),
    );
  }
}

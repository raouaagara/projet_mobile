import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../data/contract_repository.dart';

/// Before signing: "Explain this contract" asks the AI for the terms in plain words, and for the points
/// worth agreeing on in the chat first. A tinted block, because it is the AI talking, not the contract.
class ContractExplainer extends ConsumerStatefulWidget {
  const ContractExplainer({super.key, required this.contractId, this.role = 'FREELANCER'});

  final int contractId;
  final String role;

  @override
  ConsumerState<ContractExplainer> createState() => _ContractExplainerState();
}

class _ContractExplainerState extends ConsumerState<ContractExplainer> {
  ContractExplanation? _explanation;
  String? _error;
  bool _loading = false;

  Future<void> _explain() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final explanation = await ref.read(contractRepositoryProvider).explain(widget.contractId, role: widget.role);
      if (mounted) setState(() => _explanation = explanation);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final explanation = _explanation;
    if (explanation == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AiButton(label: 'Explain this contract', busy: _loading, onPressed: _explain),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
              ),
          ],
        ),
      );
    }

    Widget point(String text, {required IconData icon, required Color color}) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 16, color: color)),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45))),
            ],
          ),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppAccent.purple.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: AppAccent.purple),
              const SizedBox(width: 8),
              Text('In short', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          for (final s in explanation.summary) point(s, icon: Icons.check, color: AppAccent.purple),
          if (explanation.check.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Worth agreeing on in the chat first',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            for (final s in explanation.check) point(s, icon: Icons.help_outline, color: AppAccent.orange),
          ],
          const SizedBox(height: 10),
          Text(
            'Written by AI from these terms. It is not legal advice.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../contract_paths.dart';
import '../contract_providers.dart';
import '../widgets/contract_card.dart';

/// Second tab: the user's contracts (client or freelancer), by status.
class ContractsScreen extends ConsumerStatefulWidget {
  const ContractsScreen({super.key});

  @override
  ConsumerState<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends ConsumerState<ContractsScreen> {
  ContractFilter _filter = ContractFilter.all;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).value;
    final contracts = ref.watch(myContractsProvider);
    final isClient = session?.isClient ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Contracts')),
      body: AsyncValueView(
        value: contracts,
        onRetry: () => ref.invalidate(myContractsProvider),
        data: (contracts) {
          int count(ContractFilter filter) => contracts.where((c) => filter.matches(c.status)).length;
          final toSign = count(ContractFilter.toSign);
          final shown = contracts.where((c) => _filter.matches(c.status)).toList();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myContractsProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        icon: Icons.draw_outlined,
                        color: AppAccent.amber,
                        value: '$toSign',
                        label: 'To sign',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        icon: Icons.play_arrow_rounded,
                        color: AppAccent.blue,
                        value: '${count(ContractFilter.active)}',
                        label: 'In progress',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        icon: Icons.verified_outlined,
                        color: AppAccent.green,
                        value: '${count(ContractFilter.completed)}',
                        label: 'Completed',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Shortcut(
                        icon: Icons.account_balance_wallet_outlined,
                        color: AppAccent.purple,
                        label: 'Wallet',
                        onTap: () => context.push(ContractPaths.wallet),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Shortcut(
                        icon: Icons.gavel_outlined,
                        color: AppAccent.red,
                        label: 'Disputes',
                        onTap: () => context.push(ContractPaths.disputes),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilterPills(
                  values: ContractFilter.values,
                  selected: _filter,
                  label: (filter) =>
                      filter == ContractFilter.toSign && toSign > 0 ? '${filter.label} ($toSign)' : filter.label,
                  onSelected: (filter) => setState(() => _filter = filter),
                ),
                const SizedBox(height: 14),
                if (contracts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: EmptyView(
                      icon: Icons.description_outlined,
                      message: isClient
                          ? 'No contract yet.\nAccept a proposal on one of your projects to create one.'
                          : 'No contract yet.\nWhen a client hires you, the contract shows up here to sign.',
                    ),
                  )
                else if (shown.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: EmptyView(icon: Icons.filter_list_off, message: 'No contract in this list.'),
                  ),
                for (final contract in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ContractCard(
                      contract: contract,
                      viewerId: session?.userId ?? 0,
                      onTap: () => context.push(ContractPaths.details(contract.id)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A small card that opens another page (wallet, disputes).
class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.icon, required this.color, required this.label, required this.onTap});

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              IconBubble(icon: icon, color: color, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

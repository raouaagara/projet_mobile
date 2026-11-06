import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/brand.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../contract_paths.dart';
import '../../data/models/payment_models.dart';
import '../contract_providers.dart';
import '../format.dart';
import '../widgets/contract_style.dart';

/// Balance, money held in escrow and transaction history (client & freelancer).
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: AsyncValueView(
        value: ref.watch(walletProvider),
        onRetry: () => ref.invalidate(walletProvider),
        data: (wallet) => wallet == null
            ? const _NoWallet()
            : RefreshIndicator(
                onRefresh: () => Future.wait([
                  ref.refresh(walletProvider.future),
                  ref.refresh(myEscrowsProvider.future),
                  ref.refresh(transactionsProvider.future),
                ]),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _BalanceCard(wallet: wallet),
                    const SizedBox(height: 12),
                    const _Totals(),
                    const SizedBox(height: 12),
                    const _EscrowSection(),
                    const SizedBox(height: 12),
                    const _ActivitySection(),
                  ],
                ),
              ),
      ),
    );
  }
}

class _NoWallet extends ConsumerStatefulWidget {
  const _NoWallet();

  @override
  ConsumerState<_NoWallet> createState() => _NoWalletState();
}

class _NoWalletState extends ConsumerState<_NoWallet> {
  bool _creating = false;

  Future<void> _create() async {
    setState(() => _creating = true);
    try {
      await ref.read(walletProvider.notifier).create();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClient = ref.watch(authControllerProvider).value?.isClient ?? false;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBubble(icon: Icons.account_balance_wallet_outlined, color: theme.colorScheme.primary, size: 88),
            const SizedBox(height: 20),
            Text('No wallet yet', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              isClient
                  ? 'Your wallet funds your contracts: the money is locked in escrow when a freelancer signs.'
                  : 'Your wallet receives your payments when clients approve your work.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _creating ? null : _create,
              child: _creating
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create my wallet'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The balance on a green card, with "Add money" for clients.
class _BalanceCard extends ConsumerWidget {
  const _BalanceCard({required this.wallet});

  final Wallet wallet;

  Future<void> _topUp(BuildContext context, WidgetRef ref) async {
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _TopUpSheet(),
    );
    if (amount == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(walletProvider.notifier).topUp(amount);
      messenger.showSnackBar(SnackBar(content: Text('${formatMoney(amount)} added to your wallet.')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final isClient = wallet.walletType != WalletType.freelancer;
    Widget ring(double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Brand.green, Brand.darkGreen],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -40, right: -30, child: ring(150)),
          Positioned(bottom: -60, right: 60, child: ring(120)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2)),
                      child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Total balance',
                        style: text.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        wallet.currency,
                        style: text.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  formatMoney(wallet.balance),
                  key: const ValueKey('wallet-balance'),
                  style: text.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                if (isClient)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      backgroundColor: Colors.white,
                      foregroundColor: Brand.darkGreen,
                    ),
                    onPressed: () => _topUp(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add money'),
                  )
                else
                  Text(
                    'Payments land here when clients approve your work.',
                    style: text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Money in, money out and money held, like a dashboard.
class _Totals extends ConsumerWidget {
  const _Totals();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authControllerProvider).value?.userId ?? 0;
    final transactions = ref.watch(transactionsProvider).value;
    final escrows = ref.watch(myEscrowsProvider).value;
    String total(Iterable<double>? amounts) =>
        amounts == null ? '—' : formatMoney(amounts.fold<double>(0, (sum, a) => sum + a));
    return Row(
      children: [
        Expanded(
          child: StatTile(
            icon: Icons.south_west_rounded,
            color: AppAccent.green,
            value: total(transactions?.where((t) => t.isIncomingFor(userId)).map((t) => t.amount)),
            label: 'Money in',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatTile(
            icon: Icons.north_east_rounded,
            color: AppAccent.red,
            value: total(transactions?.where((t) => !t.isIncomingFor(userId)).map((t) => t.amount)),
            label: 'Money out',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatTile(
            icon: Icons.lock_outline,
            color: AppAccent.amber,
            value: total(escrows?.where((e) => !e.status.isClosed).map((e) => e.remainingAmount)),
            label: 'In escrow',
          ),
        ),
      ],
    );
  }
}

class _TopUpSheet extends StatefulWidget {
  const _TopUpSheet();

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  static const _presets = [100, 500, 1000, 5000];

  final _amount = TextEditingController(text: '500');
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0 || amount > 100000) {
      setState(() => _error = r'Enter an amount between $1 and $100,000');
      return;
    }
    Navigator.pop(context, amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const IconBubble(icon: Icons.add_card, color: AppAccent.green, size: 44, solid: true),
                  const SizedBox(width: 12),
                  Text('Add money', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 20),
              LabeledField(
                label: 'Amount',
                child: TextField(
                  controller: _amount,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  decoration: InputDecoration(prefixText: r'$ ', suffixText: 'USD', errorText: _error),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(height: 12),
              FilterPills(
                values: _presets,
                selected: int.tryParse(_amount.text),
                label: formatMoney,
                onSelected: (preset) => setState(() => _amount.text = '$preset'),
              ),
              const SizedBox(height: 16),
              const InfoBanner(
                'Test money: no card is charged. Real payments are not connected yet.',
                color: AppAccent.blue,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _submit, child: const Text('Add')),
            ],
          ),
        ),
      ),
    );
  }
}

class _EscrowSection extends ConsumerWidget {
  const _EscrowSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final escrows = ref.watch(myEscrowsProvider);
    return SectionCard(
      title: 'Held for contracts',
      child: escrows.when(
        loading: () => const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
        error: (e, _) => Text(ApiException.from(e).message),
        data: (escrows) {
          final open = escrows.where((e) => !e.status.isClosed).toList();
          if (open.isEmpty) {
            return Text(
              'No money is held for a contract right now.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            );
          }
          return Column(
            children: [
              for (final escrow in open)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: IconBubble(icon: escrow.status.icon, color: escrowStatusColor(escrow.status), size: 42),
                  title: Text('Contract #${escrow.contractId}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(escrow.status.label),
                  trailing: Text(
                    formatMoney(escrow.remainingAmount),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  onTap: () => context.push(ContractPaths.details(escrow.contractId)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ActivitySection extends ConsumerWidget {
  const _ActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userId = ref.watch(authControllerProvider).value?.userId ?? 0;
    final transactions = ref.watch(transactionsProvider);
    return SectionCard(
      title: 'Recent activity',
      child: transactions.when(
        loading: () => const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
        error: (e, _) => Text(ApiException.from(e).message),
        data: (transactions) {
          if (transactions.isEmpty) {
            return Text(
              'No transaction yet.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            );
          }
          return Column(
            children: [
              for (final (i, tx) in transactions.indexed) ...[
                if (i > 0) const Divider(height: 1, indent: 56),
                _TransactionTile(transaction: tx, userId: userId),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction, required this.userId});

  final WalletTransaction transaction;
  final int userId;

  @override
  Widget build(BuildContext context) {
    final incoming = transaction.isIncomingFor(userId);
    final color = incoming ? AppAccent.green : AppAccent.red;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconBubble(icon: transaction.type.icon, color: color, size: 42),
      title: Text(transaction.type.label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        [
          if (transaction.description != null) transaction.description!,
          if (transaction.createdAt != null) formatDateTime(transaction.createdAt!),
        ].join('\n'),
      ),
      isThreeLine: transaction.description != null && transaction.createdAt != null,
      trailing: Text(
        '${incoming ? '+' : '−'}${formatMoney(transaction.amount)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

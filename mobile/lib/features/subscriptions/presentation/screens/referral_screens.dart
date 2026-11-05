import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/invite_writer.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/brand.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/models/referral_models.dart';
import '../../data/referral_repository.dart';
import '../../subscription_paths.dart';
import '../format.dart';
import '../subscription_providers.dart';
import 'plans_screens.dart' show GreenCard, GreenCardIcon;

const _bonus = 5.0; // ReferralService.REFERRAL_BONUS

// ── Referral ───────────────────────────────────────────────────────

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final code = ref.watch(myReferralCodeProvider);
    final referrals = ref.watch(referralsProvider);
    final wallet = ref.watch(rewardWalletProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Referral')),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([ref.refresh(referralsProvider.future), ref.refresh(rewardWalletProvider.future)]),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            GreenCard(
              child: Column(
                children: [
                  const GreenCardIcon(Icons.card_giftcard, size: 56),
                  const SizedBox(height: 12),
                  Text(
                    'Invite freelancers and clients',
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You earn ${money(_bonus)} in your reward wallet for each person who joins with your code.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.92)),
                  ),
                  const SizedBox(height: 16),
                  code.when(
                    loading: () => const CircularProgressIndicator(color: Colors.white),
                    error: (e, _) => Text(ApiException.from(e).message, style: const TextStyle(color: Colors.white)),
                    data: (code) => Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white54),
                          ),
                          child: SelectableText(
                            code,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(46),
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white70),
                                ),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: code));
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(const SnackBar(content: Text('Code copied')));
                                },
                                icon: const Icon(Icons.copy, size: 18),
                                label: const Text('Copy'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(46),
                                  backgroundColor: Colors.white,
                                  foregroundColor: Brand.darkGreen,
                                ),
                                onPressed: () => SharePlus.instance.share(
                                  ShareParams(
                                    subject: 'Join me on ${Brand.name}',
                                    text: 'I find freelance work on ${Brand.name}. Sign up and enter my code $code 🎁',
                                  ),
                                ),
                                icon: const Icon(Icons.share, size: 18),
                                label: const Text('Share'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (code.value case final code? when code.isNotEmpty) ...[
              const SizedBox(height: 12),
              InviteWriterCard(code: code),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    icon: Icons.group_add_outlined,
                    color: AppAccent.blue,
                    value: '${referrals.value?.length ?? '…'}',
                    label: 'Friends invited',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    icon: Icons.savings_outlined,
                    color: AppAccent.green,
                    value: wallet == null ? '…' : money(wallet.balance),
                    label: 'Reward balance',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              clipBehavior: Clip.antiAlias,
              child: MenuTile(
                icon: Icons.volunteer_activism_outlined,
                color: AppAccent.purple,
                title: 'Reward wallet & donations',
                subtitle: 'Your rewards, gifts and the top earners',
                onTap: () => context.push(SubscriptionPaths.rewardWallet),
              ),
            ),
            const SizedBox(height: 12),
            const _EnterCode(),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Friends who joined',
              child: AsyncValueView(
                value: referrals,
                onRetry: () => ref.invalidate(referralsProvider),
                data: (referrals) => referrals.isEmpty
                    ? Text('Nobody yet. Share your code!', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
                    : Column(
                        children: [
                          for (final referral in referrals)
                            if (referral.referredUserId != null)
                              _PersonTile(
                                userId: referral.referredUserId!,
                                subtitle: referral.referredAt == null ? null : 'Joined ${day(referral.referredAt!)}',
                                // Held by the fraud check: no bonus until an admin looks at it.
                                trailing: referral.status == 'UNDER_REVIEW'
                                    ? const PillTag(
                                        'Being checked',
                                        icon: Icons.shield_outlined,
                                        color: AppAccent.amber,
                                      )
                                    : Text(
                                        '+${money(_bonus)}',
                                        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w800),
                                      ),
                              ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A new user can enter the code of the friend who invited them (once).
class _EnterCode extends ConsumerStatefulWidget {
  const _EnterCode();

  @override
  ConsumerState<_EnterCode> createState() => _EnterCodeState();
}

class _EnterCodeState extends ConsumerState<_EnterCode> {
  final _code = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _code.text.trim();
    if (code.isEmpty) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(referralRepositoryProvider).useCode(code, userId: ref.read(authControllerProvider).value!.userId);
      _code.clear();
      messenger.showSnackBar(const SnackBar(content: Text('Thanks! Your friend gets their bonus.')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Invited by a friend?',
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Their code, e.g. CATCH-7-A1B2C3',
                isDense: true,
                prefixIcon: Icon(Icons.redeem),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: _sending ? null : _submit,
            child: const Text('Use'),
          ),
        ],
      ),
    );
  }
}

class _PersonTile extends ConsumerWidget {
  const _PersonTile({required this.userId, this.subtitle, this.trailing});

  final int userId;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(rewardUserProvider(userId));
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: UserAvatar(user: user.value, radius: 22),
      title: Text(
        user.value?.fullName ?? (user.isLoading ? '…' : 'User #$userId'),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
    );
  }
}

// ── Reward wallet ──────────────────────────────────────────────────

class RewardWalletScreen extends ConsumerWidget {
  const RewardWalletScreen({super.key});

  Future<void> _donate(BuildContext context, WidgetRef ref, RewardWallet wallet) async {
    final donated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DonateSheet(balance: wallet.balance),
    );
    if (donated == true) {
      ref.invalidate(rewardWalletProvider);
      ref.invalidate(donationsProvider);
      ref.invalidate(topEarnersProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final me = ref.watch(authControllerProvider).value?.userId;
    return Scaffold(
      appBar: AppBar(title: const Text('Reward wallet')),
      body: AsyncValueView(
        value: ref.watch(rewardWalletProvider),
        onRetry: () => ref.invalidate(rewardWalletProvider),
        data: (wallet) => RefreshIndicator(
          onRefresh: () => Future.wait([
            ref.refresh(rewardWalletProvider.future),
            ref.refresh(rewardTransactionsProvider.future),
            ref.refresh(donationsProvider.future),
          ]),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              GreenCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const GreenCardIcon(Icons.savings_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Reward balance',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.military_tech_outlined, size: 15, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                wallet.currentTier.label,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      money(wallet.balance),
                      style: theme.textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${wallet.certificationsCount} certifications',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        backgroundColor: Colors.white,
                        foregroundColor: Brand.darkGreen,
                      ),
                      onPressed: wallet.balance > 0 ? () => _donate(context, ref, wallet) : null,
                      icon: const Icon(Icons.volunteer_activism_outlined),
                      label: const Text('Donate'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.trending_up,
                      color: AppAccent.green,
                      value: money(wallet.totalEarned),
                      label: 'Earned',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      icon: Icons.north_east_rounded,
                      color: AppAccent.pink,
                      value: money(wallet.totalDonated),
                      label: 'Donated',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      icon: Icons.south_west_rounded,
                      color: AppAccent.blue,
                      value: money(wallet.totalReceived),
                      label: 'Received',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const InfoBanner('Earned from referrals and certification tiers. It can be donated to other members.'),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Activity',
                child: ref
                    .watch(rewardTransactionsProvider)
                    .when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text(ApiException.from(e).message),
                      data: (transactions) => transactions.isEmpty
                          ? Text('No reward yet.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
                          : Column(
                              children: [
                                for (final tx in transactions)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const IconBubble(
                                      icon: Icons.stars_outlined,
                                      color: AppAccent.amber,
                                      size: 42,
                                    ),
                                    title: Text(tx.typeLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      [
                                        if ((tx.description ?? '').isNotEmpty) tx.description!,
                                        if (tx.createdAt != null) day(tx.createdAt!),
                                      ].join('\n'),
                                    ),
                                    trailing: Text(
                                      '+${money(tx.amount)}',
                                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                              ],
                            ),
                    ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Donations',
                child: ref
                    .watch(donationsProvider)
                    .when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text(ApiException.from(e).message),
                      data: (donations) {
                        final all = [
                          for (final d in donations.sent) (donation: d, sent: true),
                          for (final d in donations.received) (donation: d, sent: false),
                        ]..sort((a, b) => b.donation.id.compareTo(a.donation.id));
                        if (all.isEmpty) {
                          return Text('No donation yet.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant));
                        }
                        return Column(
                          children: [
                            for (final entry in all)
                              _PersonTile(
                                userId: entry.sent ? entry.donation.recipientId : entry.donation.donorId,
                                subtitle: [
                                  entry.sent
                                      ? 'You donated'
                                      : (entry.donation.isAnonymous ? 'Anonymous donation' : 'Donated to you'),
                                  if ((entry.donation.message ?? '').isNotEmpty) '"${entry.donation.message}"',
                                ].join(' · '),
                                trailing: Text(
                                  '${entry.sent ? '−' : '+'}${money(entry.donation.amount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: entry.sent ? theme.colorScheme.error : theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Top earners',
                icon: Icons.emoji_events_outlined,
                child: ref
                    .watch(topEarnersProvider)
                    .when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text(ApiException.from(e).message),
                      data: (top) => Column(
                        children: [
                          for (final (i, w) in top.take(10).indexed)
                            _PersonTile(
                              userId: w.userId,
                              subtitle: '#${i + 1}${w.userId == me ? ' · you' : ''}',
                              trailing: Text(money(w.totalEarned), style: const TextStyle(fontWeight: FontWeight.w800)),
                            ),
                        ],
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonateSheet extends ConsumerStatefulWidget {
  const _DonateSheet({required this.balance});

  final double balance;

  @override
  ConsumerState<_DonateSheet> createState() => _DonateSheetState();
}

class _DonateSheetState extends ConsumerState<_DonateSheet> {
  final _amount = TextEditingController(text: '1');
  final _message = TextEditingController();
  AppUser? _recipient;
  String _query = '';
  bool _anonymous = false;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (_recipient == null) return setState(() => _error = 'Pick someone');
    if (amount == null || amount <= 0 || amount > widget.balance) {
      return setState(() => _error = 'Between \$0.01 and ${money(widget.balance)}');
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(referralRepositoryProvider)
          .donate(
            donorId: ref.read(authControllerProvider).value!.userId,
            recipientId: _recipient!.id,
            amount: amount,
            message: _message.text,
            anonymous: _anonymous,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${money(amount)} sent to ${_recipient!.firstName}. Thank you!')));
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(donationRecipientsProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              Row(
                children: [
                  const IconBubble(
                    icon: Icons.volunteer_activism_outlined,
                    color: AppAccent.pink,
                    size: 44,
                    solid: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Donate',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text('Available: ${money(widget.balance)}'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_recipient == null) ...[
                SearchField(
                  hintText: 'Search a member',
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                ),
                const SizedBox(height: 4),
                ...users.when(
                  loading: () => [const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator())],
                  error: (e, _) => [Text(ApiException.from(e).message)],
                  data: (users) => [
                    for (final user
                        in users.where((u) => _query.isEmpty || u.fullName.toLowerCase().contains(_query)).take(20))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: UserAvatar(user: user),
                        title: Text(user.fullName),
                        onTap: () => setState(() => _recipient = user),
                      ),
                  ],
                ),
              ] else ...[
                Card(
                  child: ListTile(
                    leading: UserAvatar(user: _recipient),
                    title: Text(_recipient!.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    trailing: TextButton(
                      onPressed: () => setState(() => _recipient = null),
                      child: const Text('Change'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount', prefixText: r'$ '),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _message,
                  maxLength: 200,
                  decoration: const InputDecoration(labelText: 'Message (optional)'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Anonymous'),
                  value: _anonymous,
                  onChanged: (v) => setState(() => _anonymous = v),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                FilledButton(onPressed: _sending ? null : _send, child: const Text('Send')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

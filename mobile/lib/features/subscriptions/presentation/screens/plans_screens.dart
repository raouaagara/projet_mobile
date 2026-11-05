import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/plan_advisor.dart';
import '../../../../core/theme/brand.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../data/models/subscription_models.dart';
import '../../subscription_paths.dart';
import '../format.dart';
import '../subscription_providers.dart';

/// Icon and color of a plan, so each one is recognizable.
(IconData, Color) planStyle(PlanType type) => switch (type) {
  PlanType.base => (Icons.rocket_launch_outlined, AppAccent.blue),
  PlanType.premium => (Icons.workspace_premium_outlined, AppAccent.green),
  PlanType.enterprise => (Icons.business_center_outlined, AppAccent.purple),
  PlanType.unknown => (Icons.card_membership_outlined, AppAccent.grey),
};

/// A green gradient card, like the wallet's.
class GreenCard extends StatelessWidget {
  const GreenCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
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
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round white-on-green icon for [GreenCard]s.
class GreenCardIcon extends StatelessWidget {
  const GreenCardIcon(this.icon, {super.key, this.size = 44});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2)),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}

// ── Plans ──────────────────────────────────────────────────────────

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeSubscriptionProvider).value;
    final aiPick = ref.watch(planAdviceProvider)?.value?.planId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        actions: [TextButton(onPressed: () => context.push(SubscriptionPaths.compare), child: const Text('Compare'))],
      ),
      body: AsyncValueView(
        value: ref.watch(plansProvider),
        onRetry: () => ref.invalidate(plansProvider),
        data: (plans) => RefreshIndicator(
          onRefresh: () =>
              Future.wait([ref.refresh(plansProvider.future), ref.refresh(activeSubscriptionProvider.future)]),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (active != null) ...[_CurrentPlanCard(subscription: active), const SizedBox(height: 16)],
              const PlanAdvisorCard(),
              const SizedBox(height: 16),
              for (final plan in plans)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PlanCard(
                    plan: plan,
                    current: active?.plan.id == plan.id,
                    // The AI's pick, once asked; the popular plan otherwise.
                    highlighted: aiPick == null ? plan.type == PlanType.premium : aiPick == plan.id,
                    aiPick: aiPick == plan.id,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.subscription});

  final UserSubscription subscription;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final days = subscription.daysLeft();
    return GreenCard(
      onTap: () => context.push(SubscriptionPaths.mine),
      child: Row(
        children: [
          const GreenCardIcon(Icons.workspace_premium_outlined, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are on ${subscription.plan.name}',
                  style: text.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subscription.endDate == null
                      ? 'Active'
                      : 'Until ${day(subscription.endDate!)}${days != null && days <= 7 ? ' · $days day${days == 1 ? '' : 's'} left' : ''}',
                  style: text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.current, required this.highlighted, this.aiPick = false});

  final SubscriptionPlan plan;
  final bool current;
  final bool highlighted;

  /// The plan the AI advised.
  final bool aiPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (icon, color) = planStyle(plan.type);
    void choose() => context.push(SubscriptionPaths.checkout(plan.id));
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: highlighted ? colors.primary : colors.outlineVariant, width: highlighted ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBubble(icon: icon, color: color, size: 46, solid: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(plan.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ),
                if (highlighted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: aiPick ? AppAccent.purple : AppAccent.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(aiPick ? Icons.auto_awesome : Icons.local_fire_department, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          aiPick ? 'AI pick' : 'Popular',
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
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: money(plan.price),
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: colors.primary),
                  ),
                  TextSpan(
                    text: ' / ${plan.period}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if ((plan.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(plan.description!, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
            ],
            const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1)),
            for (final benefit in plan.benefits)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const IconBubble(icon: Icons.check_rounded, color: AppAccent.green, size: 22, solid: true),
                    const SizedBox(width: 10),
                    Expanded(child: Text(benefit)),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  IconBubble(
                    icon: plan.hasAiCvAccess ? Icons.auto_awesome : Icons.block,
                    color: plan.hasAiCvAccess ? AppAccent.purple : AppAccent.grey,
                    size: 22,
                    solid: true,
                  ),
                  const SizedBox(width: 10),
                  Text(plan.aiLabel),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: current
                  ? FilledButton.tonal(onPressed: choose, child: const Text('Current plan · Renew'))
                  : highlighted
                  ? FilledButton(onPressed: choose, child: Text('Choose ${plan.name}'))
                  : OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      onPressed: choose,
                      child: Text('Choose ${plan.name}'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compare ────────────────────────────────────────────────────────

class ComparePlansScreen extends ConsumerWidget {
  const ComparePlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compare plans')),
      body: AsyncValueView(
        value: ref.watch(plansProvider),
        onRetry: () => ref.invalidate(plansProvider),
        data: (plans) {
          final theme = Theme.of(context);
          // Every benefit of every plan, in order of appearance.
          final features = <String>{for (final plan in plans) ...plan.benefits}.toList();
          Widget cell(Widget child) => Padding(
            padding: const EdgeInsets.all(10),
            child: Center(child: child),
          );
          Widget label(String text) => Padding(
            padding: const EdgeInsets.all(10),
            child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Table(
                  columnWidths: const {0: FlexColumnWidth(2)},
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: TableBorder(horizontalInside: BorderSide(color: theme.colorScheme.outlineVariant)),
                  children: [
                    TableRow(
                      children: [
                        const SizedBox(),
                        for (final plan in plans)
                          cell(
                            Column(
                              children: [
                                IconBubble(
                                  icon: planStyle(plan.type).$1,
                                  color: planStyle(plan.type).$2,
                                  size: 34,
                                  solid: true,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  plan.name,
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    TableRow(
                      children: [
                        label('Price'),
                        for (final plan in plans)
                          cell(
                            Text(
                              '${money(plan.price)}\n/${plan.period}',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                            ),
                          ),
                      ],
                    ),
                    TableRow(
                      children: [
                        label('AI tools'),
                        for (final plan in plans)
                          cell(
                            Text(
                              !plan.hasAiCvAccess
                                  ? '—'
                                  : (plan.aiCvLimit == null ? 'Unlimited' : '${plan.aiCvLimit}/mo'),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                    for (final feature in features)
                      TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(10), child: Text(feature)),
                          for (final plan in plans)
                            cell(
                              plan.benefits.contains(feature)
                                  ? const Icon(Icons.check_circle, color: AppAccent.green, semanticLabel: 'Included')
                                  : Icon(Icons.remove, color: theme.colorScheme.outline, semanticLabel: 'Not included'),
                            ),
                        ],
                      ),
                    TableRow(
                      children: [
                        const SizedBox(),
                        for (final plan in plans)
                          cell(
                            TextButton(
                              onPressed: () => context.push(SubscriptionPaths.checkout(plan.id)),
                              child: const Text('Choose'),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── My subscription ────────────────────────────────────────────────

class MySubscriptionScreen extends ConsumerWidget {
  const MySubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('My subscription')),
      body: AsyncValueView(
        value: ref.watch(subscriptionHistoryProvider),
        onRetry: () => ref.invalidate(subscriptionHistoryProvider),
        data: (history) {
          final active = history.where((s) => s.status == SubscriptionStatus.active).firstOrNull;
          final payments = [
            for (final sub in history)
              for (final payment in sub.payments) (plan: sub.plan.name, payment: payment),
          ]..sort((a, b) => (b.payment.paidAt ?? DateTime(0)).compareTo(a.payment.paidAt ?? DateTime(0)));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (active == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        IconBubble(icon: Icons.workspace_premium_outlined, color: theme.colorScheme.primary, size: 72),
                        const SizedBox(height: 14),
                        Text('No active plan', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          'Pick a plan to get more proposals and the AI tools.',
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: () => context.go(SubscriptionPaths.plans), child: const Text('Plans')),
                      ],
                    ),
                  ),
                )
              else
                GreenCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const GreenCardIcon(Icons.workspace_premium_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              active.plan.name,
                              style: text.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${money(active.plan.price)} / ${active.plan.period} · ${active.plan.aiLabel}',
                        style: text.bodyMedium?.copyWith(color: Colors.white),
                      ),
                      if (active.startDate != null)
                        Text(
                          'Started ${day(active.startDate!)}',
                          style: text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                        ),
                      if (active.endDate != null)
                        Text(
                          'Active until ${day(active.endDate!)} (${active.daysLeft()} days left)',
                          style: text.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                                backgroundColor: Colors.white,
                                foregroundColor: Brand.darkGreen,
                              ),
                              onPressed: () => context.push(SubscriptionPaths.checkout(active.plan.id)),
                              child: const Text('Renew'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white70),
                              ),
                              onPressed: () => context.go(SubscriptionPaths.plans),
                              child: const Text('Change plan'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Payments',
                child: payments.isEmpty
                    ? Text('No payment yet.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
                    : Column(
                        children: [
                          for (final (i, entry) in payments.indexed) ...[
                            if (i > 0) const Divider(height: 1, indent: 56),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const IconBubble(icon: Icons.receipt_long_outlined, color: AppAccent.blue),
                              title: Text(
                                '${entry.plan} · ${money(entry.payment.amount)}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                [
                                  entry.payment.methodLabel,
                                  if (entry.payment.paidAt != null) day(entry.payment.paidAt!),
                                  if (entry.payment.invoiceRef != null) entry.payment.invoiceRef!,
                                ].join(' · '),
                              ),
                              trailing: entry.payment.status == null
                                  ? null
                                  : Text(
                                      entry.payment.status!,
                                      style: text.labelSmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'History',
                child: Column(
                  children: [
                    for (final sub in history)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: IconBubble(
                          icon: planStyle(sub.plan.type).$1,
                          color: planStyle(sub.plan.type).$2,
                          size: 40,
                        ),
                        title: Text(sub.plan.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          [
                            if (sub.startDate != null) day(sub.startDate!),
                            if (sub.endDate != null) day(sub.endDate!),
                          ].join(' – '),
                        ),
                        trailing: PillTag(
                          sub.status.label,
                          color: sub.status == SubscriptionStatus.active ? AppAccent.green : AppAccent.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

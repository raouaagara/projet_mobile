import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../contracts/data/models/contract.dart';
import '../../../contracts/data/models/payment_models.dart';
import '../../../contracts/presentation/contract_providers.dart';
import '../../../profile/data/skill_test_repository.dart';
import '../../../projects/data/models/project_enums.dart';
import '../../../projects/presentation/project_providers.dart';
import '../../data/subscription_repository.dart';

/// The AI's plan advice for me, once asked (null: not asked yet). The plans list reads it to mark its pick.
final planAdviceProvider = NotifierProvider<PlanAdviceController, AsyncValue<PlanAdvice>?>(PlanAdviceController.new);

class PlanAdviceController extends Notifier<AsyncValue<PlanAdvice>?> {
  @override
  AsyncValue<PlanAdvice>? build() => null;

  /// Gathers my activity from the other modules (each one optional), then asks the AI.
  Future<void> find() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref.read(authControllerProvider.future);
      if (session == null) throw const ApiException('Log in first.');
      Future<T?> maybe<T>(Future<T> Function() load) async {
        try {
          // A slow or failing module must not block the advice.
          return await load().timeout(const Duration(seconds: 8));
        } on Object {
          return null; // that module is down: the AI gets "unknown"
        }
      }

      final proposals = await maybe(() => ref.read(myProposalsProvider.future));
      final contracts = await maybe(() => ref.read(myContractsProvider.future));
      final transactions = await maybe(() => ref.read(transactionsProvider.future));
      final me = await maybe(() => ref.read(currentUserProvider.future));
      final certificates = await maybe(() => ref.read(certificationsProvider(session.userId).future));
      final monthAgo = DateTime.now().subtract(const Duration(days: 30));

      return ref
          .read(subscriptionRepositoryProvider)
          .advise(
            session.userId,
            PlanActivity(
              proposalsSent: proposals?.length,
              acceptedProposals: proposals?.where((p) => p.status == ProposalStatus.accepted).length,
              activeContracts: contracts?.where((c) => c.status == ContractStatus.active).length,
              completedContracts: contracts?.where((c) => c.status == ContractStatus.completed).length,
              earnedLast30Days: transactions
                  ?.where((t) => t.type == TransactionType.taskPayout && (t.createdAt?.isAfter(monthAgo) ?? false))
                  .fold<double>(0, (sum, t) => sum + t.amount),
              skills: me?.competenceIds.length,
              certificates: certificates?.where((c) => c.passed).length,
            ),
          );
    });
  }
}

/// "Which plan fits me?": a tinted AI block on the plans page.
class PlanAdvisorCard extends ConsumerWidget {
  const PlanAdvisorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final advice = ref.watch(planAdviceProvider);
    final result = advice?.value;

    final List<Widget> body;
    if (result == null) {
      body = [
        Text('Which plan fits me?', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(
          'The AI looks at your proposals, contracts and earnings, and tells you honestly if a plan is worth it.',
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        const SizedBox(height: 12),
        AiButton(
          label: 'Find my plan',
          busy: advice?.isLoading ?? false,
          onPressed: () => ref.read(planAdviceProvider.notifier).find(),
        ),
        if (advice?.hasError ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              ApiException.from(advice!.error!).message,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ),
      ];
    } else {
      body = [
        Text(
          result.planName ?? 'Stay free for now',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(result.headline, style: theme.textTheme.bodyLarge?.copyWith(height: 1.4)),
        const SizedBox(height: 8),
        for (final reason in result.reasons)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.check, size: 16, color: AppAccent.purple),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(reason, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4))),
              ],
            ),
          ),
        if (result.worthIt.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(result.worthIt, style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.4)),
        ],
      ];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppAccent.purple.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.auto_awesome, color: AppAccent.purple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: body),
          ),
        ],
      ),
    );
  }
}

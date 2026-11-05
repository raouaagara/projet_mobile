import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_paths.dart';
import '../../shared/widgets/async_value_view.dart';
import 'presentation/screens/checkout_screen.dart';
import 'presentation/screens/plans_screens.dart';
import 'presentation/screens/referral_screens.dart';
import 'presentation/screens/rewards_screen.dart';

// Module 5 – Subscriptions, Rewards & Referral (branch: feature/subscriptions-rewards)
// Freelancers only (AppPaths.freelancerOnly). Paths are listed in subscription_paths.dart.

final subscriptionsRoutes = <RouteBase>[
  GoRoute(
    path: AppPaths.subscriptions,
    builder: (context, state) => const PlansScreen(),
    routes: [
      GoRoute(path: 'compare', builder: (context, state) => const ComparePlansScreen()),
      GoRoute(path: 'mine', builder: (context, state) => const MySubscriptionScreen()),
      GoRoute(
        path: 'checkout/:planId',
        builder: (context, state) {
          final planId = int.tryParse(state.pathParameters['planId']!);
          if (planId == null) return const _InvalidLink();
          return CheckoutScreen(planId: planId, initialCode: state.uri.queryParameters['code']);
        },
      ),
    ],
  ),
  GoRoute(path: AppPaths.rewards, builder: (context, state) => const RewardsScreen()),
  GoRoute(
    path: AppPaths.referral,
    builder: (context, state) => const ReferralScreen(),
    routes: [GoRoute(path: 'wallet', builder: (context, state) => const RewardWalletScreen())],
  ),
];

class _InvalidLink extends StatelessWidget {
  const _InvalidLink();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: const ErrorView(message: 'This link is not valid.'),
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_paths.dart';
import '../../shared/widgets/async_value_view.dart';
import 'presentation/screens/contract_details_screen.dart';
import 'presentation/screens/contracts_screen.dart';
import 'presentation/screens/create_contract_screen.dart';
import 'presentation/screens/disputes_screen.dart';
import 'presentation/screens/sign_contract_screen.dart';
import 'presentation/screens/wallet_screen.dart';

// Module 3 – Contracts & Payments (branch: feature/contracts-payments)
// Paths are listed in contract_paths.dart. Static paths must come before ':contractId'.

/// Root of the second bottom tab.
final contractsTab = GoRoute(
  path: AppPaths.contracts,
  builder: (context, state) => const ContractsScreen(),
);

/// Full-screen pages, above the bottom bar.
final contractsRoutes = <RouteBase>[
  GoRoute(path: AppPaths.wallet, builder: (context, state) => const WalletScreen()),
  GoRoute(path: '${AppPaths.contracts}/disputes', builder: (context, state) => const DisputesScreen()),
  GoRoute(
    path: '${AppPaths.contracts}/new/:proposalId',
    builder: (context, state) {
      final id = int.tryParse(state.pathParameters['proposalId']!);
      return id == null ? const _InvalidLink() : CreateContractScreen(proposalId: id);
    },
  ),
  GoRoute(
    path: '${AppPaths.contracts}/:contractId',
    builder: (context, state) => _withId(state, (id) => ContractDetailsScreen(contractId: id)),
    routes: [
      GoRoute(path: 'sign', builder: (context, state) => _withId(state, (id) => SignContractScreen(contractId: id))),
    ],
  ),
];

Widget _withId(GoRouterState state, Widget Function(int id) page) {
  final id = int.tryParse(state.pathParameters['contractId']!);
  return id == null ? const _InvalidLink() : page(id);
}

class _InvalidLink extends StatelessWidget {
  const _InvalidLink();

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(), body: const ErrorView(message: 'This link is not valid.'));
}

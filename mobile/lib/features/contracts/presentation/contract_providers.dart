import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/contract_repository.dart';
import '../data/models/contract.dart';
import '../data/models/payment_models.dart';
import '../data/payment_repository.dart';

// Derived values are plain `Provider<AsyncValue>`s so they update in place, without a loading flash.

// ── Contracts ──────────────────────────────────────────────────────

/// The logged-in user's contracts (as client or freelancer), newest first.
final myContractsProvider =
    AsyncNotifierProvider<MyContractsController, List<Contract>>(MyContractsController.new);

class MyContractsController extends AsyncNotifier<List<Contract>> {
  ContractRepository get _contracts => ref.read(contractRepositoryProvider);

  @override
  Future<List<Contract>> build() async {
    final session = await ref.watch(authControllerProvider.future);
    if (session == null) return [];
    final repository = ref.watch(contractRepositoryProvider);
    return session.isClient
        ? repository.fetchForClient(session.userId)
        : repository.fetchForFreelancer(session.userId);
  }

  /// Inserts or replaces [contract] in the loaded list.
  void put(Contract contract) {
    final contracts = state.value;
    if (contracts == null) return;
    final index = contracts.indexWhere((c) => c.id == contract.id);
    state = AsyncData(index == -1 ? [contract, ...contracts] : ([...contracts]..[index] = contract));
  }

  /// Money moved: refresh what shows it.
  void _paymentsChanged(int contractId) {
    ref.invalidate(escrowProvider(contractId));
    ref.invalidate(walletProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(myEscrowsProvider);
  }

  Future<Contract> create({
    required int proposalId,
    required int clientId,
    required String clientName,
    required String clientSignature,
    required DateTime startDate,
    required String terms,
  }) async {
    final contract = await _contracts.createFromProposal(
      proposalId: proposalId,
      clientId: clientId,
      clientName: clientName,
      clientSignature: clientSignature,
      startDate: startDate,
      terms: terms,
    );
    put(contract);
    return contract;
  }

  Future<Contract> sign(Contract contract, {required String signature, required String freelancerName}) async {
    final signed = await _contracts.sign(contract.id, signature: signature, freelancerName: freelancerName);
    put(signed);
    _paymentsChanged(contract.id);
    return signed;
  }

  Future<Contract> reject(Contract contract) async {
    final rejected = await _contracts.reject(contract.id);
    put(rejected);
    return rejected;
  }

  /// Client approves the work: pays the freelancer, the contract becomes completed.
  Future<Contract> release(Contract contract, {required int clientId}) async {
    await ref.read(paymentRepositoryProvider).release(contract.id, clientId: clientId);
    final completed = await _contracts.fetch(contract.id);
    put(completed);
    _paymentsChanged(contract.id);
    return completed;
  }
}

/// One contract: from the loaded list, or from the server if it isn't there.
final contractProvider = Provider.autoDispose.family<AsyncValue<Contract>, int>((ref, id) {
  final all = ref.watch(myContractsProvider);
  final cached = all.value?.where((c) => c.id == id).firstOrNull;
  if (cached != null) return AsyncData(cached);
  if (all.isLoading) return const AsyncLoading();
  return ref.watch(_remoteContractProvider(id));
});

final _remoteContractProvider = FutureProvider.autoDispose.family<Contract, int>(
    (ref, id) => ref.watch(contractRepositoryProvider).fetch(id));

enum ContractFilter {
  all('All'),
  toSign('To sign'),
  active('In progress'),
  completed('Completed'),
  other('Other');

  const ContractFilter(this.label);

  final String label;

  bool matches(ContractStatus status) => switch (this) {
        ContractFilter.all => true,
        ContractFilter.toSign => status == ContractStatus.sent || status == ContractStatus.draft,
        ContractFilter.active => status == ContractStatus.active,
        ContractFilter.completed => status == ContractStatus.completed,
        ContractFilter.other => const [
            ContractStatus.rejected,
            ContractStatus.cancelled,
            ContractStatus.closed,
            ContractStatus.unknown,
          ].contains(status),
      };
}

// ── Escrow & disputes ──────────────────────────────────────────────

/// The escrow of a contract; null until the freelancer signs.
final escrowProvider = FutureProvider.autoDispose.family<Escrow?, int>(
    (ref, contractId) => ref.watch(paymentRepositoryProvider).fetchEscrow(contractId));

final myEscrowsProvider = FutureProvider<List<Escrow>>((ref) async {
  final session = await ref.watch(authControllerProvider.future);
  if (session == null) return [];
  return ref.watch(paymentRepositoryProvider).fetchEscrows(session.userId, freelancer: session.isFreelancer);
});

final myDisputesProvider = FutureProvider<List<Dispute>>((ref) async {
  final session = await ref.watch(authControllerProvider.future);
  if (session == null) return [];
  return ref.watch(paymentRepositoryProvider).fetchDisputes(session.userId);
});

/// The latest dispute on a contract, if any.
final contractDisputeProvider = Provider.autoDispose.family<AsyncValue<Dispute?>, int>((ref, contractId) {
  return ref
      .watch(myDisputesProvider)
      .whenData((disputes) => disputes.where((d) => d.contractId == contractId).firstOrNull);
});

/// Opens a dispute: the escrow is frozen until an admin decides.
Future<Dispute> raiseDispute(WidgetRef ref, {required int contractId, required String reason}) async {
  final userId = ref.read(authControllerProvider).value!.userId;
  final dispute =
      await ref.read(paymentRepositoryProvider).raiseDispute(contractId: contractId, userId: userId, reason: reason);
  ref.invalidate(myDisputesProvider);
  ref.invalidate(escrowProvider(contractId));
  return dispute;
}

// ── Wallet ─────────────────────────────────────────────────────────

/// The logged-in user's wallet; null if they don't have one yet.
final walletProvider = AsyncNotifierProvider<WalletController, Wallet?>(WalletController.new);

class WalletController extends AsyncNotifier<Wallet?> {
  PaymentRepository get _payments => ref.read(paymentRepositoryProvider);

  @override
  Future<Wallet?> build() async {
    final session = await ref.watch(authControllerProvider.future);
    if (session == null) return null;
    return ref.watch(paymentRepositoryProvider).fetchWallet(session.userId);
  }

  Future<void> create() async {
    final session = ref.read(authControllerProvider).value!;
    state = AsyncData(await _payments.createWallet(session.userId, freelancer: session.isFreelancer));
  }

  Future<void> topUp(double amount) async {
    final session = ref.read(authControllerProvider).value!;
    state = AsyncData(await _payments.topUp(session.userId, amount));
    ref.invalidate(transactionsProvider);
  }
}

final transactionsProvider = FutureProvider<List<WalletTransaction>>((ref) async {
  final session = await ref.watch(authControllerProvider.future);
  if (session == null) return [];
  return ref.watch(paymentRepositoryProvider).fetchTransactions(session.userId);
});

// ── People ─────────────────────────────────────────────────────────

/// The name to write on a contract: the profile's full name (waiting for it if the
/// profile isn't loaded yet), or the email if it can't be loaded.
Future<String> myContractName(WidgetRef ref) async {
  final session = ref.read(authControllerProvider).value!;
  try {
    final user = await ref.read(currentUserProvider.future);
    if (user != null && user.fullName.isNotEmpty) return user.fullName;
  } on Object {
    // Fall back to the email below.
  }
  return session.email;
}

/// Name and avatar of the other party of a contract.
final contractUserProvider =
    FutureProvider.family<AppUser, int>((ref, id) => ref.watch(authRepositoryProvider).fetchUser(id));

import 'package:catchopp_mobile/core/models/app_user.dart';
import 'package:catchopp_mobile/core/models/user_role.dart';
import 'package:catchopp_mobile/features/auth/domain/auth_session.dart';
import 'package:catchopp_mobile/features/auth/presentation/auth_controller.dart';
import 'package:catchopp_mobile/features/contracts/contracts_routes.dart';
import 'package:catchopp_mobile/features/contracts/data/contract_repository.dart';
import 'package:catchopp_mobile/features/contracts/data/models/contract.dart';
import 'package:catchopp_mobile/features/contracts/data/models/payment_models.dart';
import 'package:catchopp_mobile/features/contracts/data/payment_repository.dart';
import 'package:catchopp_mobile/features/contracts/presentation/contract_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const clientId = 2;
const freelancerId = 7;

Contract contract(int id, {ContractStatus status = ContractStatus.sent, double rate = 1100}) => Contract(
      id: id,
      projectId: 40 + id,
      proposalId: 10 + id,
      projectTitle: 'Project $id',
      rate: rate,
      clientId: clientId,
      freelancerId: freelancerId,
      clientName: 'Karim B',
      freelancerName: status == ContractStatus.sent ? null : 'Sara B',
      startDate: DateTime(2026, 9, 27),
      deadline: DateTime(2026, 10, 30),
      status: status,
      terms: 'Deliver the app.',
      createdAt: DateTime(2026, 9, 26),
    );

Contract _with(Contract c, ContractStatus status, {String? freelancerSignature, String? freelancerName}) => Contract(
      id: c.id,
      projectId: c.projectId,
      proposalId: c.proposalId,
      projectTitle: c.projectTitle,
      rate: c.rate,
      clientId: c.clientId,
      freelancerId: c.freelancerId,
      clientName: c.clientName,
      freelancerName: freelancerName ?? c.freelancerName,
      startDate: c.startDate,
      deadline: c.deadline,
      status: status,
      terms: c.terms,
      clientSignature: c.clientSignature,
      freelancerSignature: freelancerSignature ?? c.freelancerSignature,
      createdAt: c.createdAt,
    );

/// Answers a bit later, like a real network.
Future<void> _latency() => Future<void>.delayed(const Duration(milliseconds: 30));

class FakeContractRepository extends ContractRepository {
  FakeContractRepository({List<Contract>? contracts, this.proposal, this.existingForProposal})
      : contracts = contracts ?? [],
        super(Dio());

  final List<Contract> contracts;
  final ProposalSummary? proposal;
  final Contract? existingForProposal;
  String? signedWith;
  Map<String, Object>? created;

  @override
  Future<List<Contract>> fetchForClient(int clientId) async => [...contracts];

  @override
  Future<List<Contract>> fetchForFreelancer(int freelancerId) async => [...contracts];

  @override
  Future<Contract> fetch(int id) async => contracts.firstWhere((c) => c.id == id);

  @override
  Future<Contract?> fetchByProposal(int proposalId) async => existingForProposal;

  @override
  Future<ProposalSummary> fetchProposal(int proposalId) async => proposal!;

  @override
  Future<Contract> sign(int id, {required String signature, required String freelancerName}) async {
    await _latency();
    signedWith = freelancerName;
    final i = contracts.indexWhere((c) => c.id == id);
    return contracts[i] =
        _with(contracts[i], ContractStatus.active, freelancerSignature: signature, freelancerName: freelancerName);
  }

  @override
  Future<Contract> reject(int id) async {
    await _latency();
    final i = contracts.indexWhere((c) => c.id == id);
    return contracts[i] = _with(contracts[i], ContractStatus.rejected);
  }

  // ── AI ──
  String? termsNotes;
  String? disputeRole;

  @override
  Future<String> draftTerms({required int proposalId, required DateTime startDate, String? notes}) async {
    await _latency();
    termsNotes = notes;
    return '1 Scope and deliverables\nThe freelancer builds the gym app.';
  }

  @override
  Future<ContractExplanation> explain(int contractId, {required String role}) async {
    await _latency();
    return const ContractExplanation(
      summary: [r'You deliver the app by October 30 for $1,100.'],
      check: ['How many rounds of changes are included.'],
    );
  }

  @override
  Future<String> draftDispute({required int contractId, required String role, required String text}) async {
    await _latency();
    disputeRole = role;
    return 'The app was due on October 30 and was not delivered. I ask for a refund.';
  }

  /// The payment service completes the contract when the client releases the escrow.
  void complete(int id) {
    final i = contracts.indexWhere((c) => c.id == id);
    contracts[i] = _with(contracts[i], ContractStatus.completed);
  }
}

class FakePaymentRepository extends PaymentRepository {
  FakePaymentRepository({this.wallet, this.contracts, List<Escrow>? escrows, List<WalletTransaction>? transactions})
      : escrows = escrows ?? [],
        transactions = transactions ?? [],
        super(Dio());

  Wallet? wallet;
  final FakeContractRepository? contracts;
  final List<Escrow> escrows;
  final List<WalletTransaction> transactions;
  final disputes = <Dispute>[];
  int? releasedContract;

  @override
  Future<Wallet?> fetchWallet(int userId) async => wallet;

  @override
  Future<Wallet> createWallet(int userId, {required bool freelancer}) async =>
      wallet = Wallet(id: 1, userId: userId, balance: 0, walletType: freelancer ? WalletType.freelancer : WalletType.client);

  @override
  Future<Wallet> topUp(int userId, double amount) async {
    await _latency();
    wallet = Wallet(id: wallet!.id, userId: userId, balance: wallet!.balance + amount, walletType: wallet!.walletType);
    transactions.insert(0, WalletTransaction(id: 99, type: TransactionType.topUp, amount: amount, toUserId: userId));
    return wallet!;
  }

  @override
  Future<List<WalletTransaction>> fetchTransactions(int userId) async => [...transactions];

  @override
  Future<Escrow?> fetchEscrow(int contractId) async => escrows.where((e) => e.contractId == contractId).firstOrNull;

  @override
  Future<List<Escrow>> fetchEscrows(int userId, {required bool freelancer}) async => [...escrows];

  @override
  Future<Escrow> release(int contractId, {required int clientId}) async {
    await _latency();
    releasedContract = contractId;
    contracts?.complete(contractId);
    final i = escrows.indexWhere((e) => e.contractId == contractId);
    final e = escrows[i];
    return escrows[i] = Escrow(
        id: e.id, contractId: contractId, totalAmount: e.totalAmount, releasedAmount: e.totalAmount,
        status: EscrowStatus.released);
  }

  @override
  Future<Dispute> raiseDispute({required int contractId, required int userId, required String reason}) async {
    await _latency();
    final dispute = Dispute(id: 1, contractId: contractId, reason: reason, raisedByUserId: userId);
    disputes.add(dispute);
    return dispute;
  }

  @override
  Future<List<Dispute>> fetchDisputes(int userId) async => [...disputes];
}

class _LoggedIn extends AuthController {
  _LoggedIn(this.role);

  final UserRole role;

  @override
  Future<AuthSession?> build() async => AuthSession(
        token: 't',
        userId: role == UserRole.client ? clientId : freelancerId,
        email: 'me@mail.com',
        role: role,
        expiresAt: DateTime(2100),
      );
}

AppUser _user(int id) => AppUser(
    id: id,
    firstName: id == freelancerId ? 'Sara' : 'Karim',
    lastName: 'B',
    email: 'u$id@mail.com',
    role: id == freelancerId ? UserRole.freelancer : UserRole.client);

/// Module 3's pages with a fake backend, logged in as [role].
Future<void> pumpContractsApp(
  WidgetTester tester, {
  required UserRole role,
  required FakeContractRepository contracts,
  FakePaymentRepository? payments,
  String location = '/contracts',
}) async {
  final router = GoRouter(initialLocation: location, routes: [contractsTab, ...contractsRoutes]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => _LoggedIn(role)),
      currentUserProvider.overrideWith((ref) async => _user(role == UserRole.client ? clientId : freelancerId)),
      contractRepositoryProvider.overrideWithValue(contracts),
      paymentRepositoryProvider.overrideWithValue(payments ?? FakePaymentRepository(contracts: contracts)),
      contractUserProvider.overrideWith((ref, id) async => _user(id)),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

/// Scrolls the page until [finder] is on screen, then taps it.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Scrolls the page until [finder] is built and on screen (fails if it never appears).
/// A negative [delta] scrolls up.
Future<void> scrollTo(WidgetTester tester, Finder finder, {double delta = 200}) async {
  await tester.scrollUntilVisible(finder, delta, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder, findsOneWidget);
}

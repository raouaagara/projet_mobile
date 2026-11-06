import 'package:catchopp_mobile/features/contracts/data/contract_repository.dart';
import 'package:catchopp_mobile/features/contracts/data/models/contract.dart';
import 'package:catchopp_mobile/features/contracts/data/models/payment_models.dart';
import 'package:catchopp_mobile/features/contracts/presentation/contract_providers.dart';
import 'package:catchopp_mobile/features/contracts/presentation/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Contract reads the backend JSON (embedded proposal and project)', () {
    // Shape of GET /Contract/1 on the real backend (trimmed).
    final c = Contract.fromJson({
      'id': 1,
      'proposal': {
        'id': 1,
        'bidAmount': 1100.0,
        'project': {'id': 1, 'title': 'Flutter app', 'jobType': 'HOURLY', 'image': null},
      },
      'projectId': 1,
      'freelancerId': 1,
      'clientId': 2,
      'projectTitle': 'Flutter app for a restaurant',
      'freelancerName': null,
      'clientName': 'Test client',
      'rate': 1100.0,
      'startDate': '2026-09-27',
      'deadline': '2026-10-30',
      'status': 'SENT',
      'terms': '1. Scope',
      'clientSignature': 'data:image/png;base64,AA==',
      'freelancerSignature': null,
      'createdAt': '2026-09-26T13:56:15.123',
    });
    expect(c.proposalId, 1);
    expect(c.isHourly, isTrue);
    expect(c.status, ContractStatus.sent);
    expect(c.rate, 1100);
    expect(c.durationDays, 33);
    expect(c.otherPartyOf(2), 1);
    expect(c.otherPartyOf(1), 2);
    expect(c.createdAt, DateTime.parse('2026-09-26T13:56:15.123'));
    expect(Contract.fromJson(const {'id': 2, 'status': 'ARCHIVED'}).status, ContractStatus.unknown);
  });

  test('Escrow and transactions read the nested wallets', () {
    final escrow = Escrow.fromJson({
      'id': 1,
      'contractId': 1,
      'clientWallet': {'id': 1, 'userId': 2, 'walletType': 'CLIENT', 'balance': 3900.0},
      'freelancerWallet': {'id': 2, 'userId': 1, 'walletType': 'FREELANCER', 'balance': 0},
      'totalAmount': 1100.0,
      'releasedAmount': 100.0,
      'remainingAmount': 1000.0,
      'status': 'PARTIAL_PAID',
      'lockedAt': '2026-09-26T13:56:25',
    });
    expect(escrow.clientUserId, 2);
    expect(escrow.freelancerUserId, 1);
    expect(escrow.remainingAmount, 1000);
    expect(escrow.status, EscrowStatus.partialPaid);
    expect(escrow.status.isClosed, isFalse);

    final lock = WalletTransaction.fromJson({
      'id': 2,
      'fromWallet': {'userId': 2},
      'toWallet': {'userId': 0},
      'type': 'ESCROW_LOCK',
      'amount': 1100.0,
      'description': 'Payment locked in escrow - Contract #1',
      'referenceId': 1,
      'createdAt': '2026-09-26T13:56:25',
    });
    expect(lock.type, TransactionType.escrowLock);
    expect(lock.isIncomingFor(2), isFalse);
    final topUp = WalletTransaction.fromJson(const {'id': 1, 'toWallet': {'userId': 2}, 'type': 'TOP_UP', 'amount': 5000});
    expect(topUp.isIncomingFor(2), isTrue);
    expect(WalletTransaction.fromJson(const {'id': 3, 'type': 'BONUS'}).type, TransactionType.unknown);
  });

  test('Wallet and dispute', () {
    final wallet = Wallet.fromJson(const {
      'id': 1, 'userId': 2, 'walletType': 'CLIENT', 'balance': 3878.0, 'currency': 'USD', 'active': true,
    });
    expect(wallet.balance, 3878);
    expect(wallet.walletType, WalletType.client);

    final dispute = Dispute.fromJson(const {
      'id': 1, 'contractId': 2, 'raisedByUserId': 1, 'againstUserId': 2,
      'reason': 'Scope changed', 'status': 'IN_REVIEW', 'createdAt': '2026-09-26T13:56:47',
    });
    expect(dispute.status, DisputeStatus.inReview);
    expect(dispute.status.isOpen, isTrue);
    expect(DisputeStatus.resolvedClient.isOpen, isFalse);
  });

  test('ProposalSummary reads the proposal and its project', () {
    final p = ProposalSummary.fromJson(const {
      'id': 3, 'bidAmount': 2300.0, 'estimationEndDate': '2026-11-15', 'status': 'ACCEPTED', 'freelancerId': 1,
      'project': {'id': 3, 'title': 'E-commerce website', 'jobType': 'FIXED_PRICE'},
    });
    expect(p.isAccepted, isTrue);
    expect(p.projectTitle, 'E-commerce website');
    expect(p.estimationEndDate, DateTime(2026, 11, 15));
  });

  test('filters and money', () {
    expect(ContractFilter.toSign.matches(ContractStatus.sent), isTrue);
    expect(ContractFilter.active.matches(ContractStatus.sent), isFalse);
    expect(ContractFilter.other.matches(ContractStatus.rejected), isTrue);
    expect(ContractFilter.all.matches(ContractStatus.completed), isTrue);
    expect(formatMoney(1100), r'$1,100');
    expect(formatMoney(22.5), r'$22.50');
  });
}

import 'package:catchopp_mobile/core/models/user_role.dart';
import 'package:catchopp_mobile/features/contracts/data/contract_repository.dart';
import 'package:catchopp_mobile/features/contracts/data/models/contract.dart';
import 'package:catchopp_mobile/features/contracts/data/models/payment_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signature/signature.dart';

import 'fakes.dart';

void main() {
  group('freelancer', () {
    testWidgets('sees the contract to sign first, and signs it', (tester) async {
      final contracts = FakeContractRepository(
        contracts: [
          contract(1, status: ContractStatus.sent),
          contract(2, status: ContractStatus.completed),
        ],
      );
      await pumpContractsApp(tester, role: UserRole.freelancer, contracts: contracts);

      expect(find.text('To sign (1)'), findsOneWidget);
      expect(find.text('Sign now'), findsOneWidget);
      await tester.tap(find.text('Project 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review & sign'));
      await tester.pumpAndSettle();

      // The AI explains the contract before signing.
      await scrollAndTap(tester, find.text('Explain this contract'));
      expect(find.text('In short'), findsOneWidget);
      expect(find.text(r'You deliver the app by October 30 for $1,100.'), findsOneWidget);
      expect(find.text('How many rounds of changes are included.'), findsOneWidget);

      // The button stays off until the terms are accepted; no signature → error.
      final signButton = find.widgetWithText(FilledButton, 'Sign the contract');
      await scrollAndTap(tester, find.text('I have read the terms and I agree to them'));
      await scrollAndTap(tester, signButton);
      expect(find.text('Sign in the box above'), findsOneWidget);
      expect(contracts.signedWith, isNull);

      // Draw, then sign (exporting the PNG needs real async work).
      await tester.ensureVisible(find.byType(Signature));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Signature), const Offset(120, 10));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(signButton);
        for (var i = 0; i < 20 && contracts.signedWith == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
      });
      await tester.pumpAndSettle();

      expect(contracts.signedWith, 'Sara B');
      expect(contracts.contracts.first.freelancerSignature, startsWith('data:image/png;base64,'));
      // Back on the contract, now in progress.
      expect(find.text('Contract #1'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);
    });

    testWidgets('can decline a contract', (tester) async {
      final contracts = FakeContractRepository(contracts: [contract(1)]);
      await pumpContractsApp(tester, role: UserRole.freelancer, contracts: contracts, location: '/contracts/1');

      await tester.tap(find.text('Decline'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Decline')));
      await tester.pumpAndSettle();

      expect(contracts.contracts.single.status, ContractStatus.rejected);
      await scrollTo(tester, find.text('Declined by the freelancer')); // in the progress card
    });
  });

  group('client', () {
    testWidgets('approves the work: pays, completes, offers a review', (tester) async {
      final contracts = FakeContractRepository(contracts: [contract(1, status: ContractStatus.active)]);
      final payments = FakePaymentRepository(
        contracts: contracts,
        escrows: [const Escrow(id: 5, contractId: 1, totalAmount: 1100, status: EscrowStatus.locked)],
      );
      await pumpContractsApp(
        tester,
        role: UserRole.client,
        contracts: contracts,
        payments: payments,
        location: '/contracts/1',
      );

      await scrollTo(tester, find.text('Held in escrow'));
      await tester.tap(find.text('Approve & pay'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(r'Pay $1,100'));
      await tester.pumpAndSettle();

      expect(payments.releasedContract, 1);
      expect(find.text('Payment sent'), findsOneWidget);
      await tester.tap(find.text('Leave a review'));
      await tester.pumpAndSettle();
      expect(find.textContaining('module 1'), findsOneWidget); // review form lives in module 1
      expect(find.text('Review the freelancer'), findsOneWidget);
      await scrollTo(tester, find.text('The freelancer received the payment'), delta: -200); // above the payment
      await scrollTo(tester, find.text('Completed'), delta: -200); // status at the top
    });

    testWidgets('reports a problem: the dispute freezes the payment', (tester) async {
      final contracts = FakeContractRepository(contracts: [contract(1, status: ContractStatus.active)]);
      final payments = FakePaymentRepository(
        contracts: contracts,
        escrows: [const Escrow(id: 5, contractId: 1, totalAmount: 1100, status: EscrowStatus.locked)],
      );
      await pumpContractsApp(
        tester,
        role: UserRole.client,
        contracts: contracts,
        payments: payments,
        location: '/contracts/1',
      );

      await tester.tap(find.text('Report a problem'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open a dispute'));
      await tester.pumpAndSettle();
      expect(find.text('Explain the problem in at least 20 characters'), findsOneWidget);

      // The AI makes an angry message clear and factual.
      await tester.enterText(find.byType(TextFormField), 'he never sent anything!!');
      await tester.tap(find.text('Make it clear with AI'));
      await tester.pumpAndSettle();
      expect(contracts.disputeRole, 'CLIENT');
      expect(find.text('The app was due on October 30 and was not delivered. I ask for a refund.'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'The app was never delivered and no news for 2 weeks.');
      await tester.tap(find.text('Open a dispute'));
      await tester.pumpAndSettle();

      expect(payments.disputes.single.reason, startsWith('The app was never delivered'));
      await scrollTo(tester, find.text('Dispute: Open'));
      expect(find.text('Approve & pay'), findsNothing); // an admin decides now
    });

    testWidgets('opening "new contract" twice leads to the existing one', (tester) async {
      final contracts = FakeContractRepository(
        contracts: [contract(1)],
        proposal: const ProposalSummary(id: 11, bidAmount: 1100, status: 'ACCEPTED', freelancerId: freelancerId),
        existingForProposal: contract(1),
      );
      await pumpContractsApp(tester, role: UserRole.client, contracts: contracts, location: '/contracts/new/11');

      expect(find.text('The contract for this proposal was already sent.'), findsOneWidget);
      await tester.tap(find.text('Open the contract'));
      await tester.pumpAndSettle();
      expect(find.text('Contract #1'), findsOneWidget);
      expect(find.text('Waiting for the freelancer to sign.'), findsOneWidget);
    });

    testWidgets('the contract form needs a signature', (tester) async {
      final contracts = FakeContractRepository(
        proposal: const ProposalSummary(
          id: 11,
          bidAmount: 900,
          status: 'ACCEPTED',
          freelancerId: freelancerId,
          projectTitle: 'Gym app',
        ),
      );
      await pumpContractsApp(tester, role: UserRole.client, contracts: contracts, location: '/contracts/new/11');

      expect(find.text('Gym app'), findsOneWidget);
      expect(find.text('Sara B'), findsOneWidget);
      expect(find.textContaining(r'$900'), findsWidgets);
      await scrollAndTap(tester, find.text('Sign & send to the freelancer'));
      expect(find.text('Sign the contract to send it'), findsOneWidget);
      expect(contracts.contracts, isEmpty);

      // The AI writes the terms; the default text isn't sent as the client's notes. Undo restores it.
      await scrollAndTap(tester, find.text('Write the terms with AI'));
      expect(contracts.termsNotes, isNull);
      expect(find.text('1 Scope and deliverables\nThe freelancer builds the gym app.'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.textContaining('1. Scope of work'), findsOneWidget);
    });
  });

  testWidgets('wallet: create it, add money, see the history', (tester) async {
    final payments = FakePaymentRepository();
    await pumpContractsApp(
      tester,
      role: UserRole.client,
      contracts: FakeContractRepository(),
      payments: payments,
      location: '/wallet',
    );

    String balance() => tester.widget<Text>(find.byKey(const ValueKey('wallet-balance'))).data!;
    await tester.tap(find.text('Create my wallet'));
    await tester.pumpAndSettle();
    expect(balance(), r'$0');

    await tester.tap(find.text('Add money'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(r'$1,000'));
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(payments.wallet!.balance, 1000);
    expect(balance(), r'$1,000');
    expect(find.text(r'+$1,000'), findsOneWidget); // history
    expect(find.text('Money added'), findsOneWidget);
  });
}

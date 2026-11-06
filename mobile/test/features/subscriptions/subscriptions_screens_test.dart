import 'package:catchopp_mobile/features/subscriptions/data/models/referral_models.dart';
import 'package:catchopp_mobile/features/subscriptions/data/models/subscription_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  testWidgets('plans: current plan first, then every plan with its price', (tester) async {
    final subscriptions = FakeSubscriptionRepository(
      active: UserSubscription(id: 1, plan: base, status: SubscriptionStatus.active, endDate: DateTime(2026, 10, 26)),
    );
    await pumpSubscriptionsApp(tester, location: '/subscriptions', subscriptions: subscriptions);

    expect(find.text('You are on Base'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Popular'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining(r'$9.99 / month', findRichText: true), findsOneWidget);
    expect(find.text('Popular'), findsOneWidget);
    expect(find.text('Current plan · Renew'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Choose Premium'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('10 AI uses / month'), findsOneWidget);
  });

  testWidgets('plans: the AI advises a plan from my activity and marks it', (tester) async {
    final subscriptions = FakeSubscriptionRepository();
    await pumpSubscriptionsApp(tester, location: '/subscriptions', subscriptions: subscriptions);

    expect(find.text('Which plan fits me?'), findsOneWidget);
    await tester.tap(find.text('Find my plan'));
    await tester.pumpAndSettle();

    expect(subscriptions.advisedWith, isNotNull); // what the app could gather (modules down here: unknown)
    expect(find.text('Premium pays for itself with your activity.'), findsOneWidget);
    expect(find.text('You sent 3 proposals'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('AI pick'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('AI pick'), findsOneWidget);
    expect(find.text('Popular'), findsNothing); // the AI's pick replaces the default highlight
  });

  testWidgets('checkout: promo code, test payment verified by the server, plan activated', (tester) async {
    final subscriptions = FakeSubscriptionRepository(
      codes: [
        code('SPIN20'),
        code('OLD', usedAt: DateTime(2026, 9, 1)),
      ],
    );
    await pumpSubscriptionsApp(tester, location: '/subscriptions/checkout/2', subscriptions: subscriptions);

    expect(find.text('Premium'), findsOneWidget);
    expect(find.text(r'Pay $24.99 with Flouci'), findsOneWidget);
    expect(find.textContaining('OLD'), findsNothing); // used codes aren't offered

    // A code that doesn't work: explained, price unchanged.
    await tester.enterText(find.byType(TextField), 'NOPE');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.text('This promo code was already used or has expired.'), findsOneWidget);

    // One of the user's codes.
    await tester.tap(find.textContaining('SPIN20 ·'));
    await tester.pumpAndSettle();
    expect(find.text(r'−$5.00'), findsOneWidget);
    expect(find.text(r'Pay $19.99 with Flouci'), findsOneWidget);

    await scrollAndTap(tester, find.text(r'Pay $19.99 with Flouci'));
    expect(subscriptions.confirms.single, (planId: 2, promoCode: 'SPIN20', paymentId: 'TEST_1'));
    expect(find.text('Welcome to Premium!'), findsOneWidget);

    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();
    expect(find.text('My subscription'), findsOneWidget); // lands on it
    expect(find.textContaining(r'Premium · $19.99'), findsOneWidget); // the payment
  });

  testWidgets('checkout: a 100% code activates for free without payment', (tester) async {
    final subscriptions = FakeSubscriptionRepository(codes: [code('FREE100', percent: 100)]);
    await pumpSubscriptionsApp(
      tester,
      location: '/subscriptions/checkout/1?code=FREE100',
      subscriptions: subscriptions,
    );

    expect(find.text('Activate for free'), findsOneWidget);
    await scrollAndTap(tester, find.text('Activate for free'));
    expect(subscriptions.confirms.single.paymentId, isNull);
    expect(find.text('Welcome to Base!'), findsOneWidget);
  });

  testWidgets('rewards: spin once a month, the wheel lands on the prize', (tester) async {
    final subscriptions = FakeSubscriptionRepository();
    await pumpSubscriptionsApp(tester, location: '/rewards', subscriptions: subscriptions);

    expect(find.text('No code yet. Spin the wheel to win one!'), findsOneWidget);
    await tester.tap(find.text('Spin'));
    await tester.pumpAndSettle();
    expect(find.text('You won 15% off!'), findsOneWidget);
    expect(find.text('SPINWIN1'), findsOneWidget);

    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.text('Next spin in 12 days'), findsOneWidget);
    expect(find.text('SPINWIN1 · 15% off'), findsOneWidget);
  });

  testWidgets('referral: code, friends, and the own-code refusal', (tester) async {
    final referral = FakeReferralRepository();
    await pumpSubscriptionsApp(tester, location: '/referral', referral: referral);

    expect(find.text('CATCH-7-A1B2C3'), findsOneWidget);
    expect(find.text(r'$5.00'), findsOneWidget); // reward balance
    // "Invited by a friend?" is below the code card and the stats.
    await tester.scrollUntilVisible(find.text('Use'), 200, scrollable: find.byType(Scrollable).first);
    await tester.enterText(find.byType(TextField), 'CATCH-7-A1B2C3');
    await tester.tap(find.text('Use'));
    await tester.pumpAndSettle();
    expect(find.text("You can't use your own referral code."), findsOneWidget);
    expect(referral.usedCodes, isEmpty);

    await tester.scrollUntilVisible(find.text('Karim B'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text(r'+$5.00'), findsOneWidget);
  });

  testWidgets('referral: the AI writes my invite; a suspicious sign-up is being checked', (tester) async {
    final referral = FakeReferralRepository(
      extraReferrals: [Referral(id: 2, referredUserId: 9, status: 'UNDER_REVIEW', referredAt: DateTime(2026, 11, 3))],
    );
    await pumpSubscriptionsApp(tester, location: '/referral', referral: referral);

    await scrollAndTap(tester, find.text('LinkedIn'));
    await scrollAndTap(tester, find.text('Write it'));
    expect(referral.inviteChannel, 'LINKEDIN');
    expect(find.text('Hi! I use Workify for freelance work. Sign up and enter my code CATCH-7-A1B2C3'), findsOneWidget);
    expect(find.text('Write another'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Being checked'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Being checked'), findsOneWidget);
  });

  testWidgets('reward wallet: donate to a member', (tester) async {
    final referral = FakeReferralRepository();
    await pumpSubscriptionsApp(tester, location: '/referral/wallet', referral: referral);

    expect(find.text('Referral bonus'), findsOneWidget);
    await tester.tap(find.text('Donate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Karim B'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '9');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(find.text(r'Between $0.01 and $5.00'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '2');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(referral.donations.single.amount, 2);
    expect(referral.donations.single.recipientId, 2);
  });
}

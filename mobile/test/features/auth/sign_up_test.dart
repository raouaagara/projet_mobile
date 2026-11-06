import 'package:catchopp_mobile/core/models/countries.dart';
import 'package:catchopp_mobile/core/models/user_role.dart';
import 'package:catchopp_mobile/features/auth/presentation/register_screen.dart';
import 'package:catchopp_mobile/features/auth/presentation/role_choice_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openSignUp(WidgetTester tester, LoggedOut auth) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  await pumpWorkify(tester, onboarding: FakeOnboardingStore(done: true), auth: auth);
  await tester.pumpAndSettle();
  await _tap(tester, find.text('Sign up'));
}

void main() {
  test('flags come from the country code', () {
    expect(flagOf('TN'), '🇹🇳');
    expect(countries.map((c) => c.name), contains('Tunisia'));
  });

  testWidgets('sign-up starts by choosing client or freelancer', (tester) async {
    await _openSignUp(tester, LoggedOut());

    expect(find.byType(RoleChoiceScreen), findsOneWidget);
    final button = find.widgetWithText(FilledButton, 'Create an account');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await _tap(tester, find.text("I'm a client"));
    expect(find.text('Join as a client'), findsOneWidget);
    await _tap(tester, find.text("I'm a freelancer"));
    await _tap(tester, find.text('Join as a freelancer'));

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.text('You are joining as a freelancer'), findsOneWidget);
  });

  testWidgets('the form checks the fields and the terms, then signs up with the country', (tester) async {
    final auth = LoggedOut();
    await _openSignUp(tester, auth);
    await _tap(tester, find.text("I'm a client"));
    await _tap(tester, find.text('Join as a client'));

    await _tap(tester, find.text('Create my account'));
    expect(find.text('Required'), findsNWidgets(2));
    expect(find.text('Please accept the terms to create your account'), findsOneWidget);
    expect(auth.signUps, isEmpty);

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter your first name'), 'Sara');
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter your last name'), 'Ben Ali');
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter your email'), 'sara@mail.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'At least 6 characters'), 'secret123');
    await _tap(tester, find.byType(DropdownMenu<String>));
    await tester.enterText(find.descendant(of: find.byType(DropdownMenu<String>), matching: find.byType(TextField)), 'Tuni');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tunisia').last);
    await tester.pumpAndSettle();
    await _tap(tester, find.byType(Checkbox));
    expect(find.text('Please accept the terms to create your account'), findsNothing);

    await _tap(tester, find.text('Create my account'));
    expect(auth.signUps.single, {
      'firstName': 'Sara',
      'lastName': 'Ben Ali',
      'email': 'sara@mail.com',
      'role': UserRole.client,
      'country': 'Tunisia',
    });
  });
}

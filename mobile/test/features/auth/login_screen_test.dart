import 'package:catchopp_mobile/core/theme/brand.dart';
import 'package:catchopp_mobile/features/auth/presentation/login_screen.dart';
import 'package:catchopp_mobile/shared/widgets/workify_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the login screen shows the Workify logo, name and tagline', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: LoginScreen())));

    expect(find.byType(WorkifyLogo), findsOneWidget);
    expect(find.text('Workify'), findsOneWidget);
    expect(find.text(Brand.tagline), findsOneWidget);
    expect(find.textContaining('CatchOPP'), findsNothing);
  });
}

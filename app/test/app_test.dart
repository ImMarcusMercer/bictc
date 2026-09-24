import 'package:bictc/app/bictc_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('landing opens the dummy login flow', (tester) async {
    await tester.pumpWidget(const BictcApp());

    expect(find.text('BICTC'), findsOneWidget);
    expect(find.textContaining('accessibility evidence'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to BICTC'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Enter your email.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('email-field')),
      'person@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password-field')),
      'dummy-password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text("Authentication isn't connected yet."), findsOneWidget);
  });
}

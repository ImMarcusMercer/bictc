import 'package:bictc/app/bictc_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bottom navigation switches between the three main screens', (
    tester,
  ) async {
    await tester.pumpWidget(const BictcApp());

    expect(find.text('SM City North EDSA'), findsOneWidget);

    await tester.tap(find.text('For Me'));
    await tester.pumpAndSettle();
    expect(find.text('For Me screen'), findsOneWidget);

    await tester.tap(find.text('Community'));
    await tester.pumpAndSettle();
    expect(find.text('Community screen'), findsOneWidget);
  });

  testWidgets('More opens a menu that can be closed', (tester) async {
    await tester.pumpWidget(const BictcApp());

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('My Needs'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Close'));
    await tester.pumpAndSettle();

    expect(find.text('My Needs'), findsNothing);
    expect(find.text('SM City North EDSA'), findsOneWidget);
  });

  for (final destination in ['My Needs', 'Favorites', 'Settings']) {
    testWidgets('More opens the $destination screen', (tester) async {
      await tester.pumpWidget(const BictcApp());

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(destination));
      await tester.pumpAndSettle();

      expect(find.text('$destination screen'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
    });
  }
}

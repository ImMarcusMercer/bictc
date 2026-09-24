import 'test_helpers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('guests browse but cannot open a submission form', (
    tester,
  ) async {
    await pumpBictcApp(tester);
    await tester.tap(find.text('Community'));
    await tester.pumpAndSettle();
    expect(find.text('Community Reports'), findsOneWidget);
    expect(find.text('Robinsons Galleria'), findsOneWidget);
    expect(find.textContaining('Guests can browse'), findsOneWidget);
    await tester.tap(find.text('Report Issue'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in to BICTC'), findsOneWidget);
    expect(find.text('Publish report'), findsNothing);
  });

  testWidgets('city filters show an empty state', (tester) async {
    await pumpBictcApp(tester);
    await tester.tap(find.text('Community'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Cebu'));
    await tester.pumpAndSettle();
    expect(find.text('No reports match these filters.'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Robinsons Galleria'), findsOneWidget);
  });
}

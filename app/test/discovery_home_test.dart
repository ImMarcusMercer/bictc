import 'package:bictc/app/bictc_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('search and status filters narrow the sample places', (
    tester,
  ) async {
    await tester.pumpWidget(const BictcApp());

    expect(find.text('SM City North EDSA'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('place-search')), 'hospital');
    await tester.pump();

    expect(find.text('Philippine General Hospital'), findsOneWidget);
    expect(find.text('SM City North EDSA'), findsNothing);

    await tester.tap(find.text('Accessible', skipOffstage: false).first);
    await tester.pump();
    expect(find.text('No places found'), findsOneWidget);
  });

  testWidgets('clear filters restores places after an empty search', (
    tester,
  ) async {
    await tester.pumpWidget(const BictcApp());
    await tester.enterText(
      find.byKey(const Key('place-search')),
      'no such place',
    );
    await tester.pump();

    expect(find.text('No places found'), findsOneWidget);
    await tester.ensureVisible(find.text('Clear filters'));
    await tester.pump();
    await tester.tap(find.text('Clear filters'));
    await tester.pump();

    expect(find.text('SM City North EDSA'), findsOneWidget);
  });

  testWidgets('map controls fit a narrow phone viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BictcApp());
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Map').first);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('sample places'), findsWidgets);
  });
}

import 'package:bictc/app/bictc_app.dart';
import 'package:bictc/features/needs/models/accessibility_need.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('first launch opens My Needs after the splash', (tester) async {
    final store = MemoryAccessibilityNeedsStore(onboardingCompleted: false);
    await tester.pumpWidget(BictcApp(needsStore: store));

    expect(find.text('Access Able PH'), findsOneWidget);
    expect(find.text('My Accessibility Needs'), findsNothing);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Access Able PH'), findsOneWidget);
    expect(find.text('My Accessibility Needs'), findsNothing);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('Access Able PH'), findsNothing);
    expect(find.text('My Accessibility Needs'), findsOneWidget);
    expect(find.text('SM City North EDSA'), findsNothing);

    await tester.tap(find.byKey(const Key('need-wheelchair')));
    await tester.pump();
    await tester.tap(find.text('Save My Needs'));
    await tester.pumpAndSettle();

    expect(find.text('SM City North EDSA'), findsOneWidget);
    expect(store.onboardingCompleted, isTrue);
    expect(store.needs, {AccessibilityNeed.wheelchair});
  });

  testWidgets('later launches restore needs and open Places', (tester) async {
    final store = MemoryAccessibilityNeedsStore(
      needs: {AccessibilityNeed.visual},
    );

    await pumpBictcApp(tester, needsStore: store);

    expect(find.text('My Accessibility Needs'), findsNothing);
    expect(find.text('SM City North EDSA'), findsOneWidget);
    expect(find.text('Visual'), findsOneWidget);
  });

  testWidgets('bottom navigation orders Places before Map', (tester) async {
    await pumpBictcApp(tester);

    expect(find.text('For Me'), findsNothing);
    expect(find.byKey(const Key('places-list')), findsOneWidget);
    expect(find.text('SM City North EDSA'), findsOneWidget);

    await tester.tap(find.text('Map').last);
    await tester.pump();
    expect(find.byKey(const Key('full-map')), findsOneWidget);
    expect(find.byKey(const Key('places-list')), findsNothing);

    await tester.tap(find.text('Community'));
    await tester.pumpAndSettle();
    expect(find.text('Community screen'), findsOneWidget);
  });

  testWidgets('More opens a menu that can be closed', (tester) async {
    await pumpBictcApp(tester);

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

  for (final destination in ['Favorites', 'Settings']) {
    testWidgets('More opens the $destination screen', (tester) async {
      await pumpBictcApp(tester);

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(destination));
      await tester.pumpAndSettle();

      expect(find.text('$destination screen'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
    });
  }

  testWidgets('My Needs updates recommendations on Places and Map', (
    tester,
  ) async {
    final store = MemoryAccessibilityNeedsStore();
    await pumpBictcApp(tester, needsStore: store);

    expect(find.text('Best Places for You'), findsOneWidget);
    expect(find.text('Choose needs in More'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Needs'));
    await tester.pumpAndSettle();

    expect(find.text('My Accessibility Needs'), findsOneWidget);
    expect(find.text('0 needs selected'), findsOneWidget);
    await tester.tap(find.byKey(const Key('need-visual')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('need-wheelchair')));
    await tester.pump();
    expect(find.text('2 needs selected'), findsOneWidget);

    await tester.tap(find.text('Save My Needs'));
    await tester.pumpAndSettle();

    expect(find.text('Wheelchair'), findsOneWidget);
    expect(find.text('Visual'), findsOneWidget);
    expect(find.text('2 of 2 needs'), findsWidgets);
    expect(store.needs, {
      AccessibilityNeed.visual,
      AccessibilityNeed.wheelchair,
    });
    await tester.tap(find.text('Map').last);
    await tester.pump();
    expect(find.byKey(const Key('full-map')), findsOneWidget);
    expect(find.text('Wheelchair'), findsOneWidget);
    expect(find.text('Visual'), findsOneWidget);
    expect(find.text('5 of 5 match selected needs'), findsOneWidget);
  });

  testWidgets('My Needs remains usable with large text on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpBictcApp(tester);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Needs'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.byKey(const Key('need-chronic')), 240);
    expect(tester.takeException(), isNull);
    expect(find.text('Save My Needs'), findsOneWidget);
  });

  testWidgets('My Needs announces a local save failure', (tester) async {
    final store = MemoryAccessibilityNeedsStore(failOnSave: true);
    await pumpBictcApp(tester, needsStore: store);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Needs'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save My Needs'));
    await tester.pump();

    final error = find.byKey(const Key('save-needs-error'));
    expect(error, findsOneWidget);
    expect(tester.widget<Semantics>(error).properties.liveRegion, isTrue);
    expect(find.text('Save My Needs'), findsOneWidget);
  });
}

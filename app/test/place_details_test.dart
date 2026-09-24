import 'package:bictc/features/discovery/views/discovery_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openPlace(WidgetTester tester, String name) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DiscoveryHome(mode: DiscoveryMode.places, selectedNeeds: {}),
        ),
      ),
    );
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  testWidgets('place opens full details and returns to discovery', (
    tester,
  ) async {
    await openPlace(tester, 'SM City North EDSA');
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Main Entrance Ramp'), findsOneWidget);
    expect(find.textContaining('AI Detected · Suggestion'), findsOneWidget);
    expect(find.text('214 sample reports'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('places-list')), findsOneWidget);
  });

  testWidgets('other places do not inherit SM North sample evidence', (
    tester,
  ) async {
    await openPlace(tester, 'Robinsons Galleria');
    expect(find.text('No detailed evidence yet'), findsOneWidget);
    expect(find.text('Main Entrance Ramp'), findsNothing);
    expect(find.textContaining('Community Verified'), findsNothing);
  });

  testWidgets(
    'details scroll without overflow on narrow phones with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openPlace(tester, 'SM City North EDSA');
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Accessible Parking'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

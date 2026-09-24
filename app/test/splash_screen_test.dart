import 'dart:async';

import 'package:bictc/app/design_system.dart';
import 'package:bictc/features/splash/views/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows accessible branding while startup is pending', (
    tester,
  ) async {
    final startup = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppDesign.theme,
        home: SplashScreen(
          initialize: () => startup.future,
          destination: const Text('Home ready'),
        ),
      ),
    );

    expect(find.text('Access Able PH'), findsOneWidget);
    expect(find.text('Accessibility within reach'), findsOneWidget);
    expect(find.text('Loading'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      isNull,
    );
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      isNull,
    );
    expect(find.bySemanticsLabel('Access Able PH logo'), findsOneWidget);
    expect(find.bySemanticsLabel('Loading Access Able PH'), findsOneWidget);
    expect(find.text('Home ready'), findsNothing);

    startup.complete();
    await tester.pump();
    await tester.pump();

    expect(find.text('Home ready'), findsOneWidget);
    expect(find.text('Access Able PH'), findsNothing);
  });

  testWidgets('fits a narrow screen with large text', (tester) async {
    final startup = Completer<void>();
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppDesign.theme,
        home: SplashScreen(
          initialize: () => startup.future,
          destination: const Text('Home ready'),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Access Able PH'), findsOneWidget);
    expect(find.text('Loading'), findsOneWidget);
  });

  testWidgets('shows an accessible retry state after startup fails', (
    tester,
  ) async {
    var attempts = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppDesign.theme,
        home: SplashScreen(
          initialize: () async {
            attempts++;
            if (attempts == 1) throw Exception('startup failed');
          },
          destination: const Text('Home ready'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Unable to start'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Access Able PH could not start'),
      findsOneWidget,
    );

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(attempts, 2);
    expect(find.text('Home ready'), findsOneWidget);
  });
}

import 'dart:async';

import 'package:bictc/app/app_bootstrap.dart';
import 'package:bictc/app/bictc_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('startup waits for initialization before displaying the app', (
    tester,
  ) async {
    final initialized = Completer<void>();
    await tester.pumpWidget(AppBootstrap(initialize: () => initialized.future));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(BictcApp), findsNothing);
    initialized.complete();
    await tester.pumpAndSettle();
    expect(find.byType(BictcApp), findsOneWidget);
  });

  testWidgets(
    'startup failure is recoverable and does not expose exception details',
    (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        AppBootstrap(
          initialize: () async {
            if (++attempts == 1) throw StateError('sensitive-error-detail');
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('sensitive-error-detail'), findsNothing);
      expect(find.text('Unable to start the app.'), findsOneWidget);
      expect(find.byType(BictcApp), findsNothing);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.byType(BictcApp), findsOneWidget);
    },
  );
}

import 'package:bictc/app/bictc_app.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpBictcApp(WidgetTester tester) async {
  await tester.pumpWidget(const BictcApp());
  await tester.pump();
  await tester.pump();
}

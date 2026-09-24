import 'package:bictc/shared/repositories/local_store.dart';
import 'package:bictc/app/bictc_app.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpBictcApp(WidgetTester tester) async {
  await tester.pumpWidget(BictcApp(localStore: MemoryLocalStore()));
  await tester.pump();
  await tester.pump();
}

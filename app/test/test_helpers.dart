import 'package:bictc/shared/repositories/local_store.dart';
import 'package:bictc/app/bictc_app.dart';
import 'package:bictc/features/needs/data/accessibility_needs_store.dart';
import 'package:bictc/features/needs/models/accessibility_need.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryAccessibilityNeedsStore implements AccessibilityNeedsStore {
  MemoryAccessibilityNeedsStore({
    this.onboardingCompleted = true,
    this.failOnSave = false,
    Set<AccessibilityNeed>? needs,
  }) : needs = needs ?? {};

  bool onboardingCompleted;
  bool failOnSave;
  Set<AccessibilityNeed> needs;

  @override
  Future<AccessibilityNeedsPreferences> load() async =>
      AccessibilityNeedsPreferences(
        onboardingCompleted: onboardingCompleted,
        needs: needs,
      );

  @override
  Future<void> save(Set<AccessibilityNeed> needs) async {
    if (failOnSave) throw Exception('save failed');
    this.needs = {...needs};
    onboardingCompleted = true;
  }
}

Future<void> pumpBictcApp(
  WidgetTester tester, {
  LocalStore? localStore,
  MemoryAccessibilityNeedsStore? needsStore,
}) async {
  await tester.pumpWidget(
    BictcApp(
      localStore: localStore ?? MemoryLocalStore(),
      needsStore: needsStore ?? MemoryAccessibilityNeedsStore(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pump();
}

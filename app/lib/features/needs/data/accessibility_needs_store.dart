import 'package:bictc/features/needs/models/accessibility_need.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityNeedsPreferences {
  AccessibilityNeedsPreferences({
    required this.onboardingCompleted,
    required Set<AccessibilityNeed> needs,
  }) : needs = Set.unmodifiable(needs);

  final bool onboardingCompleted;
  final Set<AccessibilityNeed> needs;
}

abstract interface class AccessibilityNeedsStore {
  Future<AccessibilityNeedsPreferences> load();

  Future<void> save(Set<AccessibilityNeed> needs);
}

class SharedPreferencesAccessibilityNeedsStore
    implements AccessibilityNeedsStore {
  SharedPreferencesAccessibilityNeedsStore({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  static const _completedKey = 'accessibility_needs_onboarding_completed';
  static const _needsKey = 'accessibility_needs';

  final SharedPreferencesAsync _preferences;

  @override
  Future<AccessibilityNeedsPreferences> load() async {
    final storedNames = (await _preferences.getStringList(_needsKey))?.toSet();
    final needs = storedNames == null
        ? <AccessibilityNeed>{}
        : AccessibilityNeed.values
              .where((need) => storedNames.contains(need.name))
              .toSet();

    return AccessibilityNeedsPreferences(
      onboardingCompleted: await _preferences.getBool(_completedKey) ?? false,
      needs: needs,
    );
  }

  @override
  Future<void> save(Set<AccessibilityNeed> needs) async {
    final names = AccessibilityNeed.values
        .where(needs.contains)
        .map((need) => need.name)
        .toList();
    await _preferences.setStringList(_needsKey, names);
    await _preferences.setBool(_completedKey, true);
  }
}

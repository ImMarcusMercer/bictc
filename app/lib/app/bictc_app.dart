import 'package:bictc/features/navigation/views/main_shell.dart';
import 'package:bictc/features/needs/data/accessibility_needs_store.dart';
import 'package:bictc/features/splash/views/splash_screen.dart';
import 'package:bictc/app/design_system.dart';
import 'package:flutter/material.dart';

class BictcApp extends StatefulWidget {
  const BictcApp({this.needsStore, super.key});

  final AccessibilityNeedsStore? needsStore;

  @override
  State<BictcApp> createState() => _BictcAppState();
}

class _BictcAppState extends State<BictcApp> {
  static const _minimumSplashDuration = Duration(milliseconds: 1200);

  late final AccessibilityNeedsStore _needsStore =
      widget.needsStore ?? SharedPreferencesAccessibilityNeedsStore();
  late AccessibilityNeedsPreferences _needsPreferences;

  Future<void> _initialize() async {
    final minimumDisplay = Future<void>.delayed(_minimumSplashDuration);
    await WidgetsBinding.instance.endOfFrame;
    final needsPreferences = await _needsStore.load();
    await minimumDisplay;
    _needsPreferences = needsPreferences;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Access Able PH',
      debugShowCheckedModeBanner: false,
      theme: AppDesign.theme,
      home: SplashScreen(
        initialize: _initialize,
        destination: Builder(
          builder: (context) => MainShell(
            initialNeeds: _needsPreferences.needs,
            showNeedsOnLaunch: !_needsPreferences.onboardingCompleted,
            onNeedsSaved: _needsStore.save,
          ),
        ),
      ),
    );
  }
}

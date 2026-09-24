import 'package:bictc/features/navigation/views/main_shell.dart';
import 'package:bictc/features/splash/views/splash_screen.dart';
import 'package:bictc/app/design_system.dart';
import 'package:bictc/shared/repositories/local_store.dart';
import 'package:bictc/shared/repositories/preferences_repository.dart';
import 'package:flutter/material.dart';

class BictcApp extends StatefulWidget {
  const BictcApp({super.key, this.localStore});
  final LocalStore? localStore;
  @override
  State<BictcApp> createState() => _BictcAppState();
}

class _BictcAppState extends State<BictcApp> {
  late final LocalStore _store = widget.localStore ?? DeviceLocalStore();
  late final PreferencesRepository _preferences = PreferencesRepository(_store);
  @override
  void initState() {
    super.initState();
    _preferences.load();
  }

  @override
  void dispose() {
    _preferences.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _preferences,
    builder: (context, _) => MaterialApp(
      title: 'Access Able PH',
      debugShowCheckedModeBanner: false,
      theme: AppDesign.theme.copyWith(
        pageTransitionsTheme: _preferences.reduceMotion
            ? const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: _NoTransitions(),
                  TargetPlatform.iOS: _NoTransitions(),
                  TargetPlatform.linux: _NoTransitions(),
                  TargetPlatform.macOS: _NoTransitions(),
                  TargetPlatform.windows: _NoTransitions(),
                  TargetPlatform.fuchsia: _NoTransitions(),
                },
              )
            : null,
      ),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: _preferences.largerText
                ? media.textScaler.clamp(minScaleFactor: 1.25)
                : media.textScaler,
            disableAnimations:
                media.disableAnimations || _preferences.reduceMotion,
          ),
          child: child!,
        );
      },
      home: SplashScreen(
        initialize: () => WidgetsBinding.instance.endOfFrame,
        destination: MainShell(preferences: _preferences, store: _store),
      ),
    ),
  );
}

class _NoTransitions extends PageTransitionsBuilder {
  const _NoTransitions();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

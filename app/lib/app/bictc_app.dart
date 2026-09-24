import 'package:bictc/features/navigation/views/main_shell.dart';
import 'package:bictc/features/splash/views/splash_screen.dart';
import 'package:bictc/app/design_system.dart';
import 'package:flutter/material.dart';

class BictcApp extends StatelessWidget {
  const BictcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Access Able PH',
      debugShowCheckedModeBanner: false,
      theme: AppDesign.theme,
      home: SplashScreen(
        initialize: () => WidgetsBinding.instance.endOfFrame,
        destination: const MainShell(),
      ),
    );
  }
}

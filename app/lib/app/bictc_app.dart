import 'package:bictc/features/landing/views/landing_page.dart';
import 'package:flutter/material.dart';

class BictcApp extends StatelessWidget {
  const BictcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BICTC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006A60)),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
        useMaterial3: true,
      ),
      home: const LandingPage(),
    );
  }
}

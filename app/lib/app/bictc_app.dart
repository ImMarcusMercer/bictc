import 'package:bictc/features/navigation/views/main_shell.dart';
import 'package:bictc/app/design_system.dart';
import 'package:flutter/material.dart';

class BictcApp extends StatelessWidget {
  const BictcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AccessPH',
      debugShowCheckedModeBanner: false,
      theme: AppDesign.theme,
      home: const MainShell(),
    );
  }
}

import 'package:bictc/app/bictc_app.dart';
import 'package:bictc/app/design_system.dart';
import 'package:flutter/material.dart';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({required this.initialize, super.key});

  final Future<void> Function() initialize;

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = Future.sync(widget.initialize);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return const BictcApp();
        }
        return MaterialApp(
          title: 'AccessPH',
          debugShowCheckedModeBanner: false,
          theme: AppDesign.theme,
          home: Scaffold(
            body: SafeArea(
              child: Center(
                child: snapshot.hasError
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Unable to start the app.'),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => setState(() {
                                _initialization = Future.sync(
                                  widget.initialize,
                                );
                              }),
                              child: const Text('Try again'),
                            ),
                          ],
                        ),
                      )
                    : const CircularProgressIndicator(
                        semanticsLabel: 'Starting AccessPH',
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

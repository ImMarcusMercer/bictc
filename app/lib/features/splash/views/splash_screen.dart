import 'package:bictc/app/design_system.dart';
import 'package:flutter/material.dart';

typedef StartupTask = Future<void> Function();

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    required this.initialize,
    required this.destination,
    super.key,
  });

  final StartupTask initialize;
  final Widget destination;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  var _isReady = false;
  var _hasError = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (_hasError) setState(() => _hasError = false);

    try {
      await widget.initialize();
      if (!mounted) return;
      setState(() => _isReady = true);
    } on Object {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) return widget.destination;

    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: _SplashContent(hasError: _hasError, onRetry: _initialize),
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent({required this.hasError, required this.onRetry});

  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _SplashLogo(),
                    const SizedBox(height: 24),
                    Text(
                      'Access Able PH',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.splashInk,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Accessibility within reach',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 48),
                    if (hasError)
                      _SplashError(onRetry: onRetry)
                    else
                      const _SplashLoading(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashError extends StatelessWidget {
  const _SplashError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      liveRegion: true,
      label: 'Access Able PH could not start',
      child: Column(
        children: [
          const ExcludeSemantics(
            child: Icon(
              Icons.error_outline_rounded,
              size: 36,
              color: AppColors.barrier,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Unable to start',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: AppColors.splashInk),
          ),
          const SizedBox(height: 6),
          const Text(
            'Please try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Access Able PH logo',
      child: const ExcludeSemantics(
        child: SizedBox.square(
          dimension: 112,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 112,
                color: AppColors.splashPrimary,
              ),
              Positioned(
                top: 25,
                child: Icon(
                  Icons.accessible_forward_rounded,
                  size: 42,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashLoading extends StatelessWidget {
  const _SplashLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Loading Access Able PH',
      child: const ExcludeSemantics(
        child: Column(
          children: [
            SizedBox.square(
              dimension: 32,
              child: CircularProgressIndicator(
                color: AppColors.splashAccent,
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Loading',
              style: TextStyle(
                color: AppColors.splashInk,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  color: AppColors.splashAccent,
                  backgroundColor: AppColors.border,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

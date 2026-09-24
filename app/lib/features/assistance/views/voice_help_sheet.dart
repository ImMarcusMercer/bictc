import 'package:bictc/app/design_system.dart';
import 'package:flutter/material.dart';

/// Entry point until verified requests and LiveKit sessions are connected.
class VoiceHelpSheet extends StatelessWidget {
  const VoiceHelpSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.support_agent, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Voice assistance',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Voice calling is not available yet.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'When available, verified PWD and elderly users can ask the community for voice assistance. No request has been sent.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to app'),
            ),
          ],
        ),
      ),
    );
  }
}

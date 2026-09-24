import 'package:bictc/features/auth/views/login_page.dart';
import 'package:bictc/shared/repositories/preferences_repository.dart';
import 'package:bictc/shared/repositories/session_repository.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.preferences,
    required this.session,
  });
  final PreferencesRepository preferences;
  final SessionRepository session;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _signingOut = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    widget.preferences.load();
  }

  Future<void> _save({bool? largerText, bool? reduceMotion}) async {
    setState(() => _error = null);
    try {
      await widget.preferences.update(
        largerText: largerText,
        reduceMotion: reduceMotion,
      );
    } catch (_) {
      if (mounted)
        setState(
          () => _error = 'Could not save preferences. Your previous settings are unchanged.',
        );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([widget.preferences, widget.session]),
        builder: (context, _) {
          final prefs = widget.preferences;
          final session = widget.session;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Account', style: Theme.of(context).textTheme.titleLarge),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        session.canContribute ? 'Signed in' : 'Guest',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (session.email != null) Text(session.email!),
                      const SizedBox(height: 8),
                      Text(
                        session.isPreview
                            ? 'Sample-data mode. Sign-in is unavailable in this preview.'
                            : session.canContribute
                            ? 'Reports and account favorites use this account.'
                            : 'Browse and save places on this device. Sign in to sync favorites and contribute reports.',
                      ),
                      const SizedBox(height: 12),
                      if (session.canContribute)
                        OutlinedButton(
                          onPressed: _signingOut
                              ? null
                              : () async {
                                  setState(() {
                                    _signingOut = true;
                                    _error = null;
                                  });
                                  try {
                                    await session.signOut();
                                  } catch (_) {
                                    if (mounted)
                                      setState(
                                        () => _error = 'Unable to sign out. Check your connection and retry.',
                                      );
                                  } finally {
                                    if (mounted)
                                      setState(() => _signingOut = false);
                                  }
                                },
                          child: Text(
                            _signingOut ? 'Signing out...' : 'Sign out',
                          ),
                        )
                      else
                        FilledButton(
                          onPressed: session.isPreview
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        LoginPage(repository: session),
                                  ),
                                ),
                          child: const Text('Sign in'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Accessibility',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Text('These preferences are saved on this device.'),
              if (prefs.error != null) ...[
                Text(prefs.error!),
                TextButton(
                  onPressed: prefs.busy ? null : prefs.retry,
                  child: const Text('Retry preferences'),
                ),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Larger text'),
                subtitle: const Text(
                  'Increase app text without reducing your system text size.',
                ),
                value: prefs.largerText,
                onChanged: prefs.busy || prefs.error != null
                    ? null
                    : (value) => _save(largerText: value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reduce motion'),
                subtitle: const Text(
                  'Remove page transitions and request reduced system animations.',
                ),
                value: prefs.reduceMotion,
                onChanged: prefs.busy || prefs.error != null
                    ? null
                    : (value) => _save(reduceMotion: value),
              ),
              if (_error != null)
                Semantics(liveRegion: true, child: Text(_error!)),
              const Divider(height: 32),
              Text(
                'About Access Able PH',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('Version 0.1.0'),
              const SizedBox(height: 8),
              const Text(
                'Community accessibility observations help you plan. They are not accessibility certification. Your accessibility needs are not stored in a public profile.',
              ),
            ],
          );
        },
      ),
    ),
  );
}

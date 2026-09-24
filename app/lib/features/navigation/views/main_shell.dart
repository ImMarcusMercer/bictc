import 'package:bictc/features/favorites/views/favorites_screen.dart';
import 'package:bictc/features/settings/views/settings_screen.dart';
import 'package:bictc/shared/repositories/favorites_repository.dart';
import 'package:bictc/shared/repositories/local_store.dart';
import 'package:bictc/shared/repositories/preferences_repository.dart';
import 'package:bictc/shared/repositories/places_repository.dart';
import 'package:bictc/shared/repositories/reports_repository.dart';
import 'package:bictc/features/discovery/views/discovery_home.dart';
import 'package:bictc/features/needs/models/accessibility_need.dart';
import 'package:bictc/features/needs/views/accessibility_needs_screen.dart';
import 'package:bictc/features/assistance/views/voice_help_sheet.dart';
import 'package:bictc/features/navigation/widgets/help_navigation_bar.dart';
import 'package:bictc/features/reports/views/community_reports.dart';
import 'package:flutter/material.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    this.preferences,
    this.store,
    this.account,
    this.places,
    this.favorites,
    this.initialNeeds = const {},
    this.showNeedsOnLaunch = false,
    this.onNeedsSaved,
  });
  final PreferencesRepository? preferences;
  final LocalStore? store;
  final ReportsRepository? account;
  final PlacesRepository? places;
  final FavoritesRepository? favorites;
  final Set<AccessibilityNeed> initialNeeds;
  final bool showNeedsOnLaunch;
  final Future<void> Function(Set<AccessibilityNeed>)? onNeedsSaved;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final LocalStore _store = widget.store ?? DeviceLocalStore();
  late final PreferencesRepository _preferences =
      widget.preferences ?? PreferencesRepository(_store);
  late final ReportsRepository _account =
      widget.account ?? createReportsRepository();
  late final PlacesRepository _places =
      widget.places ?? createPlacesRepository();
  late final FavoritesRepository _favorites =
      widget.favorites ?? createFavoritesRepository(_account, _store);
  @override
  void initState() {
    super.initState();
    _preferences.load();
    _favorites.initialize();
  }

  @override
  void dispose() {
    if (widget.favorites == null) _favorites.dispose();
    if (widget.account == null) _account.dispose();
    if (widget.preferences == null) _preferences.dispose();
    super.dispose();
  }

  int _selectedIndex = 0;
  late Set<AccessibilityNeed> _selectedNeeds = {...widget.initialNeeds};
  late bool _showNeedsOnLaunch = widget.showNeedsOnLaunch;
  bool _helpSheetOpen = false;

  @override
  Widget build(BuildContext context) {
    if (_showNeedsOnLaunch) {
      return AccessibilityNeedsScreen(
        initialNeeds: _selectedNeeds,
        onSaved: _saveNeeds,
        popOnSave: false,
      );
    }

    return Scaffold(
      body: _selectedIndex < 2
          ? SafeArea(
              child: DiscoveryHome(
                repository: _places,
                favorites: _favorites,
                mode: _selectedIndex == 0
                    ? DiscoveryMode.places
                    : DiscoveryMode.map,
                selectedNeeds: _selectedNeeds,
              ),
            )
          : CommunityReports(repository: _account),
      bottomNavigationBar: HelpNavigationBar(
        selectedIndex: _selectedIndex,
        onHelpRequested: _requestHelp,
        onDestinationSelected: (index) {
          if (index == 3) {
            _showMoreMenu();
            return;
          }

          setState(() => _selectedIndex = index);
        },
      ),
    );
  }

  Future<void> _requestHelp() async {
    if (_helpSheetOpen) return;
    _helpSheetOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        useSafeArea: true,
        constraints: const BoxConstraints(maxWidth: 520),
        builder: (context) => const VoiceHelpSheet(),
      );
    } finally {
      _helpSheetOpen = false;
    }
  }

  Future<void> _showMoreMenu() async {
    final destination = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _MoreMenu(),
    );

    if (!mounted || destination == null) return;

    if (destination == 'My Needs') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => AccessibilityNeedsScreen(
            initialNeeds: _selectedNeeds,
            onSaved: _saveNeeds,
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => destination == 'Favorites'
            ? FavoritesScreen(repository: _favorites, session: _account)
            : SettingsScreen(preferences: _preferences, session: _account),
      ),
    );
  }

  Future<void> _saveNeeds(Set<AccessibilityNeed> needs) async {
    await widget.onNeedsSaved?.call(needs);
    if (!mounted) return;
    setState(() {
      _selectedNeeds = {...needs};
      _showNeedsOnLaunch = false;
    });
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MoreMenuItem(
                icon: Icons.accessible,
                label: 'My Needs',
                onTap: () => Navigator.pop(context, 'My Needs'),
              ),
              _MoreMenuItem(
                icon: Icons.favorite,
                label: 'Favorites',
                onTap: () => Navigator.pop(context, 'Favorites'),
              ),
              _MoreMenuItem(
                icon: Icons.settings,
                label: 'Settings',
                onTap: () => Navigator.pop(context, 'Settings'),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'AccessPH v0.1.0 - For PWDs across the Philippines',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreMenuItem extends StatelessWidget {
  const _MoreMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

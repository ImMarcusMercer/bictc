import 'package:bictc/features/discovery/views/discovery_home.dart';
import 'package:flutter/material.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _screenNames = ['Map', 'For Me', 'Community'];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenName = _screenNames[_selectedIndex];

    return Scaffold(
      appBar: _selectedIndex == 0 ? null : AppBar(title: Text(screenName)),
      body: _selectedIndex == 0
          ? const SafeArea(child: DiscoveryHome())
          : Center(child: Text('$screenName screen')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == 3) {
            _showMoreMenu();
            return;
          }

          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline),
            selectedIcon: Icon(Icons.star),
            label: 'For Me',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Community',
          ),
          NavigationDestination(icon: Icon(Icons.menu), label: 'More'),
        ],
      ),
    );
  }

  Future<void> _showMoreMenu() async {
    final destination = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _MoreMenu(),
    );

    if (!mounted || destination == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _EmptyScreen(title: destination),
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                'AccessPH v1.0 - For PWDs across the Philippines',
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

class _EmptyScreen extends StatelessWidget {
  const _EmptyScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title screen')),
    );
  }
}

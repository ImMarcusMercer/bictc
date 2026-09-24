import 'package:bictc/app/design_system.dart';
import 'package:bictc/features/auth/views/login_page.dart';
import 'package:bictc/shared/repositories/favorites_repository.dart';
import 'package:bictc/shared/repositories/session_repository.dart';
import 'package:bictc/shared/widgets/favorite_button.dart';
import 'package:flutter/material.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    super.key,
    required this.repository,
    required this.session,
  });
  final FavoritesRepository repository;
  final SessionRepository session;
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    widget.repository.initialize();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Favorites')),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: widget.repository,
        builder: (context, _) {
          final repo = widget.repository;
          return RefreshIndicator(
            onRefresh: repo.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.session.canContribute
                      ? 'Saved to your account'
                      : 'Saved on this device',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.session.canContribute
                      ? 'Your saved places are private to your account.'
                      : 'Save places while browsing. Sign in to sync real establishments to your account.',
                ),
                if (widget.session.isPreview)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Sample-data preview. Sample favorites stay on this device.',
                    ),
                  ),
                if (!widget.session.canContribute && !widget.session.isPreview)
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => LoginPage(repository: widget.session),
                      ),
                    ),
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in to sync'),
                  ),
                if (repo.error != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Semantics(liveRegion: true, child: Text(repo.error!)),
                          TextButton(
                            onPressed: repo.loading || repo.saving
                                ? null
                                : repo.refresh,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (repo.loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Loading favorites',
                      ),
                    ),
                  ),
                if (!repo.loading && repo.items.isEmpty && repo.error == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        SizedBox(height: 16),
                        Text('No favorites yet'),
                        SizedBox(height: 8),
                        Text('Open a place and select Save to favorites.'),
                      ],
                    ),
                  ),
                ...repo.items.map(
                  (entry) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.place_outlined),
                            title: Text(
                              entry.place?.name ?? 'Unavailable establishment',
                            ),
                            subtitle: Text(
                              entry.place == null
                                  ? 'This place is no longer publicly listed.'
                                  : '${entry.place!.city}\n${entry.place!.address}',
                            ),
                            onTap: entry.place == null
                                ? null
                                : () => showModalBottomSheet<void>(
                                    context: context,
                                    showDragHandle: true,
                                    isScrollControlled: true,
                                    builder: (_) => SafeArea(
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry.place!.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(entry.place!.address),
                                            const SizedBox(height: 12),
                                            Text(
                                              entry.place!.isSample
                                                  ? 'Sample place. Check current evidence before visiting.'
                                                  : 'Saved place. Check current accessibility evidence before visiting.',
                                            ),
                                            const SizedBox(height: 12),
                                            FavoriteButton(
                                              repository: repo,
                                              place: entry.place!,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                          if (entry.place?.isSample ?? false)
                            const Text(
                              'Sample place - device only',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: repo.loading || repo.saving
                                  ? null
                                  : () async {
                                      try {
                                        await repo.remove(entry.key);
                                      } catch (_) {
                                        if (context.mounted)
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Could not remove favorite. Please retry.',
                                                  ),
                                                ),
                                              );
                                      }
                                    },
                              icon: const Icon(Icons.favorite),
                              label: const Text('Remove'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

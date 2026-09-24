import 'package:bictc/shared/repositories/favorites_repository.dart';
import 'package:bictc/shared/repositories/fixture_places.dart';
import 'package:flutter/material.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.repository,
    required this.place,
  });
  final FavoritesRepository repository;
  final SamplePlace place;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: repository,
    builder: (context, _) {
      final saved = repository.contains(place);
      return OutlinedButton.icon(
        onPressed: repository.loading || repository.saving
            ? null
            : () async {
                try {
                  await repository.toggle(place);
                } catch (_) {
                  if (context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Could not save this change. Check your connection or device storage and retry.',
                        ),
                      ),
                    );
                }
              },
        icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
        label: Text(saved ? 'Remove from favorites' : 'Save to favorites'),
      );
    },
  );
}

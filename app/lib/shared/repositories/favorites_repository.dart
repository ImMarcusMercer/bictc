import 'dart:async';
import 'dart:convert';

import 'package:bictc/app/supabase_config.dart';
import 'package:bictc/shared/repositories/fixture_places.dart';
import 'package:bictc/shared/repositories/local_store.dart';
import 'package:bictc/shared/repositories/places_repository.dart';
import 'package:bictc/shared/repositories/session_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteEntry {
  const FavoriteEntry(this.key, this.place);
  final String key;
  final SamplePlace? place;
}

abstract interface class FavoritesBackend {
  Future<List<FavoriteEntry>> fetch(String userId);
  Future<void> add(String userId, String placeId);
  Future<void> remove(String userId, String placeId);
}

class SupabaseFavoritesBackend implements FavoritesBackend {
  SupabaseFavoritesBackend(this.client);
  final SupabaseClient client;
  @override
  Future<List<FavoriteEntry>> fetch(String userId) async {
    final entries = <FavoriteEntry>[];
    for (var offset = 0; ; offset += 200) {
      final rows = await client
          .from('favorites')
          .select('establishment_id, establishments(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .order('establishment_id')
          .range(offset, offset + 199);
      entries.addAll(
        rows.map(
          (row) => FavoriteEntry(
            row['establishment_id'] as String,
            row['establishments'] == null
                ? null
                : placeFromJson(
                    Map<String, dynamic>.from(row['establishments'] as Map),
                  ),
          ),
        ),
      );
      if (rows.length < 200) return entries;
    }
  }

  @override
  Future<void> add(String userId, String placeId) async {
    await client.from('favorites').upsert({
      'user_id': userId,
      'establishment_id': placeId,
    }, ignoreDuplicates: true);
  }

  @override
  Future<void> remove(String userId, String placeId) async {
    await client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('establishment_id', placeId);
  }
}

FavoritesRepository createFavoritesRepository(
  SessionRepository session,
  LocalStore store,
) => FavoritesRepository(
  session,
  store,
  backend: SupabaseConfig.fromEnvironment() == null
      ? null
      : SupabaseFavoritesBackend(Supabase.instance.client),
);

class FavoritesRepository extends ChangeNotifier {
  FavoritesRepository(this.session, this.store, {this.backend}) {
    _user = session.userId;
    session.addListener(_sessionChanged);
  }
  static const storageKey = 'accessph.guest-favorites.v1';
  final SessionRepository session;
  final LocalStore store;
  final FavoritesBackend? backend;
  Map<String, SamplePlace> _guest = {};
  List<FavoriteEntry> _account = [];
  String? _user;
  int _epoch = 0;
  bool _disposed = false;
  bool loading = true;
  bool saving = false;
  bool _localLoaded = false;
  String? error;
  Future<void>? _initialization;
  Future<void> _operations = Future.value();
  Future<T> _serialize<T>(Future<T> Function() operation) {
    final next = _operations.then((_) => operation());
    _operations = next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }
  List<FavoriteEntry> get items => List.unmodifiable(
    _user == null
        ? _guest.entries.map((entry) => FavoriteEntry(entry.key, entry.value))
        : _account,
  );
  bool contains(SamplePlace place) =>
      items.any((entry) => entry.key == place.favoriteKey);
  bool get hasPendingSync => _guest.values.any((place) => place.id != null);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() => _initialization ??= _initialize();
  Future<void> _initialize() async {
    try {
      final raw = await store.read(storageKey);
      if (raw != null) {
        final places = (jsonDecode(raw) as List).map(
          (row) => placeFromJson(Map<String, dynamic>.from(row as Map)),
        );
        _guest = {for (final place in places) place.favoriteKey: place};
      }
      _localLoaded = true;
      await refresh();
    } catch (_) {
      error =
          'Could not load device favorites. Retry before saving new places.';
      loading = false;
      _notify();
    }
  }

  void _sessionChanged() {
    final user = session.userId;
    if (_user == user) return;
    _user = user;
    _epoch++;
    _account = [];
    error = null;
    loading = true;
    _notify();
    if (_localLoaded) unawaited(refresh());
  }

  Future<void> refresh() {
    if (!_localLoaded) {
      _initialization = null;
      return initialize();
    }
    return _serialize(_refresh);
  }
  Future<void> _refresh() async {
    if (!_localLoaded) {
      _initialization = null;
      return initialize();
    }
    final user = _user;
    final epoch = ++_epoch;
    loading = true;
    error = null;
    _notify();
    try {
      if (user != null && backend != null) {
        // Do not remove local records until every import and the account read succeeds.
        final pending = _guest.values
            .where((place) => place.id != null)
            .toList();
        for (final place in pending) {
          if (epoch != _epoch || _disposed) return;
          await backend!.add(user, place.id!);
        }
        final records = await backend!.fetch(user);
        if (epoch != _epoch || _disposed) return;
        _account = records;
        if (pending.isNotEmpty) {
          final remaining = Map<String, SamplePlace>.from(_guest);
          for (final place in pending) {
            remaining.remove(place.favoriteKey);
          }
          await _persist(remaining);
          _guest = remaining;
          if (epoch != _epoch || _disposed) return;
        }
      }
    } catch (_) {
      if (epoch == _epoch) error = 'Favorites could not sync. Device favorites are kept safe. Check your connection and retry.';
    } finally {
      if (epoch == _epoch) {
        loading = false;
        _notify();
      }
    }
  }

  Future<void> _persist(Map<String, SamplePlace> places) => store.write(
    storageKey,
    jsonEncode(places.values.map(placeToJson).toList()),
  );
  Future<void> toggle(SamplePlace place) async {
    if (contains(place)) {
      await remove(place.favoriteKey);
      return;
    }
    await _change(place.favoriteKey, place);
  }

  Future<void> remove(String key) => _change(key, null);
  Future<void> _change(String key, SamplePlace? place) =>
      _serialize(() => _performChange(key, place));
  Future<void> _performChange(String key, SamplePlace? place) async {
    if (loading || saving || !_localLoaded)
      throw StateError('Wait for favorites to load.');
    saving = true;
    _notify();
    final user = _user;
    final epoch = _epoch;
    try {
      if (user == null) {
        final next = Map<String, SamplePlace>.from(_guest);
        if (place == null) {
          next.remove(key);
        } else {
          next[key] = place;
        }
        await _persist(next);
        _guest = next;
      } else {
        if (backend == null || (place != null && place.isSample))
          throw StateError('Sample places stay on this device.');
        if (place == null) {
          await backend!.remove(user, key);
        } else {
          await backend!.add(user, key);
        }
        if (epoch != _epoch || _disposed) return;
        _account = _account.where((entry) => entry.key != key).toList();
        if (place != null) _account.insert(0, FavoriteEntry(key, place));
      }
      error = null;
    } finally {
      saving = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    session.removeListener(_sessionChanged);
    super.dispose();
  }
}

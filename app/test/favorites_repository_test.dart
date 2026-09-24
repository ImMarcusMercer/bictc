import 'dart:async';
import 'package:bictc/shared/repositories/favorites_repository.dart';
import 'package:bictc/shared/repositories/fixture_places.dart';
import 'package:bictc/shared/repositories/local_store.dart';
import 'package:bictc/shared/repositories/places_repository.dart';
import 'package:bictc/shared/repositories/preferences_repository.dart';
import 'package:bictc/shared/repositories/session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class TestSession extends SessionRepository {
  String? account;
  @override
  String? get userId => account;
  @override
  bool get canContribute => account != null;
  @override
  bool get isPreview => false;
  @override
  Future<void> signIn(String email, String password) async { account = email; notifyListeners(); }
  @override
  Future<void> signOut() async { account = null; notifyListeners(); }
}
class TestFavoritesBackend implements FavoritesBackend {
  final Map<String, Set<String>> records = {};
  bool fail = false;
  Completer<void>? pause;
  @override
  Future<void> add(String userId, String placeId) async {
    if (fail) throw StateError('offline');
    if (pause != null) await pause!.future;
    (records[userId] ??= {}).add(placeId);
  }
  @override
  Future<List<FavoriteEntry>> fetch(String userId) async {
    if (fail) throw StateError('offline');
    return (records[userId] ?? {}).map((id) => FavoriteEntry(id, livePlace)).toList();
  }
  @override
  Future<void> remove(String userId, String placeId) async { records[userId]?.remove(placeId); }
}
class FailingStore extends MemoryLocalStore {
  bool fail = false;
  @override
  Future<void> write(String key, String value) async {
    if (fail) throw StateError('storage full');
    await super.write(key, value);
  }
}
final livePlace = placeFromJson({...placeToJson(samplePlaces.first), 'id': '30000000-0000-4000-8000-000000000001'});

void main() {
  test('guest favorites persist across repository instances and remove durably', () async {
    final store = MemoryLocalStore(); final session = TestSession();
    final first = FavoritesRepository(session, store);
    await first.initialize(); await first.toggle(samplePlaces.first); first.dispose();
    final second = FavoritesRepository(session, store);
    await second.initialize(); expect(second.items.single.place!.name, samplePlaces.first.name);
    await second.remove(samplePlaces.first.favoriteKey);
    final third = FavoritesRepository(session, store); await third.initialize();
    expect(third.items, isEmpty);
    second.dispose(); third.dispose(); session.dispose();
  });
  test('login imports only real IDs; sign-out hides account favorites', () async {
    final store = MemoryLocalStore(); final session = TestSession(); final backend = TestFavoritesBackend();
    final repo = FavoritesRepository(session, store, backend: backend); await repo.initialize();
    await repo.toggle(livePlace); await repo.toggle(samplePlaces.first);
    await session.signIn('user-a', ''); await repo.refresh();
    expect(backend.records['user-a'], {livePlace.id});
    expect(repo.items.single.key, livePlace.id);
    expect(repo.hasPendingSync, isFalse);
    await session.signOut(); await repo.refresh();
    expect(repo.items.single.place!.isSample, isTrue);
    await session.signIn('user-b', ''); await repo.refresh();
    expect(repo.items, isEmpty);
    repo.dispose(); session.dispose();
  });
  test('failed import retains guest records and retries idempotently', () async {
    final store = MemoryLocalStore(); final session = TestSession(); final backend = TestFavoritesBackend()..fail = true;
    final repo = FavoritesRepository(session, store, backend: backend); await repo.initialize(); await repo.toggle(livePlace);
    await session.signIn('user-a', ''); await repo.refresh();
    expect(repo.error, isNotNull); expect(repo.hasPendingSync, isTrue);
    backend.fail = false; await repo.refresh(); await repo.refresh();
    expect(backend.records['user-a']!.length, 1); expect(repo.hasPendingSync, isFalse);
    repo.dispose(); session.dispose();
  });
  test('account change during import never exposes previous account records', () async {
    final store = MemoryLocalStore(); final session = TestSession(); final backend = TestFavoritesBackend();
    final repo = FavoritesRepository(session, store, backend: backend); await repo.initialize(); await repo.toggle(livePlace);
    backend.pause = Completer<void>();
    await session.signIn('user-a', ''); await Future<void>.delayed(Duration.zero);
    await session.signOut(); expect(repo.items.every((entry) => entry.place != null), isTrue);
    backend.pause!.complete(); await repo.refresh();
    expect(session.userId, isNull); expect(repo.items.single.key, livePlace.id);
    repo.dispose(); session.dispose();
  });
  test('storage failure does not lose favorites or claim a preference change', () async {
    final store = FailingStore(); final session = TestSession(); final repo = FavoritesRepository(session, store);
    await repo.initialize(); await repo.toggle(livePlace); store.fail = true;
    await expectLater(repo.remove(livePlace.favoriteKey), throwsStateError);
    expect(repo.items.single.key, livePlace.id);
    final prefs = PreferencesRepository(store); await prefs.load();
    await expectLater(prefs.update(largerText: true), throwsStateError); expect(prefs.largerText, isFalse);
    repo.dispose(); session.dispose(); prefs.dispose();
  });
  test('device preferences restore across launches', () async {
    final store = MemoryLocalStore(); final first = PreferencesRepository(store); await first.load();
    await first.update(largerText: true, reduceMotion: true); first.dispose();
    final second = PreferencesRepository(store); await second.load();
    expect(second.largerText, isTrue); expect(second.reduceMotion, isTrue); second.dispose();
  });
}

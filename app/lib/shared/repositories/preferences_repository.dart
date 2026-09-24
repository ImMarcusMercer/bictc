import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:bictc/shared/repositories/local_store.dart';

class PreferencesRepository extends ChangeNotifier {
  PreferencesRepository(this.store);
  final LocalStore store;
  static const storageKey = 'accessph.preferences.v1';
  bool largerText = false;
  bool reduceMotion = false;
  bool busy = false;
  String? error;
  bool _disposed = false;
  Future<void>? _loading;
  Future<void> load() => _loading ??= _load();
  Future<void> _load() async {
    busy = true;
    try {
      final raw = await store.read(storageKey);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        largerText = data['larger_text'] == true;
        reduceMotion = data['reduce_motion'] == true;
      }
      error = null;
    } catch (_) {
      error =
          'Device preferences could not be loaded. Retry before changing them.';
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> retry() {
    _loading = null;
    return load();
  }

  Future<void> update({bool? largerText, bool? reduceMotion}) async {
    if (busy) return;
    if (error != null) throw StateError('Reload device preferences first.');
    busy = true;
    notifyListeners();
    final text = largerText ?? this.largerText;
    final motion = reduceMotion ?? this.reduceMotion;
    try {
      await store.write(
        storageKey,
        jsonEncode({'larger_text': text, 'reduce_motion': motion}),
      );
      this.largerText = text;
      this.reduceMotion = motion;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

import 'dart:async';

import 'package:bictc/app/supabase_config.dart';
import 'package:bictc/shared/models/community_report.dart';
import 'package:bictc/shared/repositories/session_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ReportsRepository extends SessionRepository {
  bool get canContribute;
  bool get isPreview;
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  Future<List<CommunityReport>> fetch({
    String? city,
    ReportStatus? status,
    int offset = 0,
  });

  /// False means the text was saved but photo attachment could not be confirmed.
  Future<bool> submit(ReportDraft draft);
  Future<void> setHelpful(String reportId, bool helpful);
  Future<String> photoUrl(String path);
}

ReportsRepository createReportsRepository() =>
    SupabaseConfig.fromEnvironment() == null
    ? PreviewReportsRepository()
    : SupabaseReportsRepository(Supabase.instance.client);

class SupabaseReportsRepository extends ReportsRepository {
  SupabaseReportsRepository(this._client) {
    _auth = _client.auth.onAuthStateChange.listen(
      (_) => notifyListeners(),
      onError: (Object _) => notifyListeners(),
    );
  }
  final SupabaseClient _client;
  late final StreamSubscription<AuthState> _auth;
  @override
  bool get canContribute =>
      _client.auth.currentSession != null &&
      _client.auth.currentUser != null &&
      !_client.auth.currentUser!.isAnonymous;
  @override
  bool get isPreview => false;
  @override
  String? get userId => canContribute ? _client.auth.currentUser!.id : null;
  @override
  String? get email => canContribute ? _client.auth.currentUser!.email : null;
  void _requireAccount() {
    if (!canContribute) throw StateError('Sign in before contributing.');
  }

  @override
  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
  @override
  Future<List<CommunityReport>> fetch({
    String? city,
    ReportStatus? status,
    int offset = 0,
  }) async {
    final rows = await _client.rpc(
      'community_report_feed',
      params: {
        'p_city': city,
        'p_status': status?.name,
        'p_offset': offset,
        'p_limit': 20,
      },
    );
    return (rows as List)
        .map(
          (row) =>
              CommunityReport.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  @override
  Future<bool> submit(ReportDraft draft) async {
    _requireAccount();
    final authorId = _client.auth.currentUser!.id;
    final row = await _client
        .from('reports')
        .insert({
          'author_id': authorId,
          'author_name': draft.author.trim(),
          'place_name': draft.place.trim(),
          'city': draft.city.trim(),
          'description': draft.description.trim(),
          'status': draft.status.name,
          'observed_at': draft.observedAt.toIso8601String().substring(0, 10),
        })
        .select('id')
        .single();
    final photo = draft.photo;
    if (photo == null) return true;
    final path = '$authorId/${row['id']}/evidence';
    try {
      _requireAccount();
      await _client.storage
          .from('report-photos')
          .uploadBinary(
            path,
            photo.bytes,
            fileOptions: FileOptions(contentType: photo.contentType),
          );
      await _client
          .from('reports')
          .update({'photo_path': path})
          .eq('id', row['id'] as String)
          .select('id')
          .single();
      return true;
    } catch (_) {
      // The attachment update may have committed even if its response was lost.
      // Preserve the object and report; trusted cleanup can remove true orphans.
      // Never repeat the report insert after an uncertain attachment response.
      return false;
    }
  }

  @override
  Future<void> setHelpful(String reportId, bool helpful) async {
    _requireAccount();
    final userId = _client.auth.currentUser!.id;
    if (helpful) {
      await _client.from('report_helpful').upsert({
        'report_id': reportId,
        'user_id': userId,
      }, ignoreDuplicates: true);
    } else {
      await _client
          .from('report_helpful')
          .delete()
          .eq('report_id', reportId)
          .eq('user_id', userId);
    }
  }

  @override
  Future<String> photoUrl(String path) =>
      _client.storage.from('report-photos').createSignedUrl(path, 600);
  @override
  void dispose() {
    unawaited(_auth.cancel());
    super.dispose();
  }
}

class PreviewReportsRepository extends ReportsRepository {
  @override
  bool get canContribute => false;
  @override
  bool get isPreview => true;
  @override
  Future<void> signIn(String email, String password) async =>
      throw StateError('Sign-in is unavailable in sample-data mode.');
  @override
  Future<void> signOut() async {}
  @override
  Future<bool> submit(ReportDraft draft) async =>
      throw StateError('Sign in before contributing.');
  @override
  Future<void> setHelpful(String reportId, bool helpful) async =>
      throw StateError('Sign in before contributing.');
  @override
  Future<String> photoUrl(String path) async =>
      throw StateError('No sample photos.');
  @override
  Future<List<CommunityReport>> fetch({
    String? city,
    ReportStatus? status,
    int offset = 0,
  }) async {
    final now = DateTime.now();
    final reports = [
      CommunityReport(
        id: 'sample-1',
        author: 'Maria Santos',
        place: 'Robinsons Galleria',
        city: 'Metro Manila',
        description: 'Elevator on Level 3 is under maintenance.\nOnly levels 1–2 accessible by elevator.\nEstimated 1 week repair.',
        status: ReportStatus.partial,
        observedAt: now,
        createdAt: now.subtract(const Duration(hours: 2)),
        helpfulCount: 27,
      ),
      CommunityReport(
        id: 'sample-2',
        author: 'Juan dela Cruz',
        place: 'SM City North EDSA',
        city: 'Metro Manila',
        description: 'The entrance ramp is clear and the elevator is working. Accessible toilet near the main lobby.',
        status: ReportStatus.accessible,
        observedAt: now,
        createdAt: now.subtract(const Duration(hours: 4)),
        helpfulCount: 18,
      ),
      CommunityReport(
        id: 'sample-3',
        author: 'Ana Reyes',
        place: 'Community Center',
        city: 'Davao',
        description: 'Steps at the entrance. No step-free route was available during my visit.',
        status: ReportStatus.barrier,
        observedAt: now,
        createdAt: now.subtract(const Duration(days: 1)),
        helpfulCount: 6,
      ),
    ];
    return reports
        .where(
          (r) =>
              (city == null || r.city == city) &&
              (status == null || r.status == status),
        )
        .skip(offset)
        .take(20)
        .toList();
  }
}

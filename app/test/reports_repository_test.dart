import 'dart:convert';
import 'dart:typed_data';

import 'package:bictc/shared/models/community_report.dart';
import 'package:bictc/shared/repositories/reports_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('uncertain attachment response preserves the uploaded object and never repeats the report insert', () async {
    var inserts = 0;
    var uploads = 0;
    var deletes = 0;
    const userId = '10000000-0000-4000-8000-000000000001';
    const reportId = '20000000-0000-4000-8000-000000000001';
    final transport = MockClient((request) async {
      if (request.url.path == '/auth/v1/token') {
        return http.Response(
          jsonEncode({
            'access_token': 'test-access-token',
            'refresh_token': 'test-refresh-token',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': userId,
              'aud': 'authenticated',
              'role': 'authenticated',
              'email': 'member@example.com',
              'app_metadata': {},
              'user_metadata': {},
              'created_at': '2026-09-24T00:00:00Z',
              'is_anonymous': false,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }
      if (request.url.path == '/rest/v1/reports') {
        if (request.method == 'POST') {
          inserts++;
          return http.Response(
            jsonEncode({'id': reportId}),
            201,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        if (request.method == 'PATCH') {
          // Simulate a committed attachment update whose response was lost.
          throw http.ClientException('Connection closed after commit');
        }
      }
      if (request.url.path.startsWith('/storage/v1/object/')) {
        if (request.method == 'DELETE') {
          deletes++;
        }
        if (request.method == 'POST') {
          uploads++;
        }
        return http.Response(
          jsonEncode({'Key': 'report-photos/$userId/$reportId/evidence'}),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }
      throw StateError(
        'Unexpected request: ${request.method} ${request.url.path}',
      );
    });
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: transport,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final repository = SupabaseReportsRepository(client);
    final draft = ReportDraft(
      author: 'Member',
      place: 'Hall',
      city: 'Cebu',
      description: 'Clear entrance ramp.',
      status: ReportStatus.accessible,
      observedAt: DateTime(2026, 9, 24),
      photo: ReportPhoto(Uint8List.fromList([255, 216, 255, 0])),
    );
    expect(repository.canContribute, isFalse);
    await expectLater(repository.submit(draft), throwsStateError);
    expect(inserts, 0);
    await repository.signIn('member@example.com', 'test-password');
    expect(repository.canContribute, isTrue);
    expect(await repository.submit(draft), isFalse);
    expect(inserts, 1);
    expect(uploads, 1);
    expect(deletes, 0);
    repository.dispose();
    await client.dispose();
  });
}

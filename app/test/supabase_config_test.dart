import 'package:bictc/app/supabase_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty configuration keeps preview available', () {
    expect(SupabaseConfig.parse(url: '', publishableKey: ''), isNull);
  });

  test('valid public configuration is normalized', () {
    final config = SupabaseConfig.parse(
      url: ' https://example.supabase.co ',
      publishableKey: ' sb_publishable_test ',
    )!;
    expect(config.url, 'https://example.supabase.co');
    expect(config.publishableKey, 'sb_publishable_test');
  });

  test('partial configuration is rejected', () {
    expect(
      () => SupabaseConfig.parse(
        url: 'https://example.supabase.co',
        publishableKey: '',
      ),
      throwsFormatException,
    );
    expect(
      () =>
          SupabaseConfig.parse(url: '', publishableKey: 'sb_publishable_test'),
      throwsFormatException,
    );
  });

  test('invalid URLs and non-publishable keys are rejected', () {
    for (final url in [
      'not-a-url',
      'ftp://example.com',
      'https://user:pass@example.com',
      'https://example.com?key=value',
    ]) {
      expect(
        () => SupabaseConfig.parse(
          url: url,
          publishableKey: 'sb_publishable_test',
        ),
        throwsFormatException,
      );
    }
    for (final key in [
      'sb_secret_test',
      'service_role',
      'sb_publishable_',
      'replace-me',
    ]) {
      expect(
        () => SupabaseConfig.parse(
          url: 'https://example.supabase.co',
          publishableKey: key,
        ),
        throwsFormatException,
      );
    }
  });
}

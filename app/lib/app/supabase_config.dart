/// Public build-time configuration; never put server credentials in this class.
class SupabaseConfig {
  const SupabaseConfig._({required this.url, required this.publishableKey});

  final String url;
  final String publishableKey;

  static SupabaseConfig? fromEnvironment() => parse(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

  /// Both values omitted means the existing sample-data preview can run.
  /// Partial or invalid configuration must not silently look connected.
  static SupabaseConfig? parse({
    required String url,
    required String publishableKey,
  }) {
    final normalizedUrl = url.trim();
    final normalizedKey = publishableKey.trim();
    if (normalizedUrl.isEmpty && normalizedKey.isEmpty) return null;

    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null ||
        !['https', 'http'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw const FormatException('Set SUPABASE_URL to the project base URL.');
    }
    if (!RegExp(r'^sb_publishable_[A-Za-z0-9_-]+$').hasMatch(normalizedKey)) {
      throw const FormatException(
        'Set SUPABASE_PUBLISHABLE_KEY to a publishable key from Supabase Connect.',
      );
    }
    return SupabaseConfig._(url: normalizedUrl, publishableKey: normalizedKey);
  }
}

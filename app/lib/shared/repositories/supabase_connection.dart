import 'package:bictc/app/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initializes the shared client for future repository adapters.
/// Initialization alone does not verify remote credentials or create tables.
Future<void> initializeSupabase() async {
  final config = SupabaseConfig.fromEnvironment();
  if (config == null) return;

  try {
    await Supabase.initialize(
      url: config.url,
      publishableKey: config.publishableKey,
      debug: false,
    );
  } catch (_) {
    // The SDK can set its initialized flag before session storage finishes.
    // Reset a partial initialization so a retry actually initializes again.
    try {
      await Supabase.instance.dispose();
    } catch (_) {
      // There may be no client yet. Preserve the original startup failure.
    }
    rethrow;
  }
}

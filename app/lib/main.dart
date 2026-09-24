import 'package:bictc/app/app_bootstrap.dart';
import 'package:bictc/shared/repositories/supabase_connection.dart';
import 'package:flutter/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrap(initialize: initializeSupabase));
}

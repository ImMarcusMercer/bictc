import 'package:flutter/foundation.dart';

/// Session state shared by reports, favorites, and account settings.
abstract class SessionRepository extends ChangeNotifier {
  bool get canContribute;
  bool get isPreview;
  String? get userId => null;
  String? get email => null;
  Future<void> signIn(String email, String password);
  Future<void> signOut();
}

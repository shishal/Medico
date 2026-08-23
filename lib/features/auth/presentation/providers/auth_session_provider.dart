import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_session_provider.g.dart';

/// Stub session flag for Phase 3.1 navigation. Phase 3.2 replaces this with
/// real Supabase Auth state.
@Riverpod(keepAlive: true)
class AuthSession extends _$AuthSession {
  @override
  bool build() => false;

  void signIn() => state = true;

  void signOut() => state = false;
}

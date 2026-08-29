import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/user_facing_error.dart';
import '../domain/auth_failure.dart';

part 'auth_repository.g.dart';

/// Talks to Supabase Auth — presentation never calls the client directly.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  bool get isSignedIn => _client.auth.currentSession != null;

  /// Prefill only — checkout still requires a password on the web page.
  String? get currentEmail => _client.auth.currentUser?.email;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<Result<void>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signUp(email: email, password: password);
      return const Success(null);
    } on AuthException catch (e) {
      return Failure(AuthFailure.fromException(e));
    } catch (e) {
      return Failure(
        UserFacingError.from(
          e,
          fallback: 'Something went wrong. Please try again.',
        ),
      );
    }
  }

  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return const Success(null);
    } on AuthException catch (e) {
      return Failure(AuthFailure.fromException(e));
    } catch (e) {
      return Failure(
        UserFacingError.from(
          e,
          fallback: 'Something went wrong. Please try again.',
        ),
      );
    }
  }

  Future<Result<void>> signOut() async {
    try {
      await _client.auth.signOut();
      return const Success(null);
    } on AuthException catch (e) {
      return Failure(AuthFailure.fromException(e));
    } catch (e) {
      return Failure(
        UserFacingError.from(
          e,
          fallback: 'Could not sign out. Please try again.',
        ),
      );
    }
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
}

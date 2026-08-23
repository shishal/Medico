import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/auth_repository.dart';

part 'auth_session_provider.g.dart';

/// Whether a Supabase session is active. Listens to auth state changes so the
/// router and splash screen stay in sync after login, logout, or app restart.
@Riverpod(keepAlive: true)
class AuthSession extends _$AuthSession {
  @override
  bool build() {
    final repository = ref.watch(authRepositoryProvider);

    final subscription = repository.authStateChanges.listen((event) {
      state = event.session != null;
    });
    ref.onDispose(subscription.cancel);

    return repository.isSignedIn;
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }
}

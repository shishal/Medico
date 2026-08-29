import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/result.dart';
import '../../../auth/presentation/providers/auth_session_provider.dart';
import '../../data/profile_repository.dart';
import '../../domain/user_profile.dart';

part 'user_profile_provider.g.dart';

/// Logged-in user's `profiles` row. Rebuilds on sign-in/out; call [refresh]
/// after you know the row changed (e.g. plan expiry tweaked in Supabase).
@Riverpod(keepAlive: true)
class UserProfileNotifier extends _$UserProfileNotifier {
  @override
  Future<UserProfile?> build() async {
    final isSignedIn = ref.watch(authSessionProvider);
    if (!isSignedIn) return null;

    final result = await ref.read(profileRepositoryProvider).fetchOwnProfile();
    return switch (result) {
      Success(:final value) => value,
      Failure(:final message) => throw Exception(message),
    };
  }

  /// Re-fetch from Supabase so UI picks up plan changes without restarting.
  /// [currentPlanProvider] watches this notifier, so it refreshes too.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

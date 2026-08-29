// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Logged-in user's `profiles` row. Rebuilds on sign-in/out; call [refresh]
/// after you know the row changed (e.g. plan expiry tweaked in Supabase).

@ProviderFor(UserProfileNotifier)
final userProfileProvider = UserProfileNotifierProvider._();

/// Logged-in user's `profiles` row. Rebuilds on sign-in/out; call [refresh]
/// after you know the row changed (e.g. plan expiry tweaked in Supabase).
final class UserProfileNotifierProvider
    extends $AsyncNotifierProvider<UserProfileNotifier, UserProfile?> {
  /// Logged-in user's `profiles` row. Rebuilds on sign-in/out; call [refresh]
  /// after you know the row changed (e.g. plan expiry tweaked in Supabase).
  UserProfileNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProfileProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userProfileNotifierHash();

  @$internal
  @override
  UserProfileNotifier create() => UserProfileNotifier();
}

String _$userProfileNotifierHash() =>
    r'63d74308eb81617cc0f71e3de8d4e2ab6669899a';

/// Logged-in user's `profiles` row. Rebuilds on sign-in/out; call [refresh]
/// after you know the row changed (e.g. plan expiry tweaked in Supabase).

abstract class _$UserProfileNotifier extends $AsyncNotifier<UserProfile?> {
  FutureOr<UserProfile?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<UserProfile?>, UserProfile?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UserProfile?>, UserProfile?>,
              AsyncValue<UserProfile?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

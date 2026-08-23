// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether a Supabase session is active. Listens to auth state changes so the
/// router and splash screen stay in sync after login, logout, or app restart.

@ProviderFor(AuthSession)
final authSessionProvider = AuthSessionProvider._();

/// Whether a Supabase session is active. Listens to auth state changes so the
/// router and splash screen stay in sync after login, logout, or app restart.
final class AuthSessionProvider extends $NotifierProvider<AuthSession, bool> {
  /// Whether a Supabase session is active. Listens to auth state changes so the
  /// router and splash screen stay in sync after login, logout, or app restart.
  AuthSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authSessionHash();

  @$internal
  @override
  AuthSession create() => AuthSession();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$authSessionHash() => r'd05f5cf9fc4dd4ca4c211eae1e05033192c7785c';

/// Whether a Supabase session is active. Listens to auth state changes so the
/// router and splash screen stay in sync after login, logout, or app restart.

abstract class _$AuthSession extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

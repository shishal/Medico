// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stub session flag for Phase 3.1 navigation. Phase 3.2 replaces this with
/// real Supabase Auth state.

@ProviderFor(AuthSession)
final authSessionProvider = AuthSessionProvider._();

/// Stub session flag for Phase 3.1 navigation. Phase 3.2 replaces this with
/// real Supabase Auth state.
final class AuthSessionProvider extends $NotifierProvider<AuthSession, bool> {
  /// Stub session flag for Phase 3.1 navigation. Phase 3.2 replaces this with
  /// real Supabase Auth state.
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

String _$authSessionHash() => r'de0d4b1a0847905a1f1b4ef724f2bd2daca00a9c';

/// Stub session flag for Phase 3.1 navigation. Phase 3.2 replaces this with
/// real Supabase Auth state.

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

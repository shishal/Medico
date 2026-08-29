// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_attempt_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(localAttemptStore)
final localAttemptStoreProvider = LocalAttemptStoreProvider._();

final class LocalAttemptStoreProvider
    extends
        $FunctionalProvider<
          LocalAttemptStore,
          LocalAttemptStore,
          LocalAttemptStore
        >
    with $Provider<LocalAttemptStore> {
  LocalAttemptStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localAttemptStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localAttemptStoreHash();

  @$internal
  @override
  $ProviderElement<LocalAttemptStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalAttemptStore create(Ref ref) {
    return localAttemptStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalAttemptStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalAttemptStore>(value),
    );
  }
}

String _$localAttemptStoreHash() => r'f1d0f902477c1e989081c924c371b6937db93dcf';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tests_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(testsRepository)
final testsRepositoryProvider = TestsRepositoryProvider._();

final class TestsRepositoryProvider
    extends
        $FunctionalProvider<TestsRepository, TestsRepository, TestsRepository>
    with $Provider<TestsRepository> {
  TestsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'testsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$testsRepositoryHash();

  @$internal
  @override
  $ProviderElement<TestsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TestsRepository create(Ref ref) {
    return testsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TestsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TestsRepository>(value),
    );
  }
}

String _$testsRepositoryHash() => r'e8ef779dc58eec9b157aa2707cade66a2a655523';

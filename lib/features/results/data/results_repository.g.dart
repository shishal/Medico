// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'results_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(resultsRepository)
final resultsRepositoryProvider = ResultsRepositoryProvider._();

final class ResultsRepositoryProvider
    extends
        $FunctionalProvider<
          ResultsRepository,
          ResultsRepository,
          ResultsRepository
        >
    with $Provider<ResultsRepository> {
  ResultsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resultsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resultsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ResultsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ResultsRepository create(Ref ref) {
    return resultsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResultsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResultsRepository>(value),
    );
  }
}

String _$resultsRepositoryHash() => r'60e3fa911484b01b7ca67916e6fb154c255f37c2';

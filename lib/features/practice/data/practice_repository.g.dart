// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(practiceRepository)
final practiceRepositoryProvider = PracticeRepositoryProvider._();

final class PracticeRepositoryProvider
    extends
        $FunctionalProvider<
          PracticeRepository,
          PracticeRepository,
          PracticeRepository
        >
    with $Provider<PracticeRepository> {
  PracticeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'practiceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$practiceRepositoryHash();

  @$internal
  @override
  $ProviderElement<PracticeRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PracticeRepository create(Ref ref) {
    return practiceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PracticeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PracticeRepository>(value),
    );
  }
}

String _$practiceRepositoryHash() =>
    r'70ad191c6678489e1d58b9acbf9dddeae2cc07c5';

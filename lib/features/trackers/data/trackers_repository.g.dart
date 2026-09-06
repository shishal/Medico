// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trackers_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(trackersRepository)
final trackersRepositoryProvider = TrackersRepositoryProvider._();

final class TrackersRepositoryProvider
    extends
        $FunctionalProvider<
          TrackersRepository,
          TrackersRepository,
          TrackersRepository
        >
    with $Provider<TrackersRepository> {
  TrackersRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trackersRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trackersRepositoryHash();

  @$internal
  @override
  $ProviderElement<TrackersRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TrackersRepository create(Ref ref) {
    return trackersRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrackersRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrackersRepository>(value),
    );
  }
}

String _$trackersRepositoryHash() =>
    r'7fdb93c30967898666abda7c3d0fe1bbdad1b9c2';

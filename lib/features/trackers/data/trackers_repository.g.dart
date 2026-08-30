// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trackers_repository.dart';

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

  Override overrideWithValue(TrackersRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrackersRepository>(value),
    );
  }
}

String _$trackersRepositoryHash() =>
    r'4444444444444444444444444444444444444444';

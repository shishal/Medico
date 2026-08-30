// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pyq_repository.dart';

@ProviderFor(pyqRepository)
final pyqRepositoryProvider = PyqRepositoryProvider._();

final class PyqRepositoryProvider
    extends $FunctionalProvider<PyqRepository, PyqRepository, PyqRepository>
    with $Provider<PyqRepository> {
  PyqRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pyqRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pyqRepositoryHash();

  @$internal
  @override
  $ProviderElement<PyqRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PyqRepository create(Ref ref) {
    return pyqRepository(ref);
  }

  Override overrideWithValue(PyqRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PyqRepository>(value),
    );
  }
}

String _$pyqRepositoryHash() => r'2222222222222222222222222222222222222222';

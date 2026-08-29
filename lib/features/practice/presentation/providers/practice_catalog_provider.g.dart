// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_catalog_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Subjects, topics, and tags for the Practice Builder.

@ProviderFor(PracticeCatalogNotifier)
final practiceCatalogProvider = PracticeCatalogNotifierProvider._();

/// Subjects, topics, and tags for the Practice Builder.
final class PracticeCatalogNotifierProvider
    extends $AsyncNotifierProvider<PracticeCatalogNotifier, PracticeCatalog> {
  /// Subjects, topics, and tags for the Practice Builder.
  PracticeCatalogNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'practiceCatalogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$practiceCatalogNotifierHash();

  @$internal
  @override
  PracticeCatalogNotifier create() => PracticeCatalogNotifier();
}

String _$practiceCatalogNotifierHash() =>
    r'ff850c358aba3f15249d92814185f67b266588d3';

/// Subjects, topics, and tags for the Practice Builder.

abstract class _$PracticeCatalogNotifier
    extends $AsyncNotifier<PracticeCatalog> {
  FutureOr<PracticeCatalog> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PracticeCatalog>, PracticeCatalog>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PracticeCatalog>, PracticeCatalog>,
              AsyncValue<PracticeCatalog>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

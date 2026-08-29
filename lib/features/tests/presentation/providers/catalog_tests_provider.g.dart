// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_tests_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Catalog tests the current user's plan is allowed to see (via RLS).
///
/// Rebuilds on sign-in/out. Call [refresh] after you expect the set to change
/// (e.g. plan upgrade reflected in Supabase).

@ProviderFor(CatalogTestsNotifier)
final catalogTestsProvider = CatalogTestsNotifierProvider._();

/// Catalog tests the current user's plan is allowed to see (via RLS).
///
/// Rebuilds on sign-in/out. Call [refresh] after you expect the set to change
/// (e.g. plan upgrade reflected in Supabase).
final class CatalogTestsNotifierProvider
    extends $AsyncNotifierProvider<CatalogTestsNotifier, List<CatalogTest>> {
  /// Catalog tests the current user's plan is allowed to see (via RLS).
  ///
  /// Rebuilds on sign-in/out. Call [refresh] after you expect the set to change
  /// (e.g. plan upgrade reflected in Supabase).
  CatalogTestsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogTestsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogTestsNotifierHash();

  @$internal
  @override
  CatalogTestsNotifier create() => CatalogTestsNotifier();
}

String _$catalogTestsNotifierHash() =>
    r'22367ea96150411a24a70559b468005903d917b3';

/// Catalog tests the current user's plan is allowed to see (via RLS).
///
/// Rebuilds on sign-in/out. Call [refresh] after you expect the set to change
/// (e.g. plan upgrade reflected in Supabase).

abstract class _$CatalogTestsNotifier
    extends $AsyncNotifier<List<CatalogTest>> {
  FutureOr<List<CatalogTest>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<CatalogTest>>, List<CatalogTest>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<CatalogTest>>, List<CatalogTest>>,
              AsyncValue<List<CatalogTest>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmarks_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Question IDs the signed-in user has bookmarked. Persists in Supabase;
/// this set is only a cache so the review-screen icon can toggle instantly.

@ProviderFor(BookmarkedIds)
final bookmarkedIdsProvider = BookmarkedIdsProvider._();

/// Question IDs the signed-in user has bookmarked. Persists in Supabase;
/// this set is only a cache so the review-screen icon can toggle instantly.
final class BookmarkedIdsProvider
    extends $AsyncNotifierProvider<BookmarkedIds, Set<String>> {
  /// Question IDs the signed-in user has bookmarked. Persists in Supabase;
  /// this set is only a cache so the review-screen icon can toggle instantly.
  BookmarkedIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookmarkedIdsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookmarkedIdsHash();

  @$internal
  @override
  BookmarkedIds create() => BookmarkedIds();
}

String _$bookmarkedIdsHash() => r'd00e80c41caf0f5e96806f13ce68d1e4a776e29e';

/// Question IDs the signed-in user has bookmarked. Persists in Supabase;
/// this set is only a cache so the review-screen icon can toggle instantly.

abstract class _$BookmarkedIds extends $AsyncNotifier<Set<String>> {
  FutureOr<Set<String>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Set<String>>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Set<String>>, Set<String>>,
              AsyncValue<Set<String>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Full bookmark rows for "My Bookmarks". Plan-locked questions stay in the
/// list as placeholders — we still have the id, just not the stem.

@ProviderFor(bookmarksList)
final bookmarksListProvider = BookmarksListProvider._();

/// Full bookmark rows for "My Bookmarks". Plan-locked questions stay in the
/// list as placeholders — we still have the id, just not the stem.

final class BookmarksListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BookmarkedQuestion>>,
          List<BookmarkedQuestion>,
          FutureOr<List<BookmarkedQuestion>>
        >
    with
        $FutureModifier<List<BookmarkedQuestion>>,
        $FutureProvider<List<BookmarkedQuestion>> {
  /// Full bookmark rows for "My Bookmarks". Plan-locked questions stay in the
  /// list as placeholders — we still have the id, just not the stem.
  BookmarksListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookmarksListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookmarksListHash();

  @$internal
  @override
  $FutureProviderElement<List<BookmarkedQuestion>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BookmarkedQuestion>> create(Ref ref) {
    return bookmarksList(ref);
  }
}

String _$bookmarksListHash() => r'40311f49469854dd8d175f3974d9d17238c10956';

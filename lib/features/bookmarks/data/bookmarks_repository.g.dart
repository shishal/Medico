// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmarks_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bookmarksRepository)
final bookmarksRepositoryProvider = BookmarksRepositoryProvider._();

final class BookmarksRepositoryProvider
    extends
        $FunctionalProvider<
          BookmarksRepository,
          BookmarksRepository,
          BookmarksRepository
        >
    with $Provider<BookmarksRepository> {
  BookmarksRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookmarksRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookmarksRepositoryHash();

  @$internal
  @override
  $ProviderElement<BookmarksRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BookmarksRepository create(Ref ref) {
    return bookmarksRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BookmarksRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BookmarksRepository>(value),
    );
  }
}

String _$bookmarksRepositoryHash() =>
    r'77773e839d728b4f0d62b1530c5953cae992d0bf';

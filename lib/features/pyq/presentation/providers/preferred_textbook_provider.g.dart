// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferred_textbook_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Local textbook preference so PYQ cards highlight one citation first.

@ProviderFor(PreferredTextbook)
final preferredTextbookProvider = PreferredTextbookProvider._();

/// Local textbook preference so PYQ cards highlight one citation first.
final class PreferredTextbookProvider
    extends $NotifierProvider<PreferredTextbook, String?> {
  /// Local textbook preference so PYQ cards highlight one citation first.
  PreferredTextbookProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preferredTextbookProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preferredTextbookHash();

  @$internal
  @override
  PreferredTextbook create() => PreferredTextbook();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$preferredTextbookHash() => r'3f1c495c327a3297dc587c2dd51185325fa0559d';

/// Local textbook preference so PYQ cards highlight one citation first.

abstract class _$PreferredTextbook extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

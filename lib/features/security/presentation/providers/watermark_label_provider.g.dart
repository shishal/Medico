// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watermark_label_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Identity tiled over question content. Email comes from Auth (always
/// present when signed in); name/phone come from `profiles` when set.
///
/// Watches [userProfileProvider] as [AsyncValue] so a profile load/error
/// still leaves the email watermark visible.

@ProviderFor(watermarkLabel)
final watermarkLabelProvider = WatermarkLabelProvider._();

/// Identity tiled over question content. Email comes from Auth (always
/// present when signed in); name/phone come from `profiles` when set.
///
/// Watches [userProfileProvider] as [AsyncValue] so a profile load/error
/// still leaves the email watermark visible.

final class WatermarkLabelProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Identity tiled over question content. Email comes from Auth (always
  /// present when signed in); name/phone come from `profiles` when set.
  ///
  /// Watches [userProfileProvider] as [AsyncValue] so a profile load/error
  /// still leaves the email watermark visible.
  WatermarkLabelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watermarkLabelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watermarkLabelHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return watermarkLabel(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$watermarkLabelHash() => r'0b36a8306cbdcf4d35396320f00bb51d5d70d1a3';

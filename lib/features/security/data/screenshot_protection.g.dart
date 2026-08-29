// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screenshot_protection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(screenshotProtection)
final screenshotProtectionProvider = ScreenshotProtectionProvider._();

final class ScreenshotProtectionProvider
    extends
        $FunctionalProvider<
          ScreenshotProtection,
          ScreenshotProtection,
          ScreenshotProtection
        >
    with $Provider<ScreenshotProtection> {
  ScreenshotProtectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'screenshotProtectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$screenshotProtectionHash();

  @$internal
  @override
  $ProviderElement<ScreenshotProtection> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ScreenshotProtection create(Ref ref) {
    return screenshotProtection(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScreenshotProtection value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScreenshotProtection>(value),
    );
  }
}

String _$screenshotProtectionHash() =>
    r'84c3943a5b17c5845f9621d5aff7f4cafdf5c26c';

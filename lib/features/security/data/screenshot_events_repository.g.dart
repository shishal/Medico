// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screenshot_events_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(screenshotEventsRepository)
final screenshotEventsRepositoryProvider =
    ScreenshotEventsRepositoryProvider._();

final class ScreenshotEventsRepositoryProvider
    extends
        $FunctionalProvider<
          ScreenshotEventsRepository,
          ScreenshotEventsRepository,
          ScreenshotEventsRepository
        >
    with $Provider<ScreenshotEventsRepository> {
  ScreenshotEventsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'screenshotEventsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$screenshotEventsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ScreenshotEventsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ScreenshotEventsRepository create(Ref ref) {
    return screenshotEventsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScreenshotEventsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScreenshotEventsRepository>(value),
    );
  }
}

String _$screenshotEventsRepositoryHash() =>
    r'3bac4c87b4e79161a19a286e9b11299b043efab6';

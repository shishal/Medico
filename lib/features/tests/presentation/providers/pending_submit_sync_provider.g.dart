// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_submit_sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-open submit retry (spec §4). Watched from [HomeScreen] so it runs
/// after sign-in even when the student is not on the player.

@ProviderFor(PendingSubmitSync)
final pendingSubmitSyncProvider = PendingSubmitSyncProvider._();

/// App-open submit retry (spec §4). Watched from [HomeScreen] so it runs
/// after sign-in even when the student is not on the player.
final class PendingSubmitSyncProvider
    extends $AsyncNotifierProvider<PendingSubmitSync, void> {
  /// App-open submit retry (spec §4). Watched from [HomeScreen] so it runs
  /// after sign-in even when the student is not on the player.
  PendingSubmitSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingSubmitSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingSubmitSyncHash();

  @$internal
  @override
  PendingSubmitSync create() => PendingSubmitSync();
}

String _$pendingSubmitSyncHash() => r'6faebf9b697cf219275a9f54abdc1f209db9ab11';

/// App-open submit retry (spec §4). Watched from [HomeScreen] so it runs
/// after sign-in even when the student is not on the player.

abstract class _$PendingSubmitSync extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

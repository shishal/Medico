// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_submit_sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-open submit retry (spec §4). Watched from [MedicoApp] so it runs even
/// when the student is not on the player screen.

@ProviderFor(PendingSubmitSync)
final pendingSubmitSyncProvider = PendingSubmitSyncProvider._();

/// App-open submit retry (spec §4). Watched from [MedicoApp] so it runs even
/// when the student is not on the player screen.
final class PendingSubmitSyncProvider
    extends $AsyncNotifierProvider<PendingSubmitSync, void> {
  /// App-open submit retry (spec §4). Watched from [MedicoApp] so it runs even
  /// when the student is not on the player screen.
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

String _$pendingSubmitSyncHash() => r'c3d7f1aaf06e881dc5714f67dd7da07794f4da6d';

/// App-open submit retry (spec §4). Watched from [MedicoApp] so it runs even
/// when the student is not on the player screen.

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

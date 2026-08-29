// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// In-memory player for one [testId] (a Riverpod *family* — each testId gets
/// its own notifier). Branches on `feedback_timing` inside
/// [PlayerSessionState] — there is no second Tutor Mode screen.
///
/// Attempt creation / autosave is Phase 5.1; this notifier only holds the
/// session the UI needs for 4B.3.

@ProviderFor(PlayerSession)
final playerSessionProvider = PlayerSessionFamily._();

/// In-memory player for one [testId] (a Riverpod *family* — each testId gets
/// its own notifier). Branches on `feedback_timing` inside
/// [PlayerSessionState] — there is no second Tutor Mode screen.
///
/// Attempt creation / autosave is Phase 5.1; this notifier only holds the
/// session the UI needs for 4B.3.
final class PlayerSessionProvider
    extends $AsyncNotifierProvider<PlayerSession, PlayerSessionState> {
  /// In-memory player for one [testId] (a Riverpod *family* — each testId gets
  /// its own notifier). Branches on `feedback_timing` inside
  /// [PlayerSessionState] — there is no second Tutor Mode screen.
  ///
  /// Attempt creation / autosave is Phase 5.1; this notifier only holds the
  /// session the UI needs for 4B.3.
  PlayerSessionProvider._({
    required PlayerSessionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'playerSessionProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playerSessionHash();

  @override
  String toString() {
    return r'playerSessionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PlayerSession create() => PlayerSession();

  @override
  bool operator ==(Object other) {
    return other is PlayerSessionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playerSessionHash() => r'd8162bd2f58c38b1f9441532a4cd5c063e8e043d';

/// In-memory player for one [testId] (a Riverpod *family* — each testId gets
/// its own notifier). Branches on `feedback_timing` inside
/// [PlayerSessionState] — there is no second Tutor Mode screen.
///
/// Attempt creation / autosave is Phase 5.1; this notifier only holds the
/// session the UI needs for 4B.3.

final class PlayerSessionFamily extends $Family
    with
        $ClassFamilyOverride<
          PlayerSession,
          AsyncValue<PlayerSessionState>,
          PlayerSessionState,
          FutureOr<PlayerSessionState>,
          String
        > {
  PlayerSessionFamily._()
    : super(
        retry: null,
        name: r'playerSessionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// In-memory player for one [testId] (a Riverpod *family* — each testId gets
  /// its own notifier). Branches on `feedback_timing` inside
  /// [PlayerSessionState] — there is no second Tutor Mode screen.
  ///
  /// Attempt creation / autosave is Phase 5.1; this notifier only holds the
  /// session the UI needs for 4B.3.

  PlayerSessionProvider call(String testId) =>
      PlayerSessionProvider._(argument: testId, from: this);

  @override
  String toString() => r'playerSessionProvider';
}

/// In-memory player for one [testId] (a Riverpod *family* — each testId gets
/// its own notifier). Branches on `feedback_timing` inside
/// [PlayerSessionState] — there is no second Tutor Mode screen.
///
/// Attempt creation / autosave is Phase 5.1; this notifier only holds the
/// session the UI needs for 4B.3.

abstract class _$PlayerSession extends $AsyncNotifier<PlayerSessionState> {
  late final _$args = ref.$arg as String;
  String get testId => _$args;

  FutureOr<PlayerSessionState> build(String testId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<PlayerSessionState>, PlayerSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PlayerSessionState>, PlayerSessionState>,
              AsyncValue<PlayerSessionState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

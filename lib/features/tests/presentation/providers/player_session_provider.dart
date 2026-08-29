import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/result.dart';
import '../../../auth/presentation/providers/auth_session_provider.dart';
import '../../data/local_attempt_store.dart';
import '../../data/tests_repository.dart';
import '../../domain/attempt_status.dart';
import '../../domain/player_session_state.dart';
import '../../domain/question_option.dart';

part 'player_session_provider.g.dart';

/// Player for one [testId]. Creates or resumes an `attempts` row, downloads
/// questions, and autosaves answers to a local JSON file (spec §4).
@Riverpod(keepAlive: true)
class PlayerSession extends _$PlayerSession {
  static const _saveDebounce = Duration(milliseconds: 500);

  Timer? _saveTimer;
  DateTime? _questionVisibleSince;
  String? _userId;
  LocalAttemptStore? _store;

  @override
  Future<PlayerSessionState> build(String testId) async {
    ref.onDispose(_tearDown);

    final signedIn = ref.watch(authSessionProvider);
    final repo = ref.read(testsRepositoryProvider);
    final store = ref.read(localAttemptStoreProvider);
    _store = store;
    final userId = repo.currentUserId;
    if (!signedIn || userId == null) {
      throw Exception('Not signed in.');
    }
    _userId = userId;

    final local = await store.readInProgressForTest(
      testId: testId,
      userId: userId,
    );

    if (local != null && local.questions.isNotEmpty) {
      final remote = await repo.fetchAttempt(local.attemptId);
      final stillOpen = switch (remote) {
        Failure() => true, // Offline: trust the local file.
        Success(:final value) when value == null => false,
        Success(:final value) => value!.status == AttemptStatus.inProgress,
      };
      if (!stillOpen) {
        await store.delete(local.attemptId);
      } else {
        _questionVisibleSince = DateTime.now();
        return PlayerSessionState.fromSnapshot(local);
      }
    }

    final bundleResult = await repo.fetchPlayerBundle(testId);
    final bundle = switch (bundleResult) {
      Success(:final value) => value,
      Failure(:final message) => throw Exception(message),
    };

    final attemptResult = await repo.startOrResumeAttempt(testId);
    final attempt = switch (attemptResult) {
      Success(:final value) => value,
      Failure(:final message) => throw Exception(message),
    };

    var session = PlayerSessionState.fromBundle(
      bundle,
      attemptId: attempt.id,
      startedAt: attempt.startedAt,
    );
    if (local != null && local.attemptId == attempt.id) {
      session = session.restoreProgress(
        savedAnswers: local.answers,
        savedIndex: local.currentIndex,
        savedSectionStartedAt: local.sectionStartedAt,
      );
    }

    await store.write(session.toSnapshot(userId: userId));
    _questionVisibleSince = DateTime.now();
    return session;
  }

  void selectOption(QuestionOption option) =>
      _update((session) => session.selectOption(option));

  void clearResponse() => _update((session) => session.clearResponse());

  void toggleMark() => _update((session) => session.toggleMark());

  void markForReviewAndNext() =>
      _update((session) => session.markForReviewAndNext());

  void saveAndNext() => _update((session) => session.saveAndNext());

  void previous() => _update((session) => session.previous());

  void goTo(int index) => _update((session) => session.goTo(index));

  /// Write immediately (leaving the player, app backgrounded, force-quit window).
  Future<void> flushSave() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    await _persist();
  }

  void _update(PlayerSessionState Function(PlayerSessionState) fn) {
    final current = state.value;
    if (current == null) return;
    final timed = _applyElapsed(current);
    state = AsyncData(fn(timed));
    _questionVisibleSince = DateTime.now();
    _scheduleSave();
  }

  PlayerSessionState _applyElapsed(PlayerSessionState session) {
    final since = _questionVisibleSince;
    if (since == null) return session;
    final extra = DateTime.now().difference(since).inSeconds;
    return session.addTimeToCurrent(extra);
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounce, () {
      unawaited(_persist());
    });
  }

  Future<void> _persist() async {
    final userId = _userId;
    final current = state.value;
    final store = _store;
    if (userId == null || current == null || store == null) return;
    final timed = _applyElapsed(current);
    if (!identical(timed, current)) {
      state = AsyncData(timed);
      _questionVisibleSince = DateTime.now();
    }
    await store.write(timed.toSnapshot(userId: userId));
  }

  void _tearDown() {
    _saveTimer?.cancel();
    _saveTimer = null;
    final userId = _userId;
    final current = state.value;
    final store = _store;
    if (userId == null || current == null || store == null) return;
    final timed = _applyElapsed(current);
    unawaited(store.write(timed.toSnapshot(userId: userId)));
  }
}

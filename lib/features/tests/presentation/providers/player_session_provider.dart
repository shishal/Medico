import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/result.dart';
import '../../data/tests_repository.dart';
import '../../domain/player_session_state.dart';
import '../../domain/question_option.dart';

part 'player_session_provider.g.dart';

/// In-memory player for one [testId] (a Riverpod *family* — each testId gets
/// its own notifier). Branches on `feedback_timing` inside
/// [PlayerSessionState] — there is no second Tutor Mode screen.
///
/// Attempt creation / autosave is Phase 5.1; this notifier only holds the
/// session the UI needs for 4B.3.
@Riverpod(keepAlive: true)
class PlayerSession extends _$PlayerSession {
  @override
  Future<PlayerSessionState> build(String testId) async {
    final result = await ref
        .read(testsRepositoryProvider)
        .fetchPlayerBundle(testId);
    return switch (result) {
      Success(:final value) => PlayerSessionState.fromBundle(value),
      Failure(:final message) => throw Exception(message),
    };
  }

  void selectOption(QuestionOption option) =>
      _update((session) => session.selectOption(option));

  void clearResponse() => _update((session) => session.clearResponse());

  void toggleMark() => _update((session) => session.toggleMark());

  void markForReviewAndNext() =>
      _update((session) => session.markForReviewAndNext());

  void saveAndNext() => _update((session) => session.saveAndNext());

  void goTo(int index) => _update((session) => session.goTo(index));

  void _update(PlayerSessionState Function(PlayerSessionState) fn) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(fn(current));
  }
}

import '../../../core/utils/result.dart';
import '../../../core/utils/wall_clock.dart';
import '../domain/attempt_status.dart';
import '../domain/attempt_submit_request.dart';
import '../domain/player_session_state.dart';
import 'local_attempt_store.dart';
import 'tests_repository.dart';

/// Completes `pending_submit` (and timer-expired in-progress) snapshots.
///
/// Spec §4: retry on app open, not only while the player is on screen.
class PendingAttemptReconciler {
  PendingAttemptReconciler({
    required this.repository,
    required this.store,
    WallClock? clock,
  }) : clock = clock ?? WallClock();

  final TestsRepository repository;
  final LocalAttemptStore store;
  final WallClock clock;

  /// How many snapshots still need the network. 0 means nothing left to retry.
  Future<int> reconcile({required String userId}) async {
    var nowClock = clock;
    final server = await repository.fetchServerNow();
    if (server is Success<DateTime>) {
      nowClock = nowClock.reconcile(
        serverNow: server.value,
        localNow: DateTime.now(),
      );
    }
    final now = nowClock.now();

    final snapshots = await store.listForUser(userId);
    var remaining = 0;

    for (final snapshot in snapshots) {
      var session = PlayerSessionState.fromSnapshot(snapshot);
      session = session.applyTimerExpiry(now);
      if (!session.isPendingSubmit) continue;

      if (snapshot.localStatus != LocalAttemptStatus.pendingSubmit) {
        await store.write(session.toSnapshot(userId: userId));
      }

      final result = await repository.submitAttempt(
        AttemptSubmitRequest.fromSession(session),
      );
      switch (result) {
        case Success():
          await store.delete(session.attemptId);
        case Failure(:final message) when isTerminalSubmitFailure(message):
          if (message != 'Not signed in.') {
            await store.delete(session.attemptId);
          } else {
            remaining++;
          }
        case Failure():
          remaining++;
      }
    }

    return remaining;
  }
}

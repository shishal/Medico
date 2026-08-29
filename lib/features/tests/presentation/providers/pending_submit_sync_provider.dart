import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/auth_session_provider.dart';
import '../../data/local_attempt_store.dart';
import '../../data/pending_attempt_reconciler.dart';
import '../../data/tests_repository.dart';
import '../../domain/submit_backoff.dart';
import 'in_progress_attempts_provider.dart';

part 'pending_submit_sync_provider.g.dart';

/// App-open submit retry (spec §4). Watched from [HomeScreen] so it runs
/// after sign-in even when the student is not on the player.
@Riverpod(keepAlive: true)
class PendingSubmitSync extends _$PendingSubmitSync {
  Timer? _retryTimer;
  int _failures = 0;
  var _alive = true;

  @override
  Future<void> build() async {
    _alive = true;
    ref.onDispose(() {
      _alive = false;
      _retryTimer?.cancel();
      _retryTimer = null;
    });

    final signedIn = ref.watch(authSessionProvider);
    if (!signedIn) return;

    try {
      await _run();
    } catch (_) {
      // Offline or client not ready — HomeScreen will rebuild later.
    }
  }

  Future<void> _run() async {
    if (!_alive) return;

    try {
      final repo = ref.read(testsRepositoryProvider);
      final userId = repo.currentUserId;
      if (userId == null) return;

      final remaining = await PendingAttemptReconciler(
        repository: repo,
        store: ref.read(localAttemptStoreProvider),
      ).reconcile(userId: userId);

      if (!_alive) return;

      // Resume banner should drop attempts we just submitted.
      ref.invalidate(inProgressAttemptsProvider);

      if (remaining <= 0) {
        _failures = 0;
        _retryTimer?.cancel();
        _retryTimer = null;
        return;
      }

      _failures++;
      _retryTimer?.cancel();
      _retryTimer = Timer(SubmitBackoff.delayFor(_failures), () {
        unawaited(_run());
      });
    } catch (_) {
      if (!_alive) return;
      _failures++;
      _retryTimer?.cancel();
      _retryTimer = Timer(SubmitBackoff.delayFor(_failures), () {
        unawaited(_run());
      });
    }
  }
}

/// Exponential backoff for a failed submit (spec §4).
///
/// 2s, 4s, 8s, … capped at 60s so we keep retrying without hammering the API.
abstract final class SubmitBackoff {
  static const maxDelay = Duration(seconds: 60);

  static Duration delayFor(int failureCount) {
    if (failureCount <= 0) return const Duration(seconds: 2);
    final shift = failureCount - 1;
    final seconds = shift >= 30 ? 60 : (2 * (1 << shift));
    if (seconds >= maxDelay.inSeconds) return maxDelay;
    return Duration(seconds: seconds);
  }
}

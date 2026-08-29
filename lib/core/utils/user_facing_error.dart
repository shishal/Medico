/// Turns thrown errors into short copy the student can act on.
///
/// Repositories catch raw [SocketException] / HTTP failures and must not let
/// those strings reach the UI. We match on the error's text rather than
/// importing `dart:io`, so the same helper works in widget tests and on device.
abstract final class UserFacingError {
  static const offlineMessage =
      "You're offline. Check your connection and try again.";

  static const _offlineNeedles = [
    'socketexception',
    'clientexception',
    'handshakeexception',
    'timeoutexception',
    'authretryablefetch',
    'failed host lookup',
    'network is unreachable',
    'connection refused',
    'connection reset',
    'connection timed out',
    'timed out',
    'failed to fetch',
    'network request failed',
    'xmlhttprequest',
    'os error',
    'no address associated',
    'networkerror',
    'errno =',
  ];

  /// True when [error] looks like a dropped connection, not an app bug.
  static bool looksOffline(Object error) {
    final haystack = '${error.runtimeType} $error'.toLowerCase();
    if (haystack.contains(offlineMessage.toLowerCase())) return true;
    return _offlineNeedles.any(haystack.contains);
  }

  /// Repository catch-all: offline copy when the network is down, else
  /// [fallback] (the screen-specific "could not load X" sentence).
  static String from(Object error, {required String fallback}) {
    if (looksOffline(error)) return offlineMessage;
    return fallback;
  }

  /// [AsyncValue.error] / `throw Exception(message)` → student-facing text.
  static String display(Object error) {
    if (looksOffline(error)) return offlineMessage;

    var message = error.toString();
    const prefix = 'Exception: ';
    if (message.startsWith(prefix)) {
      message = message.substring(prefix.length);
    }

    if (looksOffline(message)) return offlineMessage;
    if (message.trim().isEmpty) {
      return 'Something went wrong. Please try again.';
    }
    return message;
  }
}

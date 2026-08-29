/// Device clock corrected toward Postgres when they disagree.
///
/// Spec §3: remaining time is `duration - (now - started_at)` using wall-clock
/// elapsed time, never a saved "seconds left" value. Changing the device clock
/// while offline can fake [DateTime.now]; when connectivity returns we compare
/// against `server_now()` and, if the skew is more than [skewTolerance], trust
/// the server.
class WallClock {
  WallClock({this.offset = Duration.zero, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// "A couple of minutes" in the spec — smaller than any real test duration,
  /// large enough to ignore ordinary NTP jitter.
  static const skewTolerance = Duration(minutes: 2);

  final Duration offset;
  final DateTime Function() _now;

  DateTime now() => _now().add(offset);

  /// If |server − local| > [skewTolerance], future [now] calls follow the
  /// server. Otherwise drop any previous offset (clocks agree again).
  WallClock reconcile({
    required DateTime serverNow,
    required DateTime localNow,
  }) {
    final delta = serverNow.difference(localNow);
    if (delta.abs() > skewTolerance) {
      return WallClock(offset: delta, now: _now);
    }
    return WallClock(now: _now);
  }
}

/// Merge local and server section-start maps.
///
/// Missing-on-one-side keys are kept (offline enter, then sync). When both
/// exist and disagree by more than [WallClock.skewTolerance], trust server.
Map<int, DateTime> mergeSectionStartedAt(
  Map<int, DateTime> local,
  Map<int, DateTime> server,
) {
  final result = Map<int, DateTime>.from(local);
  for (final entry in server.entries) {
    final localAt = result[entry.key];
    if (localAt == null) {
      result[entry.key] = entry.value;
      continue;
    }
    if ((localAt.difference(entry.value)).abs() > WallClock.skewTolerance) {
      result[entry.key] = entry.value;
    }
  }
  return result;
}

/// JSON object `{"1": "2026-08-29T10:00:00.000Z"}` ↔ Dart map.
Map<int, DateTime> parseSectionStartedAt(Object? raw) {
  final result = <int, DateTime>{};
  if (raw is! Map) return result;
  for (final entry in raw.entries) {
    final key = int.tryParse(entry.key.toString());
    final value = DateTime.tryParse(entry.value.toString());
    if (key != null && value != null) {
      result[key] = value;
    }
  }
  return result;
}

Map<String, String> encodeSectionStartedAt(Map<int, DateTime> map) {
  return {
    for (final entry in map.entries)
      entry.key.toString(): entry.value.toUtc().toIso8601String(),
  };
}

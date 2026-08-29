import 'dart:async';

import 'package:no_screenshot/no_screenshot.dart';
import 'package:no_screenshot/screenshot_snapshot.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/capture_event.dart';

part 'screenshot_protection.g.dart';

/// Turns capture blocking on while any content screen is mounted, and
/// forwards native screenshot / recording events.
///
/// Android uses `FLAG_SECURE` (screenshot is blocked). iOS cannot fully
/// prevent capture; [events] is how we still react there.
abstract class ScreenshotProtection {
  Future<void> acquire();
  Future<void> release();
  Stream<CaptureEvent> get events;
}

/// Wraps `no_screenshot` with a hold count so stacked player + review
/// screens don't turn protection off when the first one pops.
class PluginScreenshotProtection implements ScreenshotProtection {
  PluginScreenshotProtection({NoScreenshot? plugin})
    : _plugin = plugin ?? NoScreenshot.instance;

  final NoScreenshot _plugin;
  final _events = StreamController<CaptureEvent>.broadcast();

  int _holds = 0;
  StreamSubscription<ScreenshotSnapshot>? _subscription;
  bool _wasRecording = false;

  @override
  Stream<CaptureEvent> get events => _events.stream;

  @override
  Future<void> acquire() async {
    _holds++;
    if (_holds != 1) return;
    await _enable();
  }

  @override
  Future<void> release() async {
    if (_holds == 0) return;
    _holds--;
    if (_holds != 0) return;
    await _disable();
  }

  Future<void> _enable() async {
    try {
      await _plugin.screenshotOff();
      await _plugin.startScreenshotListening();
      await _plugin.startScreenRecordingListening();
      _subscription = _plugin.screenshotStream.listen(
        _onSnapshot,
        onError: (_) {},
      );
    } catch (_) {
      // Widget tests and unsupported platforms have no native plugin.
    }
  }

  Future<void> _disable() async {
    try {
      await _subscription?.cancel();
      _subscription = null;
      await _plugin.stopScreenshotListening();
      await _plugin.stopScreenRecordingListening();
      await _plugin.screenshotOn();
    } catch (_) {}
    _wasRecording = false;
  }

  void _onSnapshot(ScreenshotSnapshot snapshot) {
    if (snapshot.wasScreenshotTaken) {
      _events.add(CaptureEvent.screenshot);
    }
    if (!_wasRecording && snapshot.isScreenRecording) {
      _events.add(CaptureEvent.recordingStarted);
    } else if (_wasRecording && !snapshot.isScreenRecording) {
      _events.add(CaptureEvent.recordingStopped);
    }
    _wasRecording = snapshot.isScreenRecording;
  }
}

@Riverpod(keepAlive: true)
ScreenshotProtection screenshotProtection(Ref ref) {
  return PluginScreenshotProtection();
}

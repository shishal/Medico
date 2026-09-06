import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Asks the platform to show the software keyboard.
///
/// Android can grant focus on the first tap and still drop the IME request —
/// common with password fields and with emulators that think a hardware
/// keyboard is attached. [TextField.onTap] runs after Flutter's own show
/// call, so retrying here covers that miss.
void requestSoftKeyboard() {
  SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  SchedulerBinding.instance.addPostFrameCallback((_) {
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  });
}

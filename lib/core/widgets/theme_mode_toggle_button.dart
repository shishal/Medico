import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_mode_provider.dart';

/// Debug control for Phase 3.1 — cycles system → light → dark.
class ThemeModeToggleButton extends ConsumerWidget {
  const ThemeModeToggleButton({super.key});

  String _label(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'System theme',
        ThemeMode.light => 'Light theme',
        ThemeMode.dark => 'Dark theme',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return OutlinedButton.icon(
      onPressed: () => ref.read(themeModeProvider.notifier).cycle(),
      icon: Icon(switch (themeMode) {
        ThemeMode.system => Icons.brightness_auto,
        ThemeMode.light => Icons.light_mode,
        ThemeMode.dark => Icons.dark_mode,
      }),
      label: Text(_label(themeMode)),
    );
  }
}

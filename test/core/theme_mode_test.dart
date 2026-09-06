import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medico/core/theme/app_theme.dart';
import 'package:medico/core/theme/comic_colors.dart';
import 'package:medico/core/theme/theme_mode_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dark canvas is charcoal, not teal paper', () {
    expect(ComicColors.dark.paper, const Color(0xFF121212));
    expect(AppTheme.splashCanvas, const Color(0xFF121212));
    expect(AppTheme.seedColor, const Color(0xFFF25C2D));
    expect(ComicColors.dark.sticker, const Color(0xFF252528));
    expect(ComicColors.dark.stickerLift, const Color(0xFF2E2E33));
    expect(ComicColors.dark.accentPurple, const Color(0xFF8B7CFF));
  });

  test('light canvas is clean gray, not comic paper', () {
    expect(ComicColors.light.paper, const Color(0xFFF4F4F5));
    expect(ComicColors.light.sticker, const Color(0xFFFFFFFF));
  });

  test('ThemeModeNotifier.fromName maps stored values', () {
    expect(ThemeModeNotifier.fromName('light'), ThemeMode.light);
    expect(ThemeModeNotifier.fromName('system'), ThemeMode.system);
    expect(ThemeModeNotifier.fromName('dark'), ThemeMode.dark);
    expect(ThemeModeNotifier.fromName('nope'), ThemeMode.dark);
  });

  test('theme preference persists as the enum name', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', 'light');
    expect(prefs.getString('theme_mode'), 'light');
    expect(ThemeModeNotifier.fromName(prefs.getString('theme_mode')!), ThemeMode.light);
  });
}

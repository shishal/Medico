import 'package:flutter/material.dart';

import '../../../../core/theme/app_surfaces.dart';
import '../../domain/test_type.dart';

/// Pastel tint + icon for a catalog test type. Not a score.
abstract final class TestTypeStyle {
  static Color tint(TestType type, Brightness brightness) {
    return CategoryTints.at(type.index, brightness);
  }

  static IconData icon(TestType type) => switch (type) {
    TestType.mini => Icons.bolt_outlined,
    TestType.subject => Icons.menu_book_outlined,
    TestType.mock => Icons.assignment_outlined,
    TestType.grand => Icons.emoji_events_outlined,
  };
}

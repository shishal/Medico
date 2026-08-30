import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../progress/domain/progress_models.dart';
import '../../../progress/presentation/providers/ug_home_providers.dart';

/// Last 7 days of study events from the server (`StudyProgress.days7`).
///
/// Counts are displayed as-is. Missing days show 0 — we do not invent activity.
class HomeWeekStrip extends ConsumerWidget {
  const HomeWeekStrip({super.key});

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days7 = ref.watch(studyProgressProvider).value?.days7 ?? const [];
    final cells = _cellsFor(days7);
    final today = DateTime.now();
    final todayKey = _ymd(DateTime(today.year, today.month, today.day));
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.lg, Spacing.lg, 0),
      child: Row(
        children: [
          for (final cell in cells)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                  decoration: BoxDecoration(
                    color: cell.key == todayKey
                        ? scheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _labels[cell.weekdayIndex],
                        style: textTheme.labelSmall?.copyWith(
                          color: cell.key == todayKey
                              ? Colors.white70
                              : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        '${cell.day}',
                        style: textTheme.titleSmall?.copyWith(
                          color: cell.key == todayKey ? Colors.white : null,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cell.count == 0 ? '·' : '${cell.count}',
                        style: textTheme.labelSmall?.copyWith(
                          color: cell.key == todayKey
                              ? Colors.white70
                              : scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Prefer the 7 server rows when they parse; otherwise last 7 local days.
  static List<_DayCell> _cellsFor(List<DayCount> days7) {
    final parsed = <_DayCell>[];
    for (final d in days7) {
      final dt = DateTime.tryParse(d.date);
      if (dt == null) continue;
      parsed.add(_DayCell(date: dt, count: d.count));
    }
    if (parsed.length == 7) return parsed;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final byDate = <String, int>{
      for (final cell in parsed) cell.key: cell.count,
    };
    return [
      for (var i = 6; i >= 0; i--)
        _DayCell(
          date: today.subtract(Duration(days: i)),
          count: byDate[_ymd(today.subtract(Duration(days: i)))] ?? 0,
        ),
    ];
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class _DayCell {
  _DayCell({required DateTime date, required this.count})
    : date = DateTime(date.year, date.month, date.day),
      day = date.day,
      weekdayIndex = date.weekday - 1,
      key = HomeWeekStrip._ymd(date);

  final DateTime date;
  final int day;
  final int weekdayIndex;
  final int count;
  final String key;
}

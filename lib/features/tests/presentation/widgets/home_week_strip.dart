import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';

/// Visual “today” strip — not a calendar you pick, and not study activity.
class HomeWeekStrip extends StatelessWidget {
  const HomeWeekStrip({super.key});

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // DateTime.weekday is 1 = Monday … 7 = Sunday.
    final todayIndex = now.weekday - 1;
    final monday = now.subtract(Duration(days: todayIndex));
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.lg, Spacing.lg, 0),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                  decoration: BoxDecoration(
                    color: i == todayIndex
                        ? scheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _labels[i],
                        style: textTheme.labelSmall?.copyWith(
                          color: i == todayIndex
                              ? Colors.white70
                              : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        monday.add(Duration(days: i)).day.toString(),
                        style: textTheme.titleSmall?.copyWith(
                          color: i == todayIndex ? Colors.white : null,
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
}

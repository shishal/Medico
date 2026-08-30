import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../profile/presentation/providers/current_plan_provider.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';

class HomeGreetingHeader extends ConsumerWidget {
  const HomeGreetingHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final plan = ref.watch(currentPlanProvider).value;
    final name = profile?.fullName?.trim();
    final hello = (name == null || name.isEmpty)
        ? 'Hi there'
        : 'Hi, ${_firstName(name)}';
    final initial = (name == null || name.isEmpty)
        ? 'M'
        : name[0].toUpperCase();

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, 0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: scheme.primary.withValues(alpha: 0.16),
            foregroundColor: scheme.primary,
            child: Text(
              initial,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hello,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Ready for NEET-PG today?',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (plan != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm,
                vertical: Spacing.xs,
              ),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                plan.label,
                style: textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _firstName(String full) {
    final space = full.indexOf(' ');
    return space <= 0 ? full : full.substring(0, space);
  }
}

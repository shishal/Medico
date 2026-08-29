import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../profile/domain/plan_tier.dart';
import '../../domain/test_detail.dart';
import '../../domain/test_type.dart';
import '../providers/catalog_tests_provider.dart';
import '../providers/test_detail_provider.dart';

/// Pre-start screen: duration, marking, and sectional lock rules before the player.
class TestInstructionsScreen extends ConsumerWidget {
  const TestInstructionsScreen({super.key, required this.testId});

  final String testId;

  static const _planLockedMessage =
      'This test is not available on your current plan.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(testDetailProvider(testId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Before you start'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.testList);
            }
          },
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          final message =
              error.toString().replaceFirst('Exception: ', '');
          final planLocked = message == _planLockedMessage;
          // Teaser list still has required_plan even when full row is RLS-empty.
          final teasers = ref.watch(catalogTestsProvider).value;
          final requiredPlan = teasers
                  ?.where((t) => t.id == testId)
                  .map((t) => t.requiredPlan)
                  .firstOrNull ??
              PlanTier.pro;
          return _ErrorBody(
            message: message,
            planLocked: planLocked,
            onRetry: planLocked
                ? null
                : () => ref.invalidate(testDetailProvider(testId)),
            onUpgrade: planLocked
                ? () => context.go(AppRoutes.upgradePath(requiredPlan))
                : null,
          );
        },
        data: (detail) => _InstructionsBody(
          detail: detail,
          onStart: () => context.go(AppRoutes.testPlayerPath(detail.id)),
        ),
      ),
    );
  }
}

class _InstructionsBody extends StatelessWidget {
  const _InstructionsBody({
    required this.detail,
    required this.onStart,
  });

  final TestDetail detail;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(Spacing.lg),
            children: [
              _TypeBadge(type: detail.testType),
              const SizedBox(height: Spacing.sm),
              Text(detail.title, style: textTheme.headlineSmall),
              if (detail.description != null &&
                  detail.description!.trim().isNotEmpty) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  detail.description!,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: Spacing.lg),
              _FactRow(
                icon: Icons.timer_outlined,
                label: 'Duration',
                value: detail.durationLabel,
              ),
              _FactRow(
                icon: Icons.quiz_outlined,
                label: 'Questions',
                value: '${detail.totalQuestions}',
              ),
              _FactRow(
                icon: Icons.scoreboard_outlined,
                label: 'Marking',
                value: detail.markingSchemeLabel,
              ),
              if (detail.sectionLayoutLabel != null)
                _FactRow(
                  icon: Icons.view_agenda_outlined,
                  label: 'Sections',
                  value: detail.sectionLayoutLabel!,
                ),
              const SizedBox(height: Spacing.lg),
              if (detail.isSectional)
                const _SectionLockWarning()
              else
                _InfoCallout(
                  icon: Icons.info_outline,
                  background: colorScheme.secondaryContainer,
                  foreground: colorScheme.onSecondaryContainer,
                  title: 'One continuous timer',
                  body:
                      'The clock starts when you tap Start. When time runs out, '
                      'your answers are submitted automatically — you cannot pause.',
                ),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.sm,
            Spacing.lg,
            Spacing.lg,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onStart,
              child: const Text('Start test'),
            ),
          ),
        ),
      ],
    );
  }
}

/// High-visibility callout — section exit is permanent (see engine spec §3).
class _SectionLockWarning extends StatelessWidget {
  const _SectionLockWarning();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _InfoCallout(
      icon: Icons.lock_clock,
      background: colorScheme.errorContainer,
      foreground: colorScheme.onErrorContainer,
      title: 'You cannot go back to a finished section',
      body:
          'Each section has its own timer. When a section’s time runs out — or '
          'you submit that section early — those questions are permanently '
          'locked. The question palette will not let you reopen them. Plan your '
          'time before you leave a section.',
    );
  }
}

class _InfoCallout extends StatelessWidget {
  const _InfoCallout({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Spacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    body,
                    style: textTheme.bodyMedium?.copyWith(color: foreground),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: colorScheme.primary),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(value, style: textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final TestType type;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xs,
        ),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(Spacing.xs),
        ),
        child: Text(
          type.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.planLocked,
    this.onRetry,
    this.onUpgrade,
  });

  final String message;
  final bool planLocked;
  final VoidCallback? onRetry;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (planLocked) ...[
              Icon(
                Icons.lock_outline,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: Spacing.md),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: Spacing.md),
            if (onUpgrade != null)
              FilledButton(
                onPressed: onUpgrade,
                child: const Text('View upgrade options'),
              )
            else if (onRetry != null)
              FilledButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            const SizedBox(height: Spacing.sm),
            TextButton(
              onPressed: () => context.go(AppRoutes.testList),
              child: const Text('Back to tests'),
            ),
          ],
        ),
      ),
    );
  }
}

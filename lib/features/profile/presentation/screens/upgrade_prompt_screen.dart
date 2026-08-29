import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/plan_tier.dart';

/// Placeholder paywall until Phase 7.1 (external Razorpay checkout).
///
/// Locked catalog cards navigate here instead of the test player.
class UpgradePromptScreen extends StatelessWidget {
  const UpgradePromptScreen({super.key, this.requiredPlan = PlanTier.pro});

  /// Plan needed to unlock the content the user tapped.
  final PlanTier requiredPlan;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final planLabel = requiredPlan.label;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.lock_outline,
              size: 56,
              color: colorScheme.primary,
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'Upgrade to $planLabel',
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'This is available on the $planLabel plan. '
              'Checkout will open in your browser in a later update — '
              'for now this screen confirms the lock works.',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/async_status_views.dart';
import '../../data/checkout_launcher.dart';
import '../../domain/plan_offering.dart';
import '../../domain/plan_tier.dart';
import '../providers/current_plan_provider.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/plan_comparison_card.dart';

/// Plan comparison + a link out to web checkout (Phase 7.1).
///
/// Payment never happens in this app — the CTA opens the device browser.
class UpgradePromptScreen extends ConsumerStatefulWidget {
  const UpgradePromptScreen({super.key, this.requiredPlan = PlanTier.pro});

  /// Plan needed to unlock the content the user tapped, if they came from a lock.
  final PlanTier requiredPlan;

  @override
  ConsumerState<UpgradePromptScreen> createState() =>
      _UpgradePromptScreenState();
}

class _UpgradePromptScreenState extends ConsumerState<UpgradePromptScreen> {
  PlanTier? _openingPlan;

  Future<void> _openCheckout(PlanTier plan) async {
    setState(() => _openingPlan = plan);

    final result = await ref
        .read(checkoutLauncherProvider)
        .openCheckout(plan: plan);

    if (!mounted) return;
    setState(() => _openingPlan = null);

    switch (result) {
      case Success():
        break;
      case Failure(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final planAsync = ref.watch(currentPlanProvider);
    final currentPlan = planAsync.value;
    final required = widget.requiredPlan == PlanTier.free
        ? null
        : widget.requiredPlan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plans'),
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
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          Text(
            required == null
                ? 'Compare plans'
                : 'Upgrade to ${required.label} to unlock this',
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'You will finish payment on our website in your browser. '
            'This app never takes a card or shows a buy button.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          if (planAsync.hasError) ...[
            InlineErrorMessage(
              message: UserFacingError.display(planAsync.error!),
              onRetry: () => ref.read(userProfileProvider.notifier).refresh(),
            ),
            const SizedBox(height: Spacing.md),
          ],
          for (final offering in PlanOffering.comparison) ...[
            PlanComparisonCard(
              offering: offering,
              isCurrent: currentPlan == offering.tier,
              isRequired: required == offering.tier,
              isOpening: _openingPlan == offering.tier,
              onContinueInBrowser:
                  offering.tier == PlanTier.free || currentPlan == offering.tier
                  ? null
                  : () => _openCheckout(offering.tier),
            ),
            const SizedBox(height: Spacing.md),
          ],
        ],
      ),
    );
  }
}

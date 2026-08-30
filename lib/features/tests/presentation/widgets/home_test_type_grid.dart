import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/async_status_views.dart';
import '../../../profile/domain/plan_tier.dart';
import '../../../profile/presentation/providers/current_plan_provider.dart';
import '../../domain/catalog_test.dart';
import '../../domain/test_type.dart';
import '../providers/catalog_tests_provider.dart';
import 'test_type_style.dart';

class HomeTestTypeGrid extends ConsumerWidget {
  const HomeTestTypeGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testsAsync = ref.watch(catalogTestsProvider);
    final plan = ref.watch(currentPlanProvider).value ?? PlanTier.free;
    final brightness = Theme.of(context).brightness;

    return testsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(Spacing.lg),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        child: InlineErrorMessage(
          message: UserFacingError.display(e),
          onRetry: () => ref.read(catalogTestsProvider.notifier).refresh(),
        ),
      ),
      data: (tests) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: Spacing.md,
            crossAxisSpacing: Spacing.md,
            childAspectRatio: 1.15,
            children: [
              for (final type in TestType.values)
                _TypeCard(
                  type: type,
                  tests: tests.where((t) => t.testType == type).toList(),
                  plan: plan,
                  tint: TestTypeStyle.tint(type, brightness),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.tests,
    required this.plan,
    required this.tint,
  });

  final TestType type;
  final List<CatalogTest> tests;
  final PlanTier plan;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final unlocked = tests.where((t) => !t.isLockedFor(plan)).length;
    final total = tests.length;
    final label = total == 0
        ? 'None yet'
        : (unlocked == total ? '$total tests' : '$unlocked of $total');

    return AppCard(
      color: tint,
      semanticLabel: type.label,
      onTap: () => context.go(AppRoutes.testList),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(TestTypeStyle.icon(type), size: 28),
          const Spacer(),
          Text(
            type.label,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Spacing.xs),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

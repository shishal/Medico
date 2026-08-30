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
import '../widgets/test_type_style.dart';

/// Tabbed catalog: unlocked tests + locked teasers for higher plans.
class TestListScreen extends ConsumerWidget {
  const TestListScreen({super.key});

  static const _tabs = <_TestTab>[
    _TestTab(label: 'All', type: null),
    _TestTab(label: 'Mini', type: TestType.mini),
    _TestTab(label: 'Subject', type: TestType.subject),
    _TestTab(label: 'Mock', type: TestType.mock),
    _TestTab(label: 'Grand', type: TestType.grand),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testsAsync = ref.watch(catalogTestsProvider);
    // Display-only plan for lock icons — RLS still gates real content.
    // Prefer loaded plan; while loading/error, treat as free (more locks, safer UX).
    final userPlan = ref.watch(currentPlanProvider).value ?? PlanTier.free;

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tests'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () =>
                  ref.read(catalogTestsProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [for (final tab in _tabs) Tab(text: tab.label)],
          ),
        ),
        body: testsAsync.when(
          loading: () => const AsyncLoadingView(),
          error: (error, _) => AsyncErrorView(
            message: UserFacingError.display(error),
            onAction: () => ref.read(catalogTestsProvider.notifier).refresh(),
          ),
          data: (tests) => TabBarView(
            children: [
              for (final tab in _tabs)
                _TestTypeList(
                  userPlan: userPlan,
                  emptyMessage: tab.type == null
                      ? 'No tests available yet.'
                      : 'No tests of this type yet.',
                  tests: tab.type == null
                      ? tests
                      : tests.where((t) => t.testType == tab.type).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestTab {
  const _TestTab({required this.label, required this.type});

  final String label;
  final TestType? type;
}

class _TestTypeList extends StatelessWidget {
  const _TestTypeList({
    required this.tests,
    required this.userPlan,
    required this.emptyMessage,
  });

  final List<CatalogTest> tests;
  final PlanTier userPlan;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (tests.isEmpty) {
      return AsyncEmptyView(icon: Icons.quiz_outlined, message: emptyMessage);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(Spacing.md),
      itemCount: tests.length,
      separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
      itemBuilder: (context, index) =>
          _TestCard(test: tests[index], userPlan: userPlan),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({required this.test, required this.userPlan});

  final CatalogTest test;
  final PlanTier userPlan;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final locked = test.isLockedFor(userPlan);
    final brightness = Theme.of(context).brightness;

    return AppCard(
      color: TestTypeStyle.tint(
        test.testType,
        brightness,
      ).withValues(alpha: locked ? 0.45 : 0.55),
      onTap: () {
        if (locked) {
          context.go(AppRoutes.upgradePath(test.requiredPlan));
        } else {
          // Instructions first — never jump straight into a timed test.
          context.go(AppRoutes.testDetailPath(test.id));
        }
      },
      child: Opacity(
        opacity: locked ? 0.85 : 1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TypeBadge(type: test.testType),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    locked ? '${test.title} 🔒' : test.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  if (locked) ...[
                    Text(
                      'Upgrade to ${test.requiredPlan.label}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                  ],
                  Text(
                    '${test.totalQuestions} questions · '
                    '${test.durationLabel}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              locked ? Icons.lock_outline : Icons.chevron_right,
              color: locked
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final TestType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        type.label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

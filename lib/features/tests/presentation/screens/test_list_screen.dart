import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../profile/domain/plan_tier.dart';
import '../../../profile/presentation/providers/current_plan_provider.dart';
import '../../domain/catalog_test.dart';
import '../../domain/test_type.dart';
import '../providers/catalog_tests_provider.dart';

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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(AppRoutes.home),
          ),
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorBody(
            message: error.toString().replaceFirst('Exception: ', ''),
            onRetry: () => ref.read(catalogTestsProvider.notifier).refresh(),
          ),
          data: (tests) => TabBarView(
            children: [
              for (final tab in _tabs)
                _TestTypeList(
                  userPlan: userPlan,
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
  const _TestTypeList({required this.tests, required this.userPlan});

  final List<CatalogTest> tests;
  final PlanTier userPlan;

  @override
  Widget build(BuildContext context) {
    if (tests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Text(
            'No tests of this type yet.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(Spacing.md),
      itemCount: tests.length,
      separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
      itemBuilder: (context, index) => _TestCard(
        test: tests[index],
        userPlan: userPlan,
      ),
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

    return Card(
      // Locked cards stay tappable so users reach the upgrade prompt.
      child: InkWell(
        borderRadius: BorderRadius.circular(Spacing.sm),
        onTap: () {
          if (locked) {
            context.go(AppRoutes.upgradePath(test.requiredPlan));
          } else {
            // Instructions first — never jump straight into a timed test.
            context.go(AppRoutes.testDetailPath(test.id));
          }
        },
        child: Opacity(
          opacity: locked ? 0.72 : 1,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
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
                        locked
                            ? '${test.title} 🔒'
                            : test.title,
                        style: textTheme.titleMedium,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
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
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: Spacing.md),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

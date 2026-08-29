import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/catalog_test.dart';
import '../../domain/test_type.dart';
import '../providers/catalog_tests_provider.dart';

/// Tabbed catalog of tests the user's plan can access (RLS filters the rest).
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
  const _TestTypeList({required this.tests});

  final List<CatalogTest> tests;

  @override
  Widget build(BuildContext context) {
    if (tests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Text(
            'No tests available on your plan for this type yet.',
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
      itemBuilder: (context, index) => _TestCard(test: tests[index]),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({required this.test});

  final CatalogTest test;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(Spacing.sm),
        onTap: () => context.go(AppRoutes.testPlayerPath(test.id)),
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
                    Text(test.title, style: textTheme.titleMedium),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      '${test.totalQuestions} questions · ${test.durationLabel}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
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

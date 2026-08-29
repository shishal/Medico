import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';

/// Placeholder question player — real engine arrives in Phase 5.
class TestPlayerScreen extends StatelessWidget {
  const TestPlayerScreen({super.key, required this.testId});

  final String testId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Test: $testId'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.testDetailPath(testId)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Question player (placeholder)',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: Spacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Text(
                  'Sample question text for test "$testId".',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
            const Spacer(),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.urgentAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => context.go(AppRoutes.resultsPath('attempt-1')),
              child: const Text('Submit test (stub)'),
            ),
          ],
        ),
      ),
    );
  }
}

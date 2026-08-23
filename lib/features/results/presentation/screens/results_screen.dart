import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';

/// Placeholder results screen — real scoring arrives in Phase 6.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.attemptId});

  final String attemptId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Results (placeholder)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: Spacing.md),
            Text('Attempt: $attemptId'),
            const SizedBox(height: Spacing.lg),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Back to home'),
            ),
          ],
        ),
      ),
    );
  }
}

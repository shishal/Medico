import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';

/// Placeholder test catalog — real data arrives in Phase 4.
class TestListScreen extends StatelessWidget {
  const TestListScreen({super.key});

  static const _placeholderTests = [
    ('mini-1', 'Mini Test 1', 'Mini'),
    ('subject-1', 'Anatomy Subject Test', 'Subject'),
    ('mock-1', 'Full Mock Test', 'Mock'),
    ('grand-1', 'NEET-PG Grand Test', 'Grand'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(Spacing.md),
        itemCount: _placeholderTests.length,
        separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
        itemBuilder: (context, index) {
          final (id, title, type) = _placeholderTests[index];
          return Card(
            child: ListTile(
              title: Text(title),
              subtitle: Text(type),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AppRoutes.testPlayerPath(id)),
            ),
          );
        },
      ),
    );
  }
}

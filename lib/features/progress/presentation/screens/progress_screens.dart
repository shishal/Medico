import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/async_status_views.dart';
import '../providers/ug_home_providers.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(studyProgressProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: progress.when(
        loading: () => const AsyncLoadingView(),
        error: (e, _) => AsyncErrorView(
          message: UserFacingError.display(e),
          onAction: () => ref.invalidate(studyProgressProvider),
        ),
        data: (p) {
          return ListView(
            padding: const EdgeInsets.all(Spacing.lg),
            children: [
              Text(
                '${p.streak}-day streak',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                '${p.days30.fold<int>(0, (sum, d) => sum + d.count)} events in the last 30 days',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: Spacing.md),
              Text('Last 7 days', style: Theme.of(context).textTheme.titleSmall),
              Wrap(
                spacing: Spacing.sm,
                children: [
                  for (final d in p.days7)
                    Chip(
                      label: Text(
                        '${d.date.length >= 10 ? d.date.substring(5) : d.date} · ${d.count}',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Spacing.lg),
              Text('Subjects', style: Theme.of(context).textTheme.titleSmall),
              for (final s in p.subjects)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.name),
                  subtitle: LinearProgressIndicator(
                    value: s.totalLessons == 0
                        ? 0
                        : s.learntLessons / s.totalLessons,
                  ),
                  trailing: Text('${s.learntLessons}/${s.totalLessons}'),
                ),
            ],
          );
        },
      ),
    );
  }
}

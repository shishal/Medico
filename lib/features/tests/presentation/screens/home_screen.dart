import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/async_status_views.dart';
import '../../../../core/widgets/theme_mode_toggle_button.dart';
import '../../../auth/presentation/providers/auth_session_provider.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../profile/presentation/providers/current_plan_provider.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../../progress/presentation/providers/ug_home_providers.dart';
import '../providers/in_progress_attempts_provider.dart';
import '../providers/pending_submit_sync_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(currentPlanProvider);
    final subjects = ref.watch(phaseSubjectsProvider);
    final progress = ref.watch(studyProgressProvider);
    final trackers = ref.watch(trackerListProvider);
    ref.watch(pendingSubmitSyncProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medico'),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () => context.push(AppRoutes.search),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.go(AppRoutes.profile),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          planAsync.when(
            data: (plan) => Text(
              plan == null ? 'Plan: —' : 'Your plan: ${plan.label}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            loading: () => const SizedBox.shrink(),
            error: (error, _) => InlineErrorMessage(
              message: UserFacingError.display(error),
              onRetry: () => ref.read(userProfileProvider.notifier).refresh(),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          progress.when(
            data: (p) => Text(
              'Streak ${p.streak} day${p.streak == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: Spacing.md),
          const _ResumeBanner(),
          const SizedBox(height: Spacing.md),
          Text('This year', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: Spacing.sm),
          subjects.when(
            data: (items) {
              if (items.isEmpty) {
                return const Text('No subjects for your year yet.');
              }
              return Column(
                children: [
                  for (final s in items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.name),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.subjectPath(s.id, s.name)),
                    ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => InlineErrorMessage(
              message: UserFacingError.display(e),
              onRetry: () => ref.invalidate(phaseSubjectsProvider),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text('Trackers', style: Theme.of(context).textTheme.titleSmall),
          trackers.when(
            data: (items) {
              if (items.isEmpty) {
                return TextButton(
                  onPressed: () => context.push(AppRoutes.trackers),
                  child: const Text('Create a custom tracker'),
                );
              }
              return Column(
                children: [
                  for (final t in items.take(3))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.title),
                      trailing: Text('${t.percent}%'),
                      onTap: () => context.push(AppRoutes.trackers),
                    ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.trackers),
                    child: const Text('All trackers'),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: Spacing.md),
          FilledButton.tonal(
            onPressed: () => context.push(AppRoutes.practice),
            child: const Text('MCQ practice'),
          ),
          const SizedBox(height: Spacing.sm),
          FilledButton.tonal(
            onPressed: () => context.push(AppRoutes.progress),
            child: const Text('7-day / 30-day progress'),
          ),
          const SizedBox(height: Spacing.sm),
          FilledButton.tonal(
            onPressed: () => context.go(AppRoutes.bookmarks),
            child: const Text('Bookmarks'),
          ),
          const SizedBox(height: Spacing.lg),
          const ThemeModeToggleButton(),
          TextButton(
            onPressed: () {
              ref.read(authSessionProvider.notifier).signOut();
              context.go(AppRoutes.login);
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _ResumeBanner extends ConsumerWidget {
  const _ResumeBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inProgressAttemptsProvider);
    if (async.hasError) {
      return Card(
        child: AsyncErrorView(
          compact: true,
          message: UserFacingError.display(async.error!),
          onAction: () => ref.invalidate(inProgressAttemptsProvider),
        ),
      );
    }

    final items = async.value;
    if (items == null || items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: Text(item.title),
                subtitle: const Text('In-progress MCQ session — tap to resume'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.testPlayerPath(item.testId)),
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/theme_mode_toggle_button.dart';
import '../../../auth/presentation/providers/auth_session_provider.dart';
import '../../../profile/presentation/providers/current_plan_provider.dart';
import '../providers/in_progress_attempts_provider.dart';

/// Landing screen after authentication (placeholder until Phase 4).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(currentPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
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
          Text('Home', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: Spacing.sm),
          planAsync.when(
            data: (plan) => Text(
              plan == null ? 'Plan: —' : 'Your plan: ${plan.label}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            loading: () => const Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, _) => Text(
              'Plan unavailable',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Placeholder shell — content screens arrive in later phases.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          const _ResumeBanner(),
          const SizedBox(height: Spacing.md),
          FilledButton(
            onPressed: () => context.go(AppRoutes.practice),
            child: const Text('Practice'),
          ),
          const SizedBox(height: Spacing.md),
          FilledButton.tonal(
            onPressed: () => context.go(AppRoutes.testList),
            child: const Text('Browse tests'),
          ),
          const SizedBox(height: Spacing.md),
          OutlinedButton(
            onPressed: () => context.go(AppRoutes.profile),
            child: const Text('Profile'),
          ),
          const SizedBox(height: Spacing.lg),
          const ThemeModeToggleButton(),
          const SizedBox(height: Spacing.md),
          TextButton(
            onPressed: () {
              ref.read(authSessionProvider.notifier).signOut();
              context.go(AppRoutes.login);
            },
            child: const Text('Sign out (stub)'),
          ),
        ],
      ),
    );
  }
}

/// Offers resume when a local/server in-progress attempt exists (spec §4).
class _ResumeBanner extends ConsumerWidget {
  const _ResumeBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inProgressAttemptsProvider);
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
                subtitle: const Text('In progress — tap to resume'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.testPlayerPath(item.testId)),
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/theme_mode_toggle_button.dart';
import '../../../auth/presentation/providers/auth_session_provider.dart';

/// Landing screen after authentication (placeholder until Phase 4).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          Text(
            'Home',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Placeholder shell — content screens arrive in later phases.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: Spacing.lg),
          FilledButton(
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

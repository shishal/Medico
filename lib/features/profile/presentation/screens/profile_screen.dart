import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/async_status_views.dart';
import '../../../../core/widgets/theme_mode_toggle_button.dart';
import '../../../auth/data/auth_repository.dart';
import '../providers/current_plan_provider.dart';
import '../providers/user_profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);

    final result = await ref.read(authRepositoryProvider).signOut();

    if (!mounted) return;

    setState(() => _isSigningOut = false);

    switch (result) {
      case Success():
        context.go(AppRoutes.login);
      case Failure(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(currentPlanProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh plan',
            onPressed: () => ref.read(userProfileProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          Text('Profile', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: Spacing.md),
          planAsync.when(
            data: (plan) => Text(
              plan == null ? 'Plan: —' : 'Current plan: ${plan.label}',
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
            error: (error, _) => InlineErrorMessage(
              message: UserFacingError.display(error),
              onRetry: () => ref.read(userProfileProvider.notifier).refresh(),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          profileAsync.when(
            data: (profile) {
              if (profile == null) return const SizedBox.shrink();
              final expires = profile.planExpiresAt;
              return Text(
                expires == null
                    ? 'No plan expiry set'
                    : 'Stored plan: ${profile.plan.label} · expires ${expires.toLocal()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: Spacing.lg),
          FilledButton.tonal(
            onPressed: () => context.go(AppRoutes.upgrade),
            child: const Text('Compare plans'),
          ),
          const SizedBox(height: Spacing.md),
          const ThemeModeToggleButton(),
          const SizedBox(height: Spacing.md),
          TextButton(
            onPressed: _isSigningOut ? null : _signOut,
            child: _isSigningOut
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

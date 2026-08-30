import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/app_card.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final name = profileAsync.value?.fullName?.trim();
    final initial = (name == null || name.isEmpty)
        ? 'M'
        : name[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
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
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: scheme.primary.withValues(alpha: 0.16),
              child: Text(
                initial,
                style: textTheme.headlineSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            (name == null || name.isEmpty) ? 'Medico student' : name,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Spacing.sm),
          planAsync.when(
            data: (plan) => Text(
              plan == null ? 'Plan: —' : 'Current plan: ${plan.label}',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
            loading: () => const Center(
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
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: Spacing.lg),
          AppCard(
            onTap: () => context.go(AppRoutes.upgrade),
            child: Row(
              children: [
                Icon(Icons.workspace_premium_outlined, color: scheme.primary),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    'Compare plans',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),
          const AppCard(child: ThemeModeToggleButton()),
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

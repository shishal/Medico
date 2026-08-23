import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/theme_mode_toggle_button.dart';
import '../../../auth/presentation/providers/auth_session_provider.dart';

/// Placeholder profile screen — real profile data arrives later.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          Text(
            'Profile (placeholder)',
            style: Theme.of(context).textTheme.headlineSmall,
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

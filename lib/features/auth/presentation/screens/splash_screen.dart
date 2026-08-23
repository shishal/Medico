import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../providers/auth_session_provider.dart';

/// Brief branded splash; navigates to login or home based on auth session.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigateAway());
  }

  Future<void> _navigateAway() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final isAuthenticated = ref.read(authSessionProvider);
    context.go(isAuthenticated ? AppRoutes.home : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_hospital_outlined,
              size: 72,
              color: colorScheme.primary,
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'Medico',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'NEET-PG Prep',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: Spacing.xl),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../providers/auth_session_provider.dart';

/// Placeholder login — real Supabase auth arrives in Phase 3.2.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome back',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: Spacing.md),
            const TextField(
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: Spacing.md),
            const TextField(
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: Spacing.lg),
            FilledButton(
              onPressed: () {
                ref.read(authSessionProvider.notifier).signIn();
                context.go(AppRoutes.home);
              },
              child: const Text('Sign in (stub)'),
            ),
            const SizedBox(height: Spacing.md),
            TextButton(
              onPressed: () => context.go(AppRoutes.signup),
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}

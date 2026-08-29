import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:medico/core/router/app_routes.dart';
import 'package:medico/core/theme/app_theme.dart';
import 'package:medico/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:medico/features/auth/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('Splash shows brand mark on teal', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.splash,
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (_, _) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, _) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authSessionProvider.overrideWithValue(false)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    expect(find.text('Medico'), findsOneWidget);
    expect(find.text('NEET-PG Prep'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppTheme.seedColor);

    await tester.pump(const Duration(milliseconds: 900));
  });
}

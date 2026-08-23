import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/providers/auth_session_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/results/presentation/screens/results_screen.dart';
import '../../features/tests/presentation/screens/home_screen.dart';
import '../../features/tests/presentation/screens/test_list_screen.dart';
import '../../features/tests/presentation/screens/test_player_screen.dart';
import 'app_routes.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  final isAuthenticated = ref.watch(authSessionProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final onSplash = location == AppRoutes.splash;
      final onAuth =
          location == AppRoutes.login || location == AppRoutes.signup;

      // Splash handles its own navigation after a brief display.
      if (onSplash) return null;

      if (!isAuthenticated && !onAuth) {
        return AppRoutes.login;
      }
      if (isAuthenticated && onAuth) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.testList,
        builder: (context, state) => const TestListScreen(),
      ),
      GoRoute(
        path: AppRoutes.testPlayer,
        builder: (context, state) {
          final testId = state.pathParameters['testId']!;
          return TestPlayerScreen(testId: testId);
        },
      ),
      GoRoute(
        path: AppRoutes.results,
        builder: (context, state) {
          final attemptId = state.pathParameters['attemptId']!;
          return ResultsScreen(attemptId: attemptId);
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}

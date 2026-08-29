import '../../features/profile/domain/plan_tier.dart';

/// Central route path constants — use these instead of string literals.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const practice = '/practice';
  static const testList = '/tests';
  static const testDetail = '/tests/:testId';
  static const testPlayer = '/tests/:testId/play';
  static const results = '/results/:attemptId';
  static const profile = '/profile';
  static const upgrade = '/upgrade';

  static String testDetailPath(String testId) => '/tests/$testId';
  static String testPlayerPath(String testId) => '/tests/$testId/play';

  static String resultsPath(
    String attemptId, {
    String? testId,
    bool isPractice = false,
  }) {
    final params = <String, String>{
      'testId': ?testId,
      if (isPractice) 'practice': '1',
    };
    if (params.isEmpty) return '/results/$attemptId';
    return Uri(path: '/results/$attemptId', queryParameters: params).toString();
  }

  /// Opens the upgrade prompt for the plan needed to unlock tapped content.
  static String upgradePath(PlanTier requiredPlan) =>
      '$upgrade?plan=${requiredPlan.name}';
}

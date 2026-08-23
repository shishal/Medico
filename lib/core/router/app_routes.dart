/// Central route path constants — use these instead of string literals.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const testList = '/tests';
  static const testPlayer = '/tests/:testId/play';
  static const results = '/results/:attemptId';
  static const profile = '/profile';

  static String testPlayerPath(String testId) => '/tests/$testId/play';
  static String resultsPath(String attemptId) => '/results/$attemptId';
}

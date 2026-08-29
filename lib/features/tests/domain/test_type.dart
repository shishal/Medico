/// Matches the Postgres `test_type` enum (mini / subject / mock / grand).
enum TestType {
  mini,
  subject,
  mock,
  grand;

  static TestType fromString(String value) {
    return switch (value.toLowerCase()) {
      'subject' => TestType.subject,
      'mock' => TestType.mock,
      'grand' => TestType.grand,
      _ => TestType.mini,
    };
  }

  /// Postgres enum value — use when filtering queries.
  String get dbValue => name;

  /// Short label for tabs and type badges.
  String get label => switch (this) {
        TestType.mini => 'Mini',
        TestType.subject => 'Subject',
        TestType.mock => 'Mock',
        TestType.grand => 'Grand',
      };
}

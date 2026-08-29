import '../../../core/supabase/tables.dart';
import '../../../core/utils/wall_clock.dart';
import 'attempt_status.dart';

/// Row from `attempts`, with optional title from an embedded `tests` row.
class Attempt {
  const Attempt({
    required this.id,
    required this.userId,
    required this.testId,
    required this.status,
    required this.startedAt,
    this.sectionStartedAt = const {},
    this.title = 'Test',
    this.isEphemeralPractice = false,
  });

  final String id;
  final String userId;
  final String testId;
  final AttemptStatus status;
  final DateTime startedAt;
  final Map<int, DateTime> sectionStartedAt;
  final String title;
  final bool isEphemeralPractice;

  factory Attempt.fromJson(Map<String, dynamic> json) {
    final embedded = json[AttemptColumns.testEmbed];
    final test = embedded is Map<String, dynamic> ? embedded : null;

    return Attempt(
      id: json[AttemptColumns.id] as String,
      userId: json[AttemptColumns.userId] as String,
      testId: json[AttemptColumns.testId] as String,
      status: AttemptStatus.fromString(
        json[AttemptColumns.status] as String? ?? 'in_progress',
      ),
      startedAt: _parseDate(json[AttemptColumns.startedAt]) ?? DateTime.now(),
      sectionStartedAt: parseSectionStartedAt(
        json[AttemptColumns.sectionStartedAt],
      ),
      title: test?[TestColumns.title] as String? ?? 'Test',
      isEphemeralPractice:
          test?[TestColumns.isEphemeralPractice] as bool? ?? false,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

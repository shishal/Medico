import '../../../core/supabase/tables.dart';

/// One row from `bookmarks`, with the joined `questions` row when RLS allows it.
class BookmarkedQuestion {
  const BookmarkedQuestion({
    required this.questionId,
    required this.createdAt,
    this.questionText,
    this.topicName,
    this.subjectName,
  });

  final String questionId;
  final DateTime createdAt;

  /// Null when `questions` RLS hid the embed (plan too low).
  final String? questionText;
  final String? topicName;
  final String? subjectName;

  bool get isPlanLocked => questionText == null;

  String get title {
    if (isPlanLocked) return 'Unavailable on your plan';
    final text = questionText!.trim();
    return text.isEmpty ? 'Question' : text;
  }

  String? get subtitle {
    if (subjectName != null && topicName != null) {
      return '$subjectName · $topicName';
    }
    return subjectName ?? topicName;
  }

  /// Reads a `bookmarks` join row. A null/empty `question` embed is a
  /// plan-locked bookmark, not a parse error.
  static BookmarkedQuestion? fromJson(Map<String, dynamic> json) {
    final embed = json[BookmarkColumns.questionEmbed];
    final question = _asJsonMap(embed);
    final id =
        json[BookmarkColumns.questionId] as String? ??
        question?[QuestionColumns.id] as String?;
    if (id == null || id.isEmpty) return null;

    final topic = _asJsonMap(question?[QuestionColumns.topicEmbed]);
    final subject = _asJsonMap(topic?[TopicColumns.subjectEmbed]);

    return BookmarkedQuestion(
      questionId: id,
      createdAt: _asDateTime(json[BookmarkColumns.createdAt]),
      questionText: question?[QuestionColumns.questionText] as String?,
      topicName: topic?[TopicColumns.name] as String?,
      subjectName: subject?[SubjectColumns.name] as String?,
    );
  }
}

Map<String, dynamic>? _asJsonMap(Object? raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  // PostgREST may return a one-row embed as a list.
  if (raw is List && raw.isNotEmpty) return _asJsonMap(raw.first);
  return null;
}

DateTime _asDateTime(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.utc(1970);
  return DateTime.utc(1970);
}

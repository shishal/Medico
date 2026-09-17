import '../../practice/domain/practice_enums.dart';
import 'pyq_models.dart';
import 'question_format.dart';

/// Chapter / paper / Must-Should-Could picks on the subject year list.
class SubjectPyqFilter {
  const SubjectPyqFilter({
    this.paperName,
    this.topicId,
    this.priorities = const {},
  });

  final String? paperName;
  final String? topicId;

  /// Empty = every priority.
  final Set<QuestionPriority> priorities;

  bool get isActive =>
      paperName != null || topicId != null || priorities.isNotEmpty;
}

/// Client-side chips on a subject PYQ feed. Does not score or gate plans.
List<PyqTeaser> filterSubjectPyqs({
  required List<PyqTeaser> teasers,
  QuestionFormat? format,
  String? paperName,
  int? year,
  String? topicId,
  Set<QuestionPriority> priorities = const {},
}) {
  final out = [
    for (final t in teasers)
      if ((format == null || t.format == format) &&
          (paperName == null || t.paperNames.contains(paperName)) &&
          (year == null || t.appearanceYears.contains(year)) &&
          (topicId == null || t.topicId == topicId) &&
          (priorities.isEmpty || priorities.contains(t.priority)))
        t,
  ];
  // A full paper sitting: essays first, then short, VSA, MCQ (printed order).
  if (paperName != null && year != null) {
    out.sort((a, b) {
      final byFormat = a.format.index.compareTo(b.format.index);
      if (byFormat != 0) return byFormat;
      return b.appearanceCount.compareTo(a.appearanceCount);
    });
  }
  return out;
}

/// Exam years that still have at least one teaser after chapter / paper filters.
List<int> yearsWithMatchingPyqs({
  required List<PyqTeaser> teasers,
  String? paperName,
  String? topicId,
  Set<QuestionPriority> priorities = const {},
}) {
  final filtered = filterSubjectPyqs(
    teasers: teasers,
    paperName: paperName,
    topicId: topicId,
    priorities: priorities,
  );
  final years = <int>{for (final t in filtered) ...t.appearanceYears};
  final list = years.toList()..sort((a, b) => b.compareTo(a));
  return list;
}

/// One row on the subject year list.
class SubjectYearSummary {
  const SubjectYearSummary({
    required this.year,
    required this.questionCount,
    required this.paperNames,
  });

  final int year;

  /// Questions in that sitting after the active filters.
  final int questionCount;

  /// Papers the sitting was split across, e.g. `[Paper I, Paper II]`.
  final List<String> paperNames;
}

/// Exam years plus how much is in each, so the year list can say what a tap
/// leads to instead of showing a bare number.
List<SubjectYearSummary> yearSummariesWithMatchingPyqs({
  required List<PyqTeaser> teasers,
  String? paperName,
  String? topicId,
  Set<QuestionPriority> priorities = const {},
}) {
  final filtered = filterSubjectPyqs(
    teasers: teasers,
    paperName: paperName,
    topicId: topicId,
    priorities: priorities,
  );
  final countByYear = <int, int>{};
  final papersByYear = <int, Set<String>>{};
  for (final t in filtered) {
    for (final year in t.appearanceYears) {
      countByYear[year] = (countByYear[year] ?? 0) + 1;
      (papersByYear[year] ??= <String>{}).addAll(t.paperNames);
    }
  }
  final years = countByYear.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final year in years)
      SubjectYearSummary(
        year: year,
        questionCount: countByYear[year]!,
        paperNames: (papersByYear[year]?.toList() ?? <String>[])..sort(),
      ),
  ];
}

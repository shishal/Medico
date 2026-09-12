import 'pyq_models.dart';
import 'question_format.dart';

/// Chapter / paper picks on the subject year list. Format lives on Screen 3 tabs.
class SubjectPyqFilter {
  const SubjectPyqFilter({this.paperName, this.topicId});

  final String? paperName;
  final String? topicId;

  bool get isActive => paperName != null || topicId != null;
}

/// Client-side chips on a subject PYQ feed. Does not score or gate plans.
List<PyqTeaser> filterSubjectPyqs({
  required List<PyqTeaser> teasers,
  QuestionFormat? format,
  String? paperName,
  int? year,
  String? topicId,
}) {
  final out = [
    for (final t in teasers)
      if ((format == null || t.format == format) &&
          (paperName == null || t.paperNames.contains(paperName)) &&
          (year == null || t.appearanceYears.contains(year)) &&
          (topicId == null || t.topicId == topicId))
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
}) {
  final filtered = filterSubjectPyqs(
    teasers: teasers,
    paperName: paperName,
    topicId: topicId,
  );
  final years = <int>{
    for (final t in filtered) ...t.appearanceYears,
  };
  final list = years.toList()..sort((a, b) => b.compareTo(a));
  return list;
}

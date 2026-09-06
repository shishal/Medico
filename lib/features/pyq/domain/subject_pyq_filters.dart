import 'pyq_models.dart';
import 'question_format.dart';

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

import '../../../core/supabase/tables.dart';
import '../../profile/domain/plan_tier.dart';

class PyqTeaser {
  const PyqTeaser({
    required this.id,
    this.lessonId,
    required this.questionText,
    this.marks,
    required this.requiredPlan,
    required this.appearanceCount,
  });

  final String id;
  final String? lessonId;
  final String questionText;
  final num? marks;
  final PlanTier requiredPlan;
  final int appearanceCount;

  factory PyqTeaser.fromJson(Map<String, dynamic> json) {
    return PyqTeaser(
      id: json[PyqTeaserColumns.id] as String,
      lessonId: json[PyqTeaserColumns.lessonId] as String?,
      questionText: json[PyqTeaserColumns.questionText] as String,
      marks: json[PyqTeaserColumns.marks] as num?,
      requiredPlan: PlanTier.fromString(
        json[PyqTeaserColumns.requiredPlan] as String? ?? 'free',
      ),
      appearanceCount: _asInt(json[PyqTeaserColumns.appearanceCount]),
    );
  }
}

class ResourceLink {
  const ResourceLink({
    required this.id,
    required this.title,
    required this.url,
    this.sourceLabel,
    required this.isFree,
  });

  final String id;
  final String title;
  final String url;
  final String? sourceLabel;
  final bool isFree;

  factory ResourceLink.fromJson(Map<String, dynamic> json) {
    return ResourceLink(
      id: json[ResourceColumns.id] as String,
      title: json[ResourceColumns.title] as String,
      url: json[ResourceColumns.url] as String,
      sourceLabel: json[ResourceColumns.sourceLabel] as String?,
      isFree: json[ResourceColumns.isFree] as bool? ?? false,
    );
  }
}

class TextbookCitation {
  const TextbookCitation({
    required this.title,
    this.authors,
    this.edition,
    required this.page,
    this.sectionHeading,
  });

  final String title;
  final String? authors;
  final String? edition;
  final int page;
  final String? sectionHeading;

  String get label {
    final ed = edition == null ? '' : ' ($edition)';
    final sec = sectionHeading == null ? '' : ' · $sectionHeading';
    return '$title$ed p. $page$sec';
  }

  factory TextbookCitation.fromJson(Map<String, dynamic> json) {
    final book = json[TextbookRefColumns.textbookEmbed];
    final map = book is Map<String, dynamic> ? book : <String, dynamic>{};
    return TextbookCitation(
      title: map[TextbookColumns.title] as String? ?? 'Textbook',
      authors: map[TextbookColumns.authors] as String?,
      edition: map[TextbookColumns.edition] as String?,
      page: _asInt(json[TextbookRefColumns.page]),
      sectionHeading: json[TextbookRefColumns.sectionHeading] as String?,
    );
  }
}

class ExamAppearance {
  const ExamAppearance({required this.year, required this.paperName});

  final int year;
  final String paperName;

  factory ExamAppearance.fromJson(Map<String, dynamic> json) {
    final paper = json[AppearanceColumns.examPaperEmbed];
    final map = paper is Map<String, dynamic> ? paper : <String, dynamic>{};
    return ExamAppearance(
      year: _asInt(map[ExamPaperColumns.examYear]),
      paperName: map[ExamPaperColumns.paperName] as String? ?? 'Paper',
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

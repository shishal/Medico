import '../../../core/supabase/tables.dart';

/// Subject / topic / tag lists for the Practice Builder.
class PracticeCatalog {
  const PracticeCatalog({
    required this.subjects,
    required this.topics,
    required this.tags,
  });

  final List<Subject> subjects;
  final List<Topic> topics;
  final List<PracticeTag> tags;

  List<Topic> topicsForSubjects(Set<String> subjectIds) {
    if (subjectIds.isEmpty) return topics;
    return topics.where((t) => subjectIds.contains(t.subjectId)).toList();
  }
}

class Subject {
  const Subject({
    required this.id,
    required this.name,
    required this.displayOrder,
  });

  final String id;
  final String name;
  final int displayOrder;

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json[SubjectColumns.id] as String,
      name: json[SubjectColumns.name] as String,
      displayOrder: _asInt(json[SubjectColumns.displayOrder]),
    );
  }
}

class Topic {
  const Topic({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.displayOrder,
  });

  final String id;
  final String subjectId;
  final String name;
  final int displayOrder;

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json[TopicColumns.id] as String,
      subjectId: json[TopicColumns.subjectId] as String,
      name: json[TopicColumns.name] as String,
      displayOrder: _asInt(json[TopicColumns.displayOrder]),
    );
  }
}

class PracticeTag {
  const PracticeTag({required this.id, required this.name});

  final String id;
  final String name;

  /// Chip label, e.g. `#PYQ`.
  String get chipLabel => name.startsWith('#') ? name : '#$name';

  factory PracticeTag.fromJson(Map<String, dynamic> json) {
    return PracticeTag(
      id: json[TagColumns.id] as String,
      name: json[TagColumns.name] as String,
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.parse(value.toString());
}

import 'package:flutter_test/flutter_test.dart';
import 'package:medico/core/supabase/tables.dart';
import 'package:medico/features/catalog/domain/catalog_models.dart';

void main() {
  test('LessonPickerItem reads nested topic and subject names', () {
    final item = LessonPickerItem.fromJson({
      LessonColumns.id: 'l1',
      LessonColumns.name: 'Brachial plexus',
      LessonColumns.topicEmbed: {
        TopicColumns.name: 'Upper Limb Anatomy',
        TopicColumns.subjectEmbed: {
          SubjectColumns.name: 'Anatomy',
          SubjectColumns.mbbsPhaseId: 'phase-1',
        },
      },
    });
    expect(item.subjectName, 'Anatomy');
    expect(item.topicName, 'Upper Limb Anatomy');
    expect(item.mbbsPhaseId, 'phase-1');
  });

  test('University reads is_fallback', () {
    final uni = University.fromJson({
      UniversityColumns.id: 'u1',
      UniversityColumns.code: 'KUHS',
      UniversityColumns.name: 'Kerala University of Health Sciences',
      UniversityColumns.state: 'Kerala',
      UniversityColumns.slug: 'kuhs',
      UniversityColumns.isFallback: true,
    });
    expect(uni.isFallback, isTrue);
    expect(uni.code, 'KUHS');
  });

  test('University stays usable when is_fallback is not in the row', () {
    final uni = University.fromJson({
      UniversityColumns.id: 'u1',
      UniversityColumns.code: 'KUHS',
      UniversityColumns.name: 'Kerala University of Health Sciences',
      UniversityColumns.state: 'Kerala',
      UniversityColumns.slug: 'kuhs',
    });
    expect(uni.isFallback, isFalse);
    expect(uni.code, 'KUHS');
  });

  test('University equality is by id so the picker checkmark works', () {
    const a = University(
      id: 'u1',
      code: 'KUHS',
      name: 'Kerala University of Health Sciences',
      state: 'Kerala',
      slug: 'kuhs',
    );
    const b = University(
      id: 'u1',
      code: 'KUHS',
      name: 'Kerala University of Health Sciences',
      state: 'Kerala',
      slug: 'kuhs',
    );
    expect(a, equals(b));
  });
}

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
}

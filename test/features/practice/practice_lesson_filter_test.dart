import 'package:flutter_test/flutter_test.dart';
import 'package:medico/features/practice/domain/practice_builder_draft.dart';
import 'package:medico/features/practice/domain/practice_enums.dart';

void main() {
  test('lessonIds stay on the draft used for lesson-scoped MCQ practice', () {
    const draft = PracticeBuilderDraft(
      sourceFilter: QuestionSourceFilter.all,
      lessonIds: {'lesson-1'},
    );
    expect(draft.lessonIds, {'lesson-1'});
    expect(draft.copyWith(questionCount: 5).lessonIds, {'lesson-1'});
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:medico/features/pyq/domain/question_format.dart';

void main() {
  test('MCQ kind is always MCQ regardless of marks', () {
    expect(
      QuestionFormat.fromKindAndMarks(kind: 'mcq', marks: 10),
      QuestionFormat.mcq,
    );
    expect(
      QuestionFormat.fromKindAndMarks(kind: 'mcq', marks: null),
      QuestionFormat.mcq,
    );
  });

  test('theory marks map to Essay / Short note / VSA', () {
    expect(
      QuestionFormat.fromKindAndMarks(kind: 'pyq_theory', marks: 10),
      QuestionFormat.essay,
    );
    expect(
      QuestionFormat.fromKindAndMarks(kind: 'pyq_theory', marks: 5),
      QuestionFormat.shortNote,
    );
    expect(
      QuestionFormat.fromKindAndMarks(kind: 'pyq_theory', marks: 4),
      QuestionFormat.shortNote,
    );
    expect(
      QuestionFormat.fromKindAndMarks(kind: 'pyq_theory', marks: 3),
      QuestionFormat.vsa,
    );
    expect(
      QuestionFormat.fromKindAndMarks(kind: 'pyq_theory', marks: 2),
      QuestionFormat.vsa,
    );
    expect(
      QuestionFormat.fromKindAndMarks(kind: 'pyq_theory', marks: null),
      QuestionFormat.essay,
    );
  });
}

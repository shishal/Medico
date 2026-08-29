import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:medico/features/practice/domain/practice_enums.dart';
import 'package:medico/features/tests/data/local_attempt_store.dart';
import 'package:medico/features/tests/domain/attempt_status.dart';
import 'package:medico/features/tests/domain/local_attempt_snapshot.dart';
import 'package:medico/features/tests/domain/player_question.dart';
import 'package:medico/features/tests/domain/question_answer.dart';
import 'package:medico/features/tests/domain/question_option.dart';

void main() {
  late Directory tempDir;
  late LocalAttemptStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('medico_attempts_');
    store = LocalAttemptStore(documentsDirectory: () async => tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  LocalAttemptSnapshot snapshot({
    required String attemptId,
    required String testId,
    required String userId,
  }) {
    return LocalAttemptSnapshot(
      attemptId: attemptId,
      testId: testId,
      userId: userId,
      title: 'Mini Test',
      startedAt: DateTime.utc(2026, 8, 29, 12),
      sectionStartedAt: {1: DateTime.utc(2026, 8, 29, 12)},
      currentIndex: 0,
      localStatus: LocalAttemptStatus.inProgress,
      feedbackTiming: FeedbackTiming.onSubmit,
      explanationLevel: ExplanationLevel.full,
      isEphemeralPractice: false,
      answers: {
        'q1': const QuestionAnswer(
          visited: true,
          selectedOption: QuestionOption.a,
        ),
      },
      questions: [
        const PlayerQuestion(
          id: 'q1',
          orderIndex: 0,
          sectionNumber: 1,
          questionText: 'Stem',
          optionA: 'A',
          optionB: 'B',
          optionC: 'C',
          optionD: 'D',
          correctOption: QuestionOption.a,
        ),
      ],
    );
  }

  test('write then read restores selected answers', () async {
    await store.write(snapshot(attemptId: 'att-1', testId: 't1', userId: 'u1'));

    final loaded = await store.read('att-1');
    expect(loaded, isNotNull);
    expect(loaded!.answers['q1']!.selectedOption, QuestionOption.a);
    expect(loaded.questions.single.id, 'q1');
  });

  test(
    'readInProgressForTest ignores another user on the same device',
    () async {
      await store.write(
        snapshot(attemptId: 'att-a', testId: 't1', userId: 'user-a'),
      );

      final forB = await store.readInProgressForTest(
        testId: 't1',
        userId: 'user-b',
      );
      expect(forB, isNull);

      final forA = await store.readInProgressForTest(
        testId: 't1',
        userId: 'user-a',
      );
      expect(forA?.attemptId, 'att-a');
    },
  );
}

import 'package:flutter_test/flutter_test.dart';

import 'package:medico/features/results/domain/attempt_results.dart';

void main() {
  final sampleJson = {
    'id': 'a1',
    'test_id': 't1',
    'test_title': 'Mini Test 1',
    'total_score': 7,
    'correct_count': 2,
    'incorrect_count': 1,
    'unattempted_count': 1,
    'percentile': 50.0,
    'submitted_at': '2026-08-29T12:00:00.000Z',
    'duration_seconds': 125,
    'question_time_seconds': 100,
    'is_ephemeral_practice': false,
    'correct_marks': 4,
    'incorrect_marks': -1,
    'unattempted_marks': 0,
    'subjects': [
      {
        'subject_id': 's-med',
        'subject_name': 'Medicine',
        'correct_count': 1,
        'incorrect_count': 1,
        'unattempted_count': 0,
      },
      {
        'subject_id': 's-surg',
        'subject_name': 'Surgery',
        'correct_count': 1,
        'incorrect_count': 0,
        'unattempted_count': 1,
      },
    ],
  };

  group('AttemptResults', () {
    test('fromJson parses score, percentile, and subjects', () {
      final results = AttemptResults.fromJson(sampleJson);

      expect(results.attemptId, 'a1');
      expect(results.testTitle, 'Mini Test 1');
      expect(results.totalScore, 7);
      expect(results.correctCount, 2);
      expect(results.incorrectCount, 1);
      expect(results.unattemptedCount, 1);
      expect(results.percentile, 50);
      expect(results.durationSeconds, 125);
      expect(results.usesNeetStyleScore, isTrue);
      expect(results.subjects, hasLength(2));
      expect(results.subjects.first.subjectName, 'Medicine');
    });

    test('subject-wise counts sum to overall totals', () {
      final results = AttemptResults.fromJson(sampleJson);
      expect(results.subjectTotalsMatchOverall, isTrue);
      expect(results.questionCount, 4);
    });

    test('accuracy is correct / all questions', () {
      final results = AttemptResults.fromJson(sampleJson);
      expect(results.accuracyPercent, 50);
      expect(results.accuracyLabel, '50%');
      expect(results.maxScore, 16);
      expect(results.scoreLabel, '7');
    });

    test('practice without negative marking uses accuracy as the hero', () {
      final results = AttemptResults.fromJson({
        ...sampleJson,
        'total_score': 2,
        'is_ephemeral_practice': true,
        'correct_marks': 1,
        'incorrect_marks': 0,
        'unattempted_marks': 0,
        'percentile': 100,
      });

      expect(results.usesNeetStyleScore, isFalse);
      expect(results.isEphemeralPractice, isTrue);
      expect(results.accuracyLabel, '50%');
    });

    test('numeric strings and ints parse', () {
      final results = AttemptResults.fromJson({
        ...sampleJson,
        'total_score': '7.5',
        'correct_count': '2',
        'percentile': 100,
        'subjects': [
          {
            'subject_id': 's1',
            'subject_name': 'Medicine',
            'correct_count': 2,
            'incorrect_count': 1,
            'unattempted_count': 1,
          },
        ],
      });

      expect(results.totalScore, 7.5);
      expect(results.scoreLabel, '7.5');
      expect(results.percentileLabel, '100');
      expect(results.subjectTotalsMatchOverall, isTrue);
    });
  });

  group('formatTimeSpent', () {
    test('formats seconds, minutes, and hours', () {
      expect(formatTimeSpent(0), '0s');
      expect(formatTimeSpent(45), '45s');
      expect(formatTimeSpent(60), '1m');
      expect(formatTimeSpent(125), '2m 5s');
      expect(formatTimeSpent(3600), '1h');
      expect(formatTimeSpent(3720), '1h 2m');
    });
  });
}

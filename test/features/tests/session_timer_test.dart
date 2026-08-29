import 'package:flutter_test/flutter_test.dart';

import 'package:medico/core/utils/wall_clock.dart';
import 'package:medico/features/practice/domain/practice_enums.dart';
import 'package:medico/features/tests/domain/attempt_status.dart';
import 'package:medico/features/tests/domain/player_question.dart';
import 'package:medico/features/tests/domain/player_session_state.dart';
import 'package:medico/features/tests/domain/question_option.dart';
import 'package:medico/features/tests/domain/session_timer.dart';
import 'package:medico/features/tests/domain/test_player_bundle.dart';

PlayerQuestion _q({required String id, required int section, int order = 0}) {
  return PlayerQuestion(
    id: id,
    orderIndex: order,
    sectionNumber: section,
    questionText: 'Stem $id',
    optionA: 'A',
    optionB: 'B',
    optionC: 'C',
    optionD: 'D',
    correctOption: QuestionOption.a,
  );
}

PlayerSessionState _nonSectional({
  required DateTime startedAt,
  int minutes = 10,
  bool timerEnabled = true,
}) {
  return PlayerSessionState.fromBundle(
    TestPlayerBundle(
      testId: 't1',
      title: 'Mini',
      feedbackTiming: FeedbackTiming.onSubmit,
      explanationLevel: ExplanationLevel.full,
      isEphemeralPractice: false,
      totalDurationMinutes: minutes,
      timerEnabled: timerEnabled,
      questions: [
        _q(id: 'q1', section: 1),
        _q(id: 'q2', section: 1, order: 1),
      ],
    ),
    attemptId: 'att-1',
    startedAt: startedAt,
  );
}

PlayerSessionState _sectional({required DateTime startedAt, int minutes = 5}) {
  return PlayerSessionState.fromBundle(
    TestPlayerBundle(
      testId: 'grand',
      title: 'Grand',
      feedbackTiming: FeedbackTiming.onSubmit,
      explanationLevel: ExplanationLevel.full,
      isEphemeralPractice: false,
      isSectional: true,
      sectionCount: 2,
      questionsPerSection: 2,
      sectionDurationMinutes: minutes,
      totalDurationMinutes: minutes * 2,
      questions: [
        _q(id: 'q1', section: 1),
        _q(id: 'q2', section: 1, order: 1),
        _q(id: 'q3', section: 2, order: 2),
        _q(id: 'q4', section: 2, order: 3),
      ],
    ),
    attemptId: 'att-g',
    startedAt: startedAt,
  );
}

void main() {
  final start = DateTime.utc(2026, 8, 29, 12);

  group('WallClock', () {
    test('trusts the server when skew exceeds two minutes', () {
      final clock = WallClock(now: () => start);
      final skewed = clock.reconcile(
        serverNow: start.add(const Duration(minutes: 5)),
        localNow: start,
      );
      expect(skewed.now(), start.add(const Duration(minutes: 5)));
    });

    test('ignores jitter under two minutes', () {
      final clock = WallClock(now: () => start);
      final aligned = clock.reconcile(
        serverNow: start.add(const Duration(minutes: 1)),
        localNow: start,
      );
      expect(aligned.now(), start);
    });

    test(
      'mergeSectionStartedAt keeps local-only keys and trusts server on skew',
      () {
        final local = {1: start, 2: start.add(const Duration(minutes: 10))};
        final server = {1: start.add(const Duration(minutes: 8))};
        final merged = mergeSectionStartedAt(local, server);
        expect(merged[1], start.add(const Duration(minutes: 8)));
        expect(merged[2], start.add(const Duration(minutes: 10)));
      },
    );
  });

  group('formatCountdown', () {
    test('uses MM:SS under an hour and HH:MM:SS at or above', () {
      expect(formatCountdown(const Duration(minutes: 5, seconds: 7)), '05:07');
      expect(
        formatCountdown(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '01:02:03',
      );
    });
  });

  group('non-sectional timer', () {
    test(
      'remaining is duration minus wall-clock elapsed, not a stored countdown',
      () {
        final session = _nonSectional(startedAt: start, minutes: 10);
        expect(
          session.remainingAt(start.add(const Duration(minutes: 3))),
          const Duration(minutes: 7),
        );
      },
    );

    test('hitting zero auto-submits exactly once', () {
      var session = _nonSectional(startedAt: start, minutes: 10);
      final expiredAt = start.add(const Duration(minutes: 10));
      session = session.applyTimerExpiry(expiredAt);
      expect(session.localStatus, LocalAttemptStatus.pendingSubmit);
      expect(session.isPendingSubmit, isTrue);

      final again = session.applyTimerExpiry(
        expiredAt.add(const Duration(minutes: 5)),
      );
      expect(identical(again, session), isTrue);
    });

    test('resume after the test should have ended auto-submits', () {
      final session = _nonSectional(startedAt: start, minutes: 1);
      final late = session.applyTimerExpiry(
        start.add(const Duration(minutes: 3)),
      );
      expect(late.isPendingSubmit, isTrue);
    });

    test('timer_enabled false never auto-submits', () {
      final session = _nonSectional(
        startedAt: start,
        minutes: 10,
        timerEnabled: false,
      );
      expect(session.showsTimer, isFalse);
      expect(session.remainingAt(start.add(const Duration(hours: 2))), isNull);
      expect(
        session.applyTimerExpiry(start.add(const Duration(hours: 2))),
        same(session),
      );
    });
  });

  group('sectional lock', () {
    test(
      'palette cannot reach another section until this one is submitted',
      () {
        final session = _sectional(startedAt: start);
        expect(session.isIndexReachable(0), isTrue);
        expect(session.isIndexReachable(1), isTrue);
        expect(session.isIndexReachable(2), isFalse);
        expect(session.goTo(2).currentIndex, 0);
        expect(session.canGoNext, isTrue);
      },
    );

    test(
      'Save & Next at the last question of a section does not leak forward',
      () {
        var session = _sectional(startedAt: start);
        session = session.goTo(1);
        expect(session.canGoNext, isFalse);
        expect(session.saveAndNext().currentIndex, 1);
      },
    );

    test('submitting a section locks it and starts the next clock at now', () {
      var session = _sectional(startedAt: start);
      final enterSecond = start.add(const Duration(minutes: 2));
      session = session.submitSection(enterSecond);

      expect(session.currentSection, 2);
      expect(session.currentIndex, 2);
      expect(session.isIndexReachable(0), isFalse);
      expect(session.goTo(0).currentIndex, 2);
      expect(session.sectionStartedAt[2], enterSecond);
      expect(
        session.remainingAt(enterSecond.add(const Duration(minutes: 1))),
        const Duration(minutes: 4),
      );
    });

    test(
      'section timer hitting zero auto-advances and locks the old section',
      () {
        var session = _sectional(startedAt: start, minutes: 5);
        final expiry = start.add(const Duration(minutes: 5));
        session = session.applyTimerExpiry(expiry);

        expect(session.isPendingSubmit, isFalse);
        expect(session.currentSection, 2);
        expect(session.isIndexReachable(0), isFalse);
        expect(session.isIndexReachable(2), isTrue);
        expect(session.sectionStartedAt[2], expiry);
      },
    );

    test('unentered later sections do not expire while the app was closed', () {
      var session = _sectional(startedAt: start, minutes: 5);
      final muchLater = start.add(const Duration(hours: 3));
      session = session.applyTimerExpiry(muchLater);

      expect(session.isPendingSubmit, isFalse);
      expect(session.currentSection, 2);
      expect(session.remainingAt(muchLater), const Duration(minutes: 5));
    });

    test('final section expiry submits the whole test once', () {
      var session = _sectional(startedAt: start, minutes: 5);
      final firstExpiry = start.add(const Duration(minutes: 5));
      session = session.applyTimerExpiry(firstExpiry);
      expect(session.currentSection, 2);

      session = session.applyTimerExpiry(
        firstExpiry.add(const Duration(minutes: 5)),
      );
      expect(session.isPendingSubmit, isTrue);
      final again = session.applyTimerExpiry(
        firstExpiry.add(const Duration(hours: 1)),
      );
      expect(identical(again, session), isTrue);
    });

    test('submit-section dialog count includes unanswered in the current section only', () {
      var session = _sectional(startedAt: start);
      session = session.selectOption(QuestionOption.a);
      expect(session.unansweredInCurrentSection(), 1);

      session = session.submitSection(start.add(const Duration(minutes: 1)));
      expect(session.unansweredInCurrentSection(), 2);
    });
  });
}

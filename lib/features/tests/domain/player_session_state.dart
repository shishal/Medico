import '../../practice/domain/practice_enums.dart';
import 'attempt_status.dart';
import 'local_attempt_snapshot.dart';
import 'palette_cell.dart';
import 'player_question.dart';
import 'question_answer.dart';
import 'question_option.dart';
import 'test_player_bundle.dart';

/// What the Tutor Mode panel should show after an option is locked.
///
/// Null in Exam Mode — that is the "no reveal until submit" guarantee.
class FeedbackReveal {
  const FeedbackReveal({
    required this.isCorrect,
    required this.highlightCorrectOption,
    this.explanationText,
  });

  final bool isCorrect;
  final bool highlightCorrectOption;
  final String? explanationText;
}

/// How one option chip should look. Exam Mode only uses [idle] / [selected].
enum OptionVisual {
  idle,
  selected,
  chosenCorrect,
  chosenIncorrect,
  revealedCorrect,
}

/// In-memory player session. Mutations return a new instance (immutable).
///
/// Answers live here and in a local JSON snapshot (Phase 5.1). Timers and
/// server-side scoring arrive in 5.3 / 6.1.
class PlayerSessionState {
  const PlayerSessionState({
    required this.attemptId,
    required this.testId,
    required this.title,
    required this.feedbackTiming,
    required this.explanationLevel,
    required this.isEphemeralPractice,
    required this.questions,
    required this.answers,
    required this.currentIndex,
    required this.startedAt,
    required this.sectionStartedAt,
    this.localStatus = LocalAttemptStatus.inProgress,
  });

  factory PlayerSessionState.fromBundle(
    TestPlayerBundle bundle, {
    String attemptId = 'local',
    DateTime? startedAt,
  }) {
    final firstId = bundle.questions.first.id;
    final start = startedAt ?? DateTime.now();
    final firstSection = bundle.questions.first.sectionNumber;
    return PlayerSessionState(
      attemptId: attemptId,
      testId: bundle.testId,
      title: bundle.title,
      feedbackTiming: bundle.feedbackTiming,
      explanationLevel: bundle.explanationLevel,
      isEphemeralPractice: bundle.isEphemeralPractice,
      questions: bundle.questions,
      answers: {firstId: const QuestionAnswer(visited: true)},
      currentIndex: 0,
      startedAt: start,
      sectionStartedAt: {firstSection: start},
    );
  }

  factory PlayerSessionState.fromSnapshot(LocalAttemptSnapshot snapshot) {
    final clamped = snapshot.questions.isEmpty
        ? 0
        : snapshot.currentIndex.clamp(0, snapshot.questions.length - 1);
    final answers = Map<String, QuestionAnswer>.from(snapshot.answers);
    if (snapshot.questions.isNotEmpty) {
      final current = snapshot.questions[clamped];
      answers[current.id] = (answers[current.id] ?? const QuestionAnswer())
          .copyWith(visited: true);
    }
    return PlayerSessionState(
      attemptId: snapshot.attemptId,
      testId: snapshot.testId,
      title: snapshot.title,
      feedbackTiming: snapshot.feedbackTiming,
      explanationLevel: snapshot.explanationLevel,
      isEphemeralPractice: snapshot.isEphemeralPractice,
      questions: snapshot.questions,
      answers: answers,
      currentIndex: clamped,
      startedAt: snapshot.startedAt,
      sectionStartedAt: snapshot.sectionStartedAt,
      localStatus: snapshot.localStatus,
    );
  }

  final String attemptId;
  final String testId;
  final String title;
  final FeedbackTiming feedbackTiming;
  final ExplanationLevel explanationLevel;
  final bool isEphemeralPractice;
  final List<PlayerQuestion> questions;
  final Map<String, QuestionAnswer> answers;
  final int currentIndex;
  final DateTime startedAt;
  final Map<int, DateTime> sectionStartedAt;
  final LocalAttemptStatus localStatus;

  bool get isTutorMode => feedbackTiming == FeedbackTiming.immediate;

  PlayerQuestion get currentQuestion => questions[currentIndex];

  QuestionAnswer get currentAnswer => answerFor(currentQuestion);

  bool get isLastQuestion => currentIndex >= questions.length - 1;

  /// Tutor Mode locks the option the moment it is chosen.
  bool get isCurrentAnswerLocked =>
      isTutorMode && currentAnswer.selectedOption != null;

  /// Exam Mode is always false. Tutor Mode is true only after a selection.
  /// Every reveal UI must go through this getter — do not check correctness
  /// any other way in widgets, or Exam Mode will leak.
  bool get revealsFeedback =>
      isTutorMode && currentAnswer.selectedOption != null;

  QuestionAnswer answerFor(PlayerQuestion question) =>
      answers[question.id] ?? const QuestionAnswer();

  PaletteCell paletteAt(int index) {
    final question = questions[index];
    return PaletteCell.fromAnswer(
      questionNumber: index + 1,
      answer: answerFor(question),
      correctOption: question.correctOption,
      feedbackTiming: feedbackTiming,
    );
  }

  FeedbackReveal? get feedbackReveal {
    if (!revealsFeedback) return null;
    final selected = currentAnswer.selectedOption!;
    final isCorrect = selected == currentQuestion.correctOption;
    final showAnswer = explanationLevel != ExplanationLevel.none;
    final showText = explanationLevel == ExplanationLevel.full;
    final raw = currentQuestion.explanationText?.trim();
    return FeedbackReveal(
      isCorrect: isCorrect,
      highlightCorrectOption: showAnswer,
      explanationText: showText && raw != null && raw.isNotEmpty ? raw : null,
    );
  }

  OptionVisual visualFor(QuestionOption option) {
    final reveal = feedbackReveal;
    if (reveal == null) {
      return currentAnswer.selectedOption == option
          ? OptionVisual.selected
          : OptionVisual.idle;
    }
    final selected = currentAnswer.selectedOption!;
    final correct = currentQuestion.correctOption;
    if (option == selected && option == correct) {
      return OptionVisual.chosenCorrect;
    }
    if (option == selected && option != correct) {
      return OptionVisual.chosenIncorrect;
    }
    if (reveal.highlightCorrectOption && option == correct) {
      return OptionVisual.revealedCorrect;
    }
    return OptionVisual.idle;
  }

  PlayerSessionState selectOption(QuestionOption option) {
    if (isCurrentAnswerLocked) return this;
    return _writeCurrent(
      currentAnswer.copyWith(visited: true, selectedOption: option),
    );
  }

  PlayerSessionState clearResponse() {
    if (isCurrentAnswerLocked) return this;
    return _writeCurrent(currentAnswer.withoutSelection());
  }

  PlayerSessionState toggleMark() {
    return _writeCurrent(
      currentAnswer.copyWith(
        visited: true,
        markedForReview: !currentAnswer.markedForReview,
      ),
    );
  }

  /// Spec action: set the marked flag (keeping the answer) and advance.
  PlayerSessionState markForReviewAndNext() {
    final marked = _writeCurrent(
      currentAnswer.copyWith(visited: true, markedForReview: true),
    );
    return marked.goTo(currentIndex + 1);
  }

  PlayerSessionState saveAndNext() => goTo(currentIndex + 1);

  PlayerSessionState goTo(int index) {
    if (index < 0 || index >= questions.length) return this;
    final target = questions[index];
    return copyWith(
      answers: {
        ...answers,
        target.id: answerFor(target).copyWith(visited: true),
      },
      currentIndex: index,
    );
  }

  PlayerSessionState addTimeToCurrent(int seconds) {
    if (seconds <= 0) return this;
    return _writeCurrent(currentAnswer.addTime(seconds));
  }

  /// Re-apply saved answers onto a freshly downloaded question list.
  PlayerSessionState restoreProgress({
    required Map<String, QuestionAnswer> savedAnswers,
    required int savedIndex,
    Map<int, DateTime>? savedSectionStartedAt,
  }) {
    final clamped = savedIndex.clamp(0, questions.length - 1);
    final target = questions[clamped];
    return copyWith(
      answers: {
        ...savedAnswers,
        target.id: (savedAnswers[target.id] ?? const QuestionAnswer()).copyWith(
          visited: true,
        ),
      },
      currentIndex: clamped,
      sectionStartedAt: savedSectionStartedAt ?? sectionStartedAt,
    );
  }

  LocalAttemptSnapshot toSnapshot({required String userId}) {
    return LocalAttemptSnapshot(
      attemptId: attemptId,
      testId: testId,
      userId: userId,
      title: title,
      startedAt: startedAt,
      sectionStartedAt: sectionStartedAt,
      currentIndex: currentIndex,
      localStatus: localStatus,
      feedbackTiming: feedbackTiming,
      explanationLevel: explanationLevel,
      isEphemeralPractice: isEphemeralPractice,
      answers: answers,
      questions: questions,
    );
  }

  PlayerSessionState copyWith({
    String? attemptId,
    String? testId,
    String? title,
    FeedbackTiming? feedbackTiming,
    ExplanationLevel? explanationLevel,
    bool? isEphemeralPractice,
    List<PlayerQuestion>? questions,
    Map<String, QuestionAnswer>? answers,
    int? currentIndex,
    DateTime? startedAt,
    Map<int, DateTime>? sectionStartedAt,
    LocalAttemptStatus? localStatus,
  }) {
    return PlayerSessionState(
      attemptId: attemptId ?? this.attemptId,
      testId: testId ?? this.testId,
      title: title ?? this.title,
      feedbackTiming: feedbackTiming ?? this.feedbackTiming,
      explanationLevel: explanationLevel ?? this.explanationLevel,
      isEphemeralPractice: isEphemeralPractice ?? this.isEphemeralPractice,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      currentIndex: currentIndex ?? this.currentIndex,
      startedAt: startedAt ?? this.startedAt,
      sectionStartedAt: sectionStartedAt ?? this.sectionStartedAt,
      localStatus: localStatus ?? this.localStatus,
    );
  }

  PlayerSessionState _writeCurrent(QuestionAnswer next) {
    return copyWith(answers: {...answers, currentQuestion.id: next});
  }
}

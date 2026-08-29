import '../../practice/domain/practice_enums.dart';
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
/// Attempt rows, autosave, and timers are Phase 5 — this type is the
/// behavioral core that 4B.3 branches on [feedbackTiming].
class PlayerSessionState {
  const PlayerSessionState({
    required this.testId,
    required this.title,
    required this.feedbackTiming,
    required this.explanationLevel,
    required this.isEphemeralPractice,
    required this.questions,
    required this.answers,
    required this.currentIndex,
  });

  factory PlayerSessionState.fromBundle(TestPlayerBundle bundle) {
    final firstId = bundle.questions.first.id;
    return PlayerSessionState(
      testId: bundle.testId,
      title: bundle.title,
      feedbackTiming: bundle.feedbackTiming,
      explanationLevel: bundle.explanationLevel,
      isEphemeralPractice: bundle.isEphemeralPractice,
      questions: bundle.questions,
      answers: {firstId: const QuestionAnswer(visited: true)},
      currentIndex: 0,
    );
  }

  final String testId;
  final String title;
  final FeedbackTiming feedbackTiming;
  final ExplanationLevel explanationLevel;
  final bool isEphemeralPractice;
  final List<PlayerQuestion> questions;
  final Map<String, QuestionAnswer> answers;
  final int currentIndex;

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
    return PlayerSessionState(
      testId: testId,
      title: title,
      feedbackTiming: feedbackTiming,
      explanationLevel: explanationLevel,
      isEphemeralPractice: isEphemeralPractice,
      questions: questions,
      answers: {
        ...answers,
        target.id: answerFor(target).copyWith(visited: true),
      },
      currentIndex: index,
    );
  }

  PlayerSessionState _writeCurrent(QuestionAnswer next) {
    return PlayerSessionState(
      testId: testId,
      title: title,
      feedbackTiming: feedbackTiming,
      explanationLevel: explanationLevel,
      isEphemeralPractice: isEphemeralPractice,
      questions: questions,
      answers: {...answers, currentQuestion.id: next},
      currentIndex: currentIndex,
    );
  }
}

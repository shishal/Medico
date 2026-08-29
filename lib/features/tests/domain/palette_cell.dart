import '../../practice/domain/practice_enums.dart';
import 'question_answer.dart';
import 'question_option.dart';

/// Semantic palette state — Exam Mode uses answered/not-answered; Tutor Mode
/// uses correct/incorrect once a question is revealed.
enum PaletteKind {
  notVisited,
  notAnswered,
  skipped,
  answered,
  correct,
  incorrect,
}

enum PaletteFill { grey, red, green, purple, none }

enum PaletteOutline { none, red, purple }

/// One cell in the question palette. Visuals are derived here so the widget
/// does not re-implement Exam vs Tutor rules.
class PaletteCell {
  const PaletteCell({
    required this.questionNumber,
    required this.kind,
    required this.markedForReview,
    required this.isTutorMode,
  });

  final int questionNumber;
  final PaletteKind kind;
  final bool markedForReview;
  final bool isTutorMode;

  factory PaletteCell.fromAnswer({
    required int questionNumber,
    required QuestionAnswer answer,
    required QuestionOption correctOption,
    required FeedbackTiming feedbackTiming,
  }) {
    final isTutor = feedbackTiming == FeedbackTiming.immediate;
    final kind = _kind(
      answer: answer,
      correctOption: correctOption,
      isTutor: isTutor,
    );
    return PaletteCell(
      questionNumber: questionNumber,
      kind: kind,
      markedForReview: answer.markedForReview,
      isTutorMode: isTutor,
    );
  }

  static PaletteKind _kind({
    required QuestionAnswer answer,
    required QuestionOption correctOption,
    required bool isTutor,
  }) {
    if (!answer.visited) return PaletteKind.notVisited;
    final selected = answer.selectedOption;
    if (isTutor) {
      if (selected == null) return PaletteKind.skipped;
      return selected == correctOption
          ? PaletteKind.correct
          : PaletteKind.incorrect;
    }
    return selected == null ? PaletteKind.notAnswered : PaletteKind.answered;
  }

  PaletteFill get fill {
    if (isTutorMode) {
      return switch (kind) {
        PaletteKind.notVisited => PaletteFill.grey,
        PaletteKind.skipped => PaletteFill.none,
        PaletteKind.correct => PaletteFill.green,
        PaletteKind.incorrect => PaletteFill.red,
        PaletteKind.notAnswered || PaletteKind.answered => PaletteFill.grey,
      };
    }
    // Exam Mode: marked-unanswered and marked-answered both use purple fill
    // (with a green check on the latter) — the convention students know.
    if (markedForReview) return PaletteFill.purple;
    return switch (kind) {
      PaletteKind.notVisited => PaletteFill.grey,
      PaletteKind.notAnswered || PaletteKind.skipped => PaletteFill.red,
      PaletteKind.answered || PaletteKind.correct => PaletteFill.green,
      PaletteKind.incorrect => PaletteFill.red,
    };
  }

  PaletteOutline get outline {
    if (!isTutorMode) return PaletteOutline.none;
    if (markedForReview) return PaletteOutline.purple;
    if (kind == PaletteKind.skipped) return PaletteOutline.red;
    return PaletteOutline.none;
  }

  /// Exam Mode "Answered & Marked for Review" — purple cell with a green check.
  bool get showGreenCheck =>
      !isTutorMode && markedForReview && kind == PaletteKind.answered;

  /// Tutor Mode overlay so a correct/incorrect/skipped cell can also be flagged.
  bool get showReviewDot => isTutorMode && markedForReview;

  String get semanticsLabel {
    final status = switch (kind) {
      PaletteKind.notVisited => 'not visited',
      PaletteKind.notAnswered => 'not answered',
      PaletteKind.skipped => 'skipped',
      PaletteKind.answered => 'answered',
      PaletteKind.correct => 'correct',
      PaletteKind.incorrect => 'incorrect',
    };
    final review = markedForReview ? ', marked for review' : '';
    return 'Question $questionNumber, $status$review';
  }
}

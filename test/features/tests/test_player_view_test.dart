import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medico/features/practice/domain/practice_enums.dart';
import 'package:medico/features/tests/domain/palette_cell.dart';
import 'package:medico/features/tests/domain/player_question.dart';
import 'package:medico/features/tests/domain/player_session_state.dart';
import 'package:medico/features/tests/domain/question_option.dart';
import 'package:medico/features/tests/domain/test_player_bundle.dart';
import 'package:medico/features/tests/presentation/widgets/test_player_view.dart';

const _explanation = 'Because mitochondria produce ATP.';

PlayerSessionState _session(FeedbackTiming timing) {
  return PlayerSessionState.fromBundle(
    TestPlayerBundle(
      testId: 't1',
      title: 'Session',
      feedbackTiming: timing,
      explanationLevel: ExplanationLevel.full,
      isEphemeralPractice: true,
      questions: [
        const PlayerQuestion(
          id: 'q1',
          orderIndex: 1,
          sectionNumber: 1,
          questionText: 'Which organelle produces ATP?',
          optionA: 'Mitochondria',
          optionB: 'Ribosome',
          optionC: 'Golgi',
          optionD: 'Nucleus',
          correctOption: QuestionOption.a,
          explanationText: _explanation,
        ),
        const PlayerQuestion(
          id: 'q2',
          orderIndex: 2,
          sectionNumber: 1,
          questionText: 'Second question',
          optionA: 'A2',
          optionB: 'B2',
          optionC: 'C2',
          optionD: 'D2',
          correctOption: QuestionOption.b,
        ),
      ],
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  ValueNotifier<PlayerSessionState> session,
) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: ValueListenableBuilder<PlayerSessionState>(
        valueListenable: session,
        builder: (context, value, _) {
          return TestPlayerView(
            session: value,
            onSelectOption: (option) =>
                session.value = value.selectOption(option),
            onGoTo: (index) => session.value = value.goTo(index),
            onClear: () => session.value = value.clearResponse(),
            onToggleMark: () => session.value = value.toggleMark(),
            onMarkAndNext: () => session.value = value.markForReviewAndNext(),
            onPrevious: () => session.value = value.previous(),
            onSaveAndNext: () => session.value = value.saveAndNext(),
            onFinish: () {},
            onExit: () {},
          );
        },
      ),
    ),
  );
}

void main() {
  testWidgets('Tutor Mode locks the option and shows feedback', (tester) async {
    final session = ValueNotifier(_session(FeedbackTiming.immediate));
    addTearDown(session.dispose);
    await _pump(tester, session);

    await tester.tap(find.byKey(const Key('option-A')));
    await tester.pump();

    expect(find.text('Correct'), findsOneWidget);
    expect(find.text(_explanation), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsWidgets);

    await tester.tap(find.byKey(const Key('option-B')));
    await tester.pump();

    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('Incorrect'), findsNothing);
    expect(session.value.currentAnswer.selectedOption, QuestionOption.a);
  });

  testWidgets('Exam Mode never shows correctness or explanation', (
    tester,
  ) async {
    final session = ValueNotifier(_session(FeedbackTiming.onSubmit));
    addTearDown(session.dispose);
    await _pump(tester, session);

    await tester.tap(find.byKey(const Key('option-A')));
    await tester.pump();

    expect(find.text('Correct'), findsNothing);
    expect(find.text('Incorrect'), findsNothing);
    expect(find.text(_explanation), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.byIcon(Icons.cancel), findsNothing);
    expect(find.textContaining('Tutor Mode'), findsNothing);

    await tester.tap(find.byKey(const Key('option-B')));
    await tester.pump();

    expect(session.value.currentAnswer.selectedOption, QuestionOption.b);
    expect(find.text('Correct'), findsNothing);
    expect(find.text(_explanation), findsNothing);
  });

  testWidgets('Tutor Mode palette reports correct, not generic answered', (
    tester,
  ) async {
    final session = ValueNotifier(_session(FeedbackTiming.immediate));
    addTearDown(session.dispose);
    await _pump(tester, session);

    await tester.tap(find.byKey(const Key('option-A')));
    await tester.pump();

    expect(session.value.paletteAt(0).kind, PaletteKind.correct);

    await tester.tap(find.byKey(const Key('question-palette-button')));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Question 1, correct'), findsOneWidget);
  });

  testWidgets('Exam Mode palette walks every spec state', (tester) async {
    final session = ValueNotifier(_session(FeedbackTiming.onSubmit));
    addTearDown(session.dispose);
    await _pump(tester, session);

    expect(session.value.paletteAt(0).kind, PaletteKind.notAnswered);
    expect(session.value.paletteAt(1).kind, PaletteKind.notVisited);

    await tester.tap(find.byKey(const Key('option-A')));
    await tester.pump();
    expect(session.value.paletteAt(0).kind, PaletteKind.answered);
    expect(session.value.paletteAt(0).fill, PaletteFill.green);

    await tester.tap(find.byKey(const Key('player-mark-next')));
    await tester.pump();
    expect(session.value.currentIndex, 1);
    expect(session.value.paletteAt(0).fill, PaletteFill.purple);
    expect(session.value.paletteAt(0).showGreenCheck, isTrue);

    await tester.tap(find.byKey(const Key('player-previous')));
    await tester.pump();
    expect(session.value.currentIndex, 0);

    await tester.tap(find.byKey(const Key('player-clear')));
    await tester.pump();
    expect(session.value.paletteAt(0).kind, PaletteKind.notAnswered);
    expect(session.value.paletteAt(0).fill, PaletteFill.purple);
    expect(session.value.paletteAt(0).showGreenCheck, isFalse);

    await tester.tap(find.byKey(const Key('question-palette-button')));
    await tester.pumpAndSettle();

    expect(find.text('Not Visited'), findsOneWidget);
    expect(find.text('Not Answered'), findsWidgets);
    expect(find.text('Answered'), findsWidgets);
    expect(find.text('Marked for Review'), findsOneWidget);
    expect(find.text('Answered & Marked'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Question 1, not answered, marked for review'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Question 2, not answered'), findsOneWidget);

    await tester.tap(find.byKey(const Key('palette-2')));
    await tester.pumpAndSettle();
    expect(session.value.currentIndex, 1);
    expect(find.text('Second question'), findsOneWidget);
  });

  testWidgets('Exam Mode Save & Next then Previous restores the answer', (
    tester,
  ) async {
    final session = ValueNotifier(_session(FeedbackTiming.onSubmit));
    addTearDown(session.dispose);
    await _pump(tester, session);

    await tester.tap(find.byKey(const Key('option-B')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('player-save-next')));
    await tester.pump();
    expect(session.value.currentIndex, 1);

    await tester.tap(find.byKey(const Key('player-previous')));
    await tester.pump();
    expect(session.value.currentIndex, 0);
    expect(session.value.currentAnswer.selectedOption, QuestionOption.b);
    expect(find.text('Correct'), findsNothing);
    expect(find.text(_explanation), findsNothing);
  });
}

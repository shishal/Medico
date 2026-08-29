import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/player_session_state.dart';
import '../../domain/question_option.dart';
import 'option_list.dart';
import 'player_action_bar.dart';
import 'question_palette.dart';
import 'tutor_feedback_panel.dart';

/// Shared question player. Tutor vs Exam is a state branch, not a second screen.
class TestPlayerView extends StatelessWidget {
  const TestPlayerView({
    super.key,
    required this.session,
    required this.onSelectOption,
    required this.onGoTo,
    required this.onClear,
    required this.onToggleMark,
    required this.onMarkAndNext,
    required this.onSaveAndNext,
    required this.onFinish,
    required this.onExit,
  });

  final PlayerSessionState session;
  final ValueChanged<QuestionOption> onSelectOption;
  final ValueChanged<int> onGoTo;
  final VoidCallback onClear;
  final VoidCallback onToggleMark;
  final VoidCallback onMarkAndNext;
  final VoidCallback onSaveAndNext;
  final VoidCallback onFinish;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final question = session.currentQuestion;
    final reveal = session.feedbackReveal;
    final finishLabel = session.isTutorMode ? 'Finish session' : 'Submit test';

    return Scaffold(
      appBar: AppBar(
        title: Text(session.title),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: onExit),
        actions: [
          IconButton(
            tooltip: session.currentAnswer.markedForReview
                ? 'Unmark for review'
                : 'Mark for review',
            onPressed: onToggleMark,
            icon: Icon(
              session.currentAnswer.markedForReview
                  ? Icons.flag
                  : Icons.flag_outlined,
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              Spacing.sm,
              Spacing.md,
              0,
            ),
            child: Text(
              'Question ${session.currentIndex + 1} of ${session.questions.length}'
              '${session.isTutorMode ? ' · Tutor Mode' : ''}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          QuestionPalette(
            cells: [
              for (var i = 0; i < session.questions.length; i++)
                session.paletteAt(i),
            ],
            currentIndex: session.currentIndex,
            onSelect: onGoTo,
          ),
          const SizedBox(height: Spacing.md),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              children: [
                Text(
                  question.questionText,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: Spacing.md),
                OptionList(session: session, onSelect: onSelectOption),
                if (reveal != null) ...[
                  const SizedBox(height: Spacing.md),
                  TutorFeedbackPanel(reveal: reveal),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            child: FilledButton(
              style: session.isTutorMode
                  ? null
                  : FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).urgentAccent,
                      foregroundColor: Colors.white,
                    ),
              onPressed: onFinish,
              child: Text(finishLabel),
            ),
          ),
          PlayerActionBar(
            session: session,
            onClear: onClear,
            onMarkAndNext: onMarkAndNext,
            onSaveAndNext: onSaveAndNext,
          ),
        ],
      ),
    );
  }
}

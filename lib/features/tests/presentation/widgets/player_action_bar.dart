import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../domain/player_session_state.dart';

class PlayerActionBar extends StatelessWidget {
  const PlayerActionBar({
    super.key,
    required this.session,
    required this.onClear,
    required this.onMarkAndNext,
    required this.onPrevious,
    required this.onSaveAndNext,
  });

  final PlayerSessionState session;
  final VoidCallback onClear;
  final VoidCallback onMarkAndNext;
  final VoidCallback onPrevious;
  final VoidCallback onSaveAndNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.sm,
        Spacing.md,
        Spacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('player-clear'),
                  onPressed: session.isCurrentAnswerLocked ? null : onClear,
                  child: const Text('Clear Response'),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: OutlinedButton(
                  key: const Key('player-mark-next'),
                  onPressed: onMarkAndNext,
                  child: const Text(
                    'Mark for Review & Next',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('player-previous'),
                  onPressed: session.isFirstQuestion ? null : onPrevious,
                  child: const Text('Previous'),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: FilledButton(
                  key: const Key('player-save-next'),
                  onPressed: session.isLastQuestion ? null : onSaveAndNext,
                  child: const Text('Save & Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

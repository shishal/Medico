import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../domain/player_session_state.dart';

class PlayerActionBar extends StatelessWidget {
  const PlayerActionBar({
    super.key,
    required this.session,
    required this.onClear,
    required this.onMarkAndNext,
    required this.onSaveAndNext,
  });

  final PlayerSessionState session;
  final VoidCallback onClear;
  final VoidCallback onMarkAndNext;
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
                  onPressed: session.isCurrentAnswerLocked ? null : onClear,
                  child: const Text('Clear Response'),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: OutlinedButton(
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
          FilledButton(
            onPressed: session.isLastQuestion ? null : onSaveAndNext,
            child: const Text('Save & Next'),
          ),
        ],
      ),
    );
  }
}

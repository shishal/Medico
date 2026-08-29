import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../profile/domain/plan_tier.dart';
import '../providers/player_session_provider.dart';
import '../widgets/test_player_view.dart';

/// Question player for catalog tests and practice sessions.
///
/// Behavior branches on `tests.feedback_timing` inside [PlayerSessionState]:
/// Tutor Mode reveals + locks; Exam Mode does not. Same widget either way.
class TestPlayerScreen extends ConsumerWidget {
  const TestPlayerScreen({super.key, required this.testId});

  final String testId;

  static const _planLockedMessage =
      'This test is not available on your current plan.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(playerSessionProvider(testId));

    return sessionAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) {
        final message = error.toString().replaceFirst('Exception: ', '');
        return Scaffold(
          appBar: AppBar(title: const Text('Test')),
          body: _ErrorBody(
            message: message,
            planLocked: message == _planLockedMessage,
            onRetry: () => ref.invalidate(playerSessionProvider(testId)),
            onUpgrade: () => context.go(AppRoutes.upgradePath(PlanTier.pro)),
            onBack: () => _exit(context, isPractice: false),
          ),
        );
      },
      data: (session) => TestPlayerView(
        session: session,
        onSelectOption: (option) => ref
            .read(playerSessionProvider(testId).notifier)
            .selectOption(option),
        onGoTo: (index) =>
            ref.read(playerSessionProvider(testId).notifier).goTo(index),
        onClear: () =>
            ref.read(playerSessionProvider(testId).notifier).clearResponse(),
        onToggleMark: () =>
            ref.read(playerSessionProvider(testId).notifier).toggleMark(),
        onMarkAndNext: () => ref
            .read(playerSessionProvider(testId).notifier)
            .markForReviewAndNext(),
        onSaveAndNext: () =>
            ref.read(playerSessionProvider(testId).notifier).saveAndNext(),
        onFinish: () {
          ref.invalidate(playerSessionProvider(testId));
          context.go(
            AppRoutes.resultsPath(
              'local-$testId',
              testId: testId,
              isPractice: session.isEphemeralPractice,
            ),
          );
        },
        onExit: () => _exit(context, isPractice: session.isEphemeralPractice),
      ),
    );
  }

  void _exit(BuildContext context, {required bool isPractice}) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(isPractice ? AppRoutes.home : AppRoutes.testDetailPath(testId));
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.planLocked,
    required this.onRetry,
    required this.onUpgrade,
    required this.onBack,
  });

  final String message;
  final bool planLocked;
  final VoidCallback onRetry;
  final VoidCallback onUpgrade;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: Spacing.md),
            if (planLocked)
              FilledButton(
                onPressed: onUpgrade,
                child: const Text('View upgrade options'),
              )
            else
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            TextButton(onPressed: onBack, child: const Text('Back')),
          ],
        ),
      ),
    );
  }
}

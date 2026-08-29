import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../profile/domain/plan_tier.dart';
import '../../domain/player_session_state.dart';
import '../providers/player_session_provider.dart';
import '../widgets/test_player_view.dart';

/// Question player for catalog tests and practice sessions.
///
/// Behavior branches on `tests.feedback_timing` inside [PlayerSessionState]:
/// Tutor Mode reveals + locks; Exam Mode does not. Same widget either way.
class TestPlayerScreen extends ConsumerStatefulWidget {
  const TestPlayerScreen({super.key, required this.testId});

  final String testId;

  static const _planLockedMessage =
      'This test is not available on your current plan.';

  @override
  ConsumerState<TestPlayerScreen> createState() => _TestPlayerScreenState();
}

class _TestPlayerScreenState extends ConsumerState<TestPlayerScreen>
    with WidgetsBindingObserver {
  bool _didNavigateToResults = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void deactivate() {
    _flush();
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(playerSessionProvider(widget.testId).notifier).onAppResumed();
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _flush();
    }
  }

  void _flush() {
    ref.read(playerSessionProvider(widget.testId).notifier).flushSave();
  }

  void _goToResults(PlayerSessionState session) {
    if (_didNavigateToResults || !mounted) return;
    _didNavigateToResults = true;
    ref.invalidate(playerSessionProvider(widget.testId));
    context.go(
      AppRoutes.resultsPath(
        session.attemptId,
        testId: widget.testId,
        isPractice: session.isEphemeralPractice,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final testId = widget.testId;
    final sessionAsync = ref.watch(playerSessionProvider(testId));

    ref.listen(playerSessionProvider(testId), (previous, next) {
      final session = next.asData?.value;
      if (session == null) return;
      if (session.isSubmitComplete) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _goToResults(session);
        });
        return;
      }
      if (session.isPendingSubmit) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(playerSessionProvider(testId).notifier).ensureSubmitting();
        });
      }
    });

    return sessionAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) {
        final message = error.toString().replaceFirst('Exception: ', '');
        return Scaffold(
          appBar: AppBar(title: const Text('Test')),
          body: _ErrorBody(
            message: message,
            planLocked: message == TestPlayerScreen._planLockedMessage,
            onRetry: () => ref.invalidate(playerSessionProvider(testId)),
            onUpgrade: () => context.go(AppRoutes.upgradePath(PlanTier.pro)),
            onBack: () => _exit(context, isPractice: false),
          ),
        );
      },
      data: (session) {
        if (session.isSubmitComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _goToResults(session);
          });
          return const _SubmittingBody();
        }

        if (session.isPendingSubmit) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(playerSessionProvider(testId).notifier).ensureSubmitting();
          });
          return _SubmittingBody(errorMessage: session.submitError);
        }

        return TestPlayerView(
          session: session,
          now: () => ref.read(playerSessionProvider(testId).notifier).now(),
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
          onPrevious: () =>
              ref.read(playerSessionProvider(testId).notifier).previous(),
          onSaveAndNext: () =>
              ref.read(playerSessionProvider(testId).notifier).saveAndNext(),
          onSubmitSection: () =>
              ref.read(playerSessionProvider(testId).notifier).submitSection(),
          onFinish: () => ref
              .read(playerSessionProvider(testId).notifier)
              .finishAndSubmit(),
          onExit: () => _exit(context, isPractice: session.isEphemeralPractice),
        );
      },
    );
  }

  void _exit(BuildContext context, {required bool isPractice}) {
    _flush();
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(
      isPractice ? AppRoutes.home : AppRoutes.testDetailPath(widget.testId),
    );
  }
}

class _SubmittingBody extends StatelessWidget {
  const _SubmittingBody({this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: Spacing.md),
              const Text('Submitting…'),
              if (errorMessage != null) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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

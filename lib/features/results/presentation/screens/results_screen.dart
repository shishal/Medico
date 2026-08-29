import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/result.dart';
import '../../../practice/data/practice_repository.dart';

/// Placeholder results screen — real scoring arrives in Phase 6.
class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({
    super.key,
    required this.attemptId,
    this.testId,
    this.isPractice = false,
  });

  final String attemptId;
  final String? testId;
  final bool isPractice;

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  bool _similarBusy = false;

  Future<void> _practiceSimilarAgain() async {
    final testId = widget.testId;
    if (testId == null) return;

    setState(() => _similarBusy = true);

    final result =
        await ref.read(practiceRepositoryProvider).fetchSimilarDraft(testId);

    if (!mounted) return;
    setState(() => _similarBusy = false);

    switch (result) {
      case Success(:final value):
        if (value == null) {
          _showMessage('Could not restore those filters.');
          return;
        }
        context.go(AppRoutes.practice, extra: value);
      case Failure(:final message):
        _showMessage(message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Results (placeholder)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: Spacing.md),
            Text('Attempt: ${widget.attemptId}'),
            const SizedBox(height: Spacing.lg),
            if (widget.isPractice && widget.testId != null) ...[
              FilledButton.tonal(
                onPressed: _similarBusy ? null : _practiceSimilarAgain,
                child: _similarBusy
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                      )
                    : const Text('Practice Similar Again'),
              ),
              const SizedBox(height: Spacing.md),
            ],
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Back to home'),
            ),
          ],
        ),
      ),
    );
  }
}

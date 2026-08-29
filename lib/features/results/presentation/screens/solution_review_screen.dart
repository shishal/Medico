import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../bookmarks/presentation/widgets/bookmark_icon_button.dart';
import '../providers/attempt_review_provider.dart';
import '../widgets/review_nav_bar.dart';
import '../widgets/review_question_view.dart';

/// Per-question solutions after submit. Explanation visibility follows
/// `tests.show_explanation_level`; missing `questions` rows are plan-locked.
class SolutionReviewScreen extends ConsumerStatefulWidget {
  const SolutionReviewScreen({super.key, required this.attemptId});

  final String attemptId;

  @override
  ConsumerState<SolutionReviewScreen> createState() =>
      _SolutionReviewScreenState();
}

class _SolutionReviewScreenState extends ConsumerState<SolutionReviewScreen> {
  int _index = 0;

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.resultsPath(widget.attemptId));
  }

  @override
  Widget build(BuildContext context) {
    final reviewAsync = ref.watch(attemptReviewProvider(widget.attemptId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solutions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        actions: [
          ...reviewAsync.maybeWhen(
            data: (review) {
              if (review.items.isEmpty) return const <Widget>[];
              final index = _index.clamp(0, review.items.length - 1);
              return [
                BookmarkIconButton(questionId: review.items[index].questionId),
              ];
            },
            orElse: () => const <Widget>[],
          ),
        ],
      ),
      body: reviewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          final message = error.toString().replaceFirst('Exception: ', '');
          return _ErrorBody(
            message: message,
            onRetry: () =>
                ref.invalidate(attemptReviewProvider(widget.attemptId)),
            onBack: _goBack,
          );
        },
        data: (review) {
          if (review.items.isEmpty) {
            return const Center(child: Text('No questions to review.'));
          }
          final last = review.items.length - 1;
          final index = _index.clamp(0, last);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: Spacing.sm),
                child: ReviewPaletteBar(
                  items: review.items,
                  currentIndex: index,
                  onSelect: (i) => setState(() => _index = i),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Expanded(child: ReviewQuestionView(item: review.items[index])),
              ReviewNavBar(
                currentIndex: index,
                total: review.items.length,
                onPrevious: index > 0
                    ? () => setState(() => _index = index - 1)
                    : null,
                onNext: index < last
                    ? () => setState(() => _index = index + 1)
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
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
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
            TextButton(onPressed: onBack, child: const Text('Back')),
          ],
        ),
      ),
    );
  }
}

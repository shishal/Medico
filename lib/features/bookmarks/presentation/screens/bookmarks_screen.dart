import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../practice/domain/practice_builder_draft.dart';
import '../../../practice/domain/practice_enums.dart';
import '../../domain/bookmarked_question.dart';
import '../providers/bookmarks_provider.dart';
import '../widgets/bookmark_icon_button.dart';

/// Saved questions for later practice. Data lives in Supabase `bookmarks`.
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(bookmarksListProvider);
    final ids = ref.watch(bookmarkedIdsProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookmarks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go(AppRoutes.home);
          },
        ),
      ),
      body: listAsync.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          final message = error.toString().replaceFirst('Exception: ', '');
          return _MessageBody(
            message: message,
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(bookmarksListProvider),
          );
        },
        data: (items) {
          // Hide rows the ID set already dropped (optimistic unbookmark).
          final visible = ids == null
              ? items
              : items.where((item) => ids.contains(item.questionId)).toList();

          if (visible.isEmpty) {
            return const _MessageBody(
              message:
                  'No bookmarks yet. Bookmark a question from solution review '
                  'to practice it later.',
            );
          }

          final unlocked = visible.where((item) => !item.isPlanLocked).length;

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return _BookmarkTile(item: visible[index]);
                  },
                ),
              ),
              if (unlocked > 0)
                _PracticeBar(
                  count: unlocked,
                  onPractice: () => context.go(
                    AppRoutes.practice,
                    extra: PracticeBuilderDraft(
                      sourceFilter: QuestionSourceFilter.bookmarked,
                      questionCount: unlocked,
                      timerMinutes: unlocked,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({required this.item});

  final BookmarkedQuestion item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle = item.subtitle;

    return ListTile(
      leading: Icon(
        item.isPlanLocked ? Icons.lock_outline : Icons.quiz_outlined,
        color: item.isPlanLocked ? colorScheme.outline : colorScheme.primary,
      ),
      title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null
          ? (item.isPlanLocked
                ? Text(
                    'Upgrade to see this question.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  )
                : null)
          : Text(subtitle),
      trailing: BookmarkIconButton(questionId: item.questionId),
    );
  }
}

class _PracticeBar extends StatelessWidget {
  const _PracticeBar({required this.count, required this.onPractice});

  final int count;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.md,
          Spacing.sm,
          Spacing.md,
          Spacing.md,
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onPractice,
            child: Text(
              count == 1
                  ? 'Practice 1 bookmarked question'
                  : 'Practice $count bookmarked questions',
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: Spacing.md),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

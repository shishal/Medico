import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/comic_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/async_status_views.dart';
import '../../../../core/widgets/comic_card.dart';
import '../../../practice/domain/practice_builder_draft.dart';
import '../../../practice/domain/practice_enums.dart';
import '../../data/bookmarks_repository.dart';
import '../../domain/bookmarked_lesson.dart';
import '../../domain/bookmarked_question.dart';
import '../providers/bookmarks_provider.dart';
import '../widgets/bookmark_icon_button.dart';
import '../widgets/lesson_bookmark_icon_button.dart';

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
        loading: () => const AsyncLoadingView(),
        error: (error, _) => AsyncErrorView(
          message: UserFacingError.display(error),
          onAction: () => ref.invalidate(bookmarksListProvider),
        ),
        data: (items) {
          // Hide rows the ID set already dropped (optimistic unbookmark).
          final visible = ids == null
              ? items
              : items.where((item) => ids.contains(item.questionId)).toList();

          if (visible.isEmpty) {
            return Column(
              children: [
                const Expanded(
                  child: AsyncEmptyView(
                    icon: Icons.bookmark_border,
                    message:
                        'No question bookmarks yet. Bookmark a PYQ or a '
                        'question from solution review.',
                  ),
                ),
                const _LessonBookmarks(),
              ],
            );
          }

          final unlocked = visible.where((item) => !item.isPlanLocked).length;

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(Spacing.md),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: Spacing.sm),
                  itemBuilder: (context, index) {
                    return _BookmarkTile(item: visible[index], index: index);
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
              const _LessonBookmarks(),
            ],
          );
        },
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({required this.item, required this.index});

  final BookmarkedQuestion item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final comic = ComicColors.of(context);
    final subtitle = item.subtitle;
    final tint = StickerFills.tintAt(index, Theme.of(context).brightness);

    return ComicCard(
      color: Color.alphaBlend(tint.withValues(alpha: 0.35), comic.sticker),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
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
      ),
    );
  }
}

class _LessonBookmarks extends ConsumerStatefulWidget {
  const _LessonBookmarks();

  @override
  ConsumerState<_LessonBookmarks> createState() => _LessonBookmarksState();
}

class _LessonBookmarksState extends ConsumerState<_LessonBookmarks> {
  List<BookmarkedLesson> _items = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    try {
      final result = await ref.read(bookmarksRepositoryProvider).fetchLessons();
      if (!mounted) return;
      if (result case Success(:final value)) {
        setState(() {
          _items = value;
          _loaded = true;
        });
      } else {
        setState(() => _loaded = true);
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _items.isEmpty) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              Spacing.md,
              Spacing.md,
              0,
            ),
            child: Text(
              'Lessons',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          for (final item in _items)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                Spacing.sm,
                Spacing.md,
                0,
              ),
              child: ComicCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm,
                  vertical: Spacing.xs,
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.article_outlined),
                  title: Text(item.name),
                  trailing: LessonBookmarkIconButton(lessonId: item.lessonId),
                  onTap: () => context.push(
                    AppRoutes.lessonPath(item.lessonId, item.name),
                  ),
                ),
              ),
            ),
        ],
      ),
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

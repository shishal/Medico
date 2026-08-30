import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/async_status_views.dart';
import '../../../../core/widgets/comic_card.dart';
import '../../../bookmarks/presentation/widgets/lesson_bookmark_icon_button.dart';
import '../../../practice/data/practice_repository.dart';
import '../../../practice/domain/practice_builder_draft.dart';
import '../../../practice/domain/practice_enums.dart';
import '../../../profile/domain/plan_tier.dart';
import '../../../profile/presentation/providers/current_plan_provider.dart';
import '../../../progress/presentation/providers/ug_home_providers.dart';
import '../../../pyq/data/pyq_repository.dart';
import '../../../pyq/domain/pyq_models.dart';
import '../../../pyq/presentation/providers/pyq_providers.dart';
import '../../data/catalog_repository.dart';
import '../providers/catalog_providers.dart';
import '../widgets/catalog_row_card.dart';

class SubjectListScreen extends ConsumerWidget {
  const SubjectListScreen({
    super.key,
    required this.subjectId,
    required this.title,
  });

  final String subjectId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(subjectTopicsProvider(subjectId));
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: topics.when(
        loading: () => const AsyncLoadingView(),
        error: (e, _) => AsyncErrorView(
          message: UserFacingError.display(e),
          onAction: () => ref.invalidate(subjectTopicsProvider(subjectId)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AsyncEmptyView(
              message: 'No topics in this subject yet.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(Spacing.md),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
            itemBuilder: (context, i) {
              final topic = items[i];
              return CatalogRowCard(
                title: topic.name,
                index: i,
                onTap: () =>
                    context.push(AppRoutes.topicPath(topic.id, topic.name)),
              );
            },
          );
        },
      ),
    );
  }
}

class TopicLessonsScreen extends ConsumerWidget {
  const TopicLessonsScreen({
    super.key,
    required this.topicId,
    required this.title,
  });

  final String topicId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(topicLessonsProvider(topicId));
    final plan = ref.watch(currentPlanProvider).value ?? PlanTier.free;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: lessons.when(
        loading: () => const AsyncLoadingView(),
        error: (e, _) => AsyncErrorView(
          message: UserFacingError.display(e),
          onAction: () => ref.invalidate(topicLessonsProvider(topicId)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AsyncEmptyView(
              message: 'No lessons in this topic yet.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(Spacing.md),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
            itemBuilder: (context, i) {
              final lesson = items[i];
              final locked = !plan.covers(lesson.requiredPlan);
              return CatalogRowCard(
                title: lesson.name,
                index: i,
                trailing: Icon(
                  locked ? Icons.lock_outline : Icons.chevron_right_rounded,
                ),
                onTap: () {
                  if (locked) {
                    context.push(AppRoutes.upgradePath(lesson.requiredPlan));
                    return;
                  }
                  context.push(AppRoutes.lessonPath(lesson.id, lesson.name));
                },
              );
            },
          );
        },
      ),
    );
  }
}

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.lessonId, required this.title});

  final String lessonId;
  final String title;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  List<ResourceLink> _resources = const [];
  bool _recordedOpen = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadExtras);
  }

  Future<void> _loadExtras() async {
    final resources = await ref
        .read(pyqRepositoryProvider)
        .fetchLessonResources(widget.lessonId);
    if (!mounted) return;
    if (resources case Success(:final value)) {
      setState(() => _resources = value);
    }
    if (!_recordedOpen) {
      _recordedOpen = true;
      await ref
          .read(catalogRepositoryProvider)
          .recordOpenedLesson(widget.lessonId);
    }
  }

  Future<void> _openLink(ResourceLink link, PlanTier plan) async {
    if (!link.isFree && plan.rank < PlanTier.pro.rank) {
      if (!mounted) return;
      context.push(AppRoutes.upgradePath(PlanTier.pro));
      return;
    }
    final uri = Uri.tryParse(link.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final pyqs = ref.watch(lessonPyqsProvider(widget.lessonId));
    final lessonAsync = ref.watch(lessonDetailProvider(widget.lessonId));
    final plan = ref.watch(currentPlanProvider).value ?? PlanTier.free;
    final lesson = lessonAsync.value;
    if (lesson != null && !plan.covers(lesson.requiredPlan)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(AppRoutes.upgradePath(lesson.requiredPlan));
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [LessonBookmarkIconButton(lessonId: widget.lessonId)],
      ),
      body: pyqs.when(
        loading: () => const AsyncLoadingView(),
        error: (e, _) => AsyncErrorView(
          message: UserFacingError.display(e),
          onAction: () => ref.invalidate(lessonPyqsProvider(widget.lessonId)),
        ),
        data: (items) {
          return ListView(
            padding: const EdgeInsets.all(Spacing.md),
            children: [
              FilledButton(
                onPressed: () async {
                  final catalog = await ref
                      .read(practiceRepositoryProvider)
                      .fetchCatalog();
                  if (!context.mounted) return;
                  switch (catalog) {
                    case Failure(:final message):
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(message)));
                    case Success(:final value):
                      final created = await ref
                          .read(practiceRepositoryProvider)
                          .createSession(
                            draft: PracticeBuilderDraft(
                              questionCount: 10,
                              sourceFilter: QuestionSourceFilter.all,
                              feedbackTiming: FeedbackTiming.immediate,
                              lessonIds: {widget.lessonId},
                            ),
                            catalog: value,
                          );
                      if (!context.mounted) return;
                      switch (created) {
                        case Success(:final value):
                          context.go(AppRoutes.testPlayerPath(value.testId));
                        case Failure(:final message):
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(message)));
                      }
                  }
                },
                child: const Text('Practice MCQs'),
              ),
              const SizedBox(height: Spacing.md),
              FilledButton.tonal(
                onPressed: () async {
                  final result = await ref
                      .read(catalogRepositoryProvider)
                      .markLessonLearnt(widget.lessonId);
                  if (!context.mounted) return;
                  final message = switch (result) {
                    Success() => 'Marked as learnt',
                    Failure(:final message) => message,
                  };
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(message)));
                  ref.invalidate(trackerListProvider);
                },
                child: const Text('Mark lesson learnt'),
              ),
              if (_resources.isNotEmpty) ...[
                const SizedBox(height: Spacing.lg),
                Text(
                  'More on this topic',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final link in _resources)
                  Padding(
                    padding: const EdgeInsets.only(top: Spacing.sm),
                    child: ComicCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm,
                        vertical: Spacing.xs,
                      ),
                      onTap: () => _openLink(link, plan),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          link.isFree ? Icons.open_in_new : Icons.lock_outline,
                        ),
                        title: Text(link.title),
                        subtitle: link.sourceLabel == null
                            ? null
                            : Text(link.sourceLabel!),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: Spacing.lg),
              Text(
                'Previous year questions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: Spacing.sm),
              if (items.isEmpty)
                const Text('No PYQs tagged to this lesson yet.')
              else
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: CatalogRowCard(
                      title: items[i].questionText,
                      index: i,
                      subtitle: [
                        if (items[i].marks != null) '${items[i].marks} marks',
                        if (items[i].appearanceCount > 0)
                          '${items[i].appearanceCount}× in papers',
                      ].join(' · '),
                      onTap: () => context.push(AppRoutes.pyqPath(items[i].id)),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

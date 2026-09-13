import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/result.dart';
import '../../../profile/domain/plan_tier.dart';
import '../../../profile/presentation/providers/current_plan_provider.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../data/pyq_repository.dart';
import '../../domain/pyq_models.dart';
import '../../domain/subject_pyq_filters.dart';
import '../../../practice/domain/practice_enums.dart';

part 'pyq_providers.g.dart';

@riverpod
Future<PyqLessonFeed> lessonPyqs(Ref ref, String lessonId) async {
  final profile = await ref.watch(userProfileProvider.future);
  final result = await ref
      .watch(pyqRepositoryProvider)
      .fetchTeasersForLesson(
        lessonId: lessonId,
        universityId: profile?.universityId,
      );
  return switch (result) {
    Success(:final value) => value,
    Failure(:final message) => throw Exception(message),
  };
}

/// Kept alive so leaving the subject and coming back does not re-show
/// the loading spinner while the feed is fetched again.
@Riverpod(keepAlive: true)
Future<PyqSubjectFeed> subjectPyqs(Ref ref, String subjectId) async {
  final profile = await ref.watch(userProfileProvider.future);
  final result = await ref
      .watch(pyqRepositoryProvider)
      .fetchTeasersForSubject(
        subjectId: subjectId,
        universityId: profile?.universityId,
      );
  return switch (result) {
    Success(:final value) => value,
    Failure(:final message) => throw Exception(message),
  };
}

/// Chapter / paper filters for one subject's year list and paper outline.
@Riverpod(keepAlive: true)
class SubjectPyqFilters extends _$SubjectPyqFilters {
  @override
  SubjectPyqFilter build(String subjectId) => const SubjectPyqFilter();

  void setPaperName(String? paperName) {
    state = SubjectPyqFilter(
      paperName: paperName,
      topicId: state.topicId,
      priorities: state.priorities,
    );
  }

  void setTopicId(String? topicId) {
    state = SubjectPyqFilter(
      paperName: state.paperName,
      topicId: topicId,
      priorities: state.priorities,
    );
  }

  void togglePriority(QuestionDifficulty value) {
    final next = {...state.priorities};
    if (!next.add(value)) next.remove(value);
    state = SubjectPyqFilter(
      paperName: state.paperName,
      topicId: state.topicId,
      priorities: next,
    );
  }

  void clear() {
    state = const SubjectPyqFilter();
  }
}

@riverpod
Future<PyqDetail> pyqDetail(Ref ref, String questionId) async {
  final plan = ref.watch(currentPlanProvider).value ?? PlanTier.free;
  final result = await ref
      .watch(pyqRepositoryProvider)
      .fetchDetail(questionId: questionId, plan: plan);
  return switch (result) {
    Success(:final value) => value,
    Failure(:final message) => throw Exception(message),
  };
}

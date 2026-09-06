import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/result.dart';
import '../../../profile/domain/plan_tier.dart';
import '../../../profile/presentation/providers/current_plan_provider.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../data/pyq_repository.dart';
import '../../domain/pyq_models.dart';

part 'pyq_providers.g.dart';

@riverpod
Future<PyqLessonFeed> lessonPyqs(Ref ref, String lessonId) async {
  final profile = await ref.watch(userProfileProvider.future);
  final result = await ref.watch(pyqRepositoryProvider).fetchTeasersForLesson(
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
  final result = await ref.watch(pyqRepositoryProvider).fetchTeasersForSubject(
        subjectId: subjectId,
        universityId: profile?.universityId,
      );
  return switch (result) {
    Success(:final value) => value,
    Failure(:final message) => throw Exception(message),
  };
}

@riverpod
Future<PyqDetail> pyqDetail(Ref ref, String questionId) async {
  final plan = ref.watch(currentPlanProvider).value ?? PlanTier.free;
  final result = await ref.watch(pyqRepositoryProvider).fetchDetail(
        questionId: questionId,
        plan: plan,
      );
  return switch (result) {
    Success(:final value) => value,
    Failure(:final message) => throw Exception(message),
  };
}

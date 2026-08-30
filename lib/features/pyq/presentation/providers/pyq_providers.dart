import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/result.dart';
import '../../../profile/domain/plan_tier.dart';
import '../../../profile/presentation/providers/current_plan_provider.dart';
import '../../data/pyq_repository.dart';
import '../../domain/pyq_models.dart';

part 'pyq_providers.g.dart';

@riverpod
Future<List<PyqTeaser>> lessonPyqs(Ref ref, String lessonId) async {
  final result = await ref.watch(pyqRepositoryProvider).fetchTeasersForLesson(lessonId);
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

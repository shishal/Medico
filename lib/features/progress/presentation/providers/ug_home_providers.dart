import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/result.dart';
import '../../../progress/data/progress_repository.dart';
import '../../../progress/domain/progress_models.dart';

part 'ug_home_providers.g.dart';

@riverpod
Future<StudyProgress> studyProgress(Ref ref) async {
  final result = await ref.watch(progressRepositoryProvider).fetchProgress();
  return switch (result) {
    Success(:final value) => value,
    Failure(:final message) => throw Exception(message),
  };
}

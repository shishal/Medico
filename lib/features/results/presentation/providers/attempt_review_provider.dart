import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/result.dart';
import '../../data/results_repository.dart';
import '../../domain/attempt_review.dart';

part 'attempt_review_provider.g.dart';

/// Per-question solutions for a submitted attempt.
@riverpod
Future<AttemptReview> attemptReview(Ref ref, String attemptId) async {
  final result = await ref
      .read(resultsRepositoryProvider)
      .fetchAttemptReview(attemptId);
  return switch (result) {
    Success(:final value) => value,
    Failure(:final message) => throw Exception(message),
  };
}

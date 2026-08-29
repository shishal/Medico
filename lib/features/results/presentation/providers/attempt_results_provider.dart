import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/result.dart';
import '../../data/results_repository.dart';
import '../../domain/attempt_results.dart';

part 'attempt_results_provider.g.dart';

/// Submitted-attempt summary for the results screen.
@riverpod
Future<AttemptResults> attemptResults(Ref ref, String attemptId) async {
  final result = await ref
      .read(resultsRepositoryProvider)
      .fetchAttemptResults(attemptId);
  return switch (result) {
    Success(:final value) => value,
    Failure(:final message) => throw Exception(message),
  };
}

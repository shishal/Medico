import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/result.dart';
import '../../data/tests_repository.dart';
import '../../domain/test_detail.dart';

part 'test_detail_provider.g.dart';

/// Plan-gated test row for the instructions screen.
///
/// Throws with the repository message on failure (including "not on your plan")
/// so the screen can show a dedicated upgrade path vs a generic retry.
@riverpod
Future<TestDetail> testDetail(Ref ref, String testId) async {
  final result = await ref.read(testsRepositoryProvider).fetchTestDetail(testId);
  return switch (result) {
    Success(:final value) => value,
    Failure(:final message) => throw Exception(message),
  };
}

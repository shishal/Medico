import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../../core/supabase/tables.dart';
import '../../../core/utils/result.dart';
import '../domain/catalog_test.dart';
import '../domain/test_detail.dart';

part 'tests_repository.g.dart';

/// Fetches catalog teasers and plan-gated test details.
/// Presentation never calls Supabase directly.
///
/// List data comes from [Tables.catalogTestTeasers] (all authenticated users
/// see titles for higher plans). Full rows (marking, sections) come from
/// [Tables.tests] and are RLS-gated — empty result means upgrade required.
class TestsRepository {
  TestsRepository(this._client);

  final SupabaseClient _client;

  /// Active catalog teasers (locked + unlocked). Caller applies plan locks in UI.
  Future<Result<List<CatalogTest>>> fetchCatalogTests() async {
    if (_client.auth.currentUser == null) {
      return const Failure('Not signed in.');
    }

    try {
      final rows = await _client
          .from(Tables.catalogTestTeasers)
          .select(
            '${TestColumns.id},'
            '${TestColumns.title},'
            '${TestColumns.testType},'
            '${TestColumns.requiredPlan},'
            '${TestColumns.isSectional},'
            '${TestColumns.totalDurationMinutes},'
            '${TestColumns.totalQuestions}',
          )
          .order(TestColumns.createdAt, ascending: false);

      final tests = (rows as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(CatalogTest.fromJson)
          .toList();

      return Success(tests);
    } on PostgrestException catch (_) {
      return const Failure('Could not load tests. Please try again.');
    } catch (_) {
      return const Failure('Could not load tests. Please try again.');
    }
  }

  /// Instructions payload for one test. RLS returns no row if plan is too low.
  Future<Result<TestDetail>> fetchTestDetail(String testId) async {
    if (_client.auth.currentUser == null) {
      return const Failure('Not signed in.');
    }

    try {
      final rows = await _client
          .from(Tables.tests)
          .select(
            '${TestColumns.id},'
            '${TestColumns.title},'
            '${TestColumns.description},'
            '${TestColumns.testType},'
            '${TestColumns.requiredPlan},'
            '${TestColumns.isSectional},'
            '${TestColumns.sectionCount},'
            '${TestColumns.questionsPerSection},'
            '${TestColumns.sectionDurationMinutes},'
            '${TestColumns.totalDurationMinutes},'
            '${TestColumns.totalQuestions},'
            '${TestColumns.correctMarks},'
            '${TestColumns.incorrectMarks},'
            '${TestColumns.unattemptedMarks}',
          )
          .eq(TestColumns.id, testId)
          .limit(1);

      final list = (rows as List<dynamic>).cast<Map<String, dynamic>>();
      if (list.isEmpty) {
        // Empty under RLS almost always means plan gate — not a network glitch.
        return const Failure(
          'This test is not available on your current plan.',
        );
      }

      return Success(TestDetail.fromJson(list.first));
    } on PostgrestException catch (_) {
      return const Failure('Could not load test details. Please try again.');
    } catch (_) {
      return const Failure('Could not load test details. Please try again.');
    }
  }
}

@Riverpod(keepAlive: true)
TestsRepository testsRepository(Ref ref) {
  return TestsRepository(ref.watch(supabaseClientProvider));
}

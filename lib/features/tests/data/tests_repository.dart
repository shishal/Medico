import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../../core/supabase/tables.dart';
import '../../../core/utils/result.dart';
import '../domain/catalog_test.dart';

part 'tests_repository.g.dart';

/// Fetches catalog tests. Presentation never calls Supabase directly.
///
/// Plan gating is entirely RLS (`tests` select policy) — this repo does not
/// re-filter by plan. Free users simply get fewer rows back.
class TestsRepository {
  TestsRepository(this._client);

  final SupabaseClient _client;

  /// Active catalog tests visible to the signed-in user.
  Future<Result<List<CatalogTest>>> fetchCatalogTests() async {
    if (_client.auth.currentUser == null) {
      return const Failure('Not signed in.');
    }

    try {
      // Explicit column list keeps the payload small and avoids depending on
      // Phase 4B practice columns that may not exist yet.
      final rows = await _client
          .from(Tables.tests)
          .select(
            '${TestColumns.id},'
            '${TestColumns.title},'
            '${TestColumns.description},'
            '${TestColumns.testType},'
            '${TestColumns.requiredPlan},'
            '${TestColumns.isSectional},'
            '${TestColumns.totalDurationMinutes},'
            '${TestColumns.totalQuestions}',
          )
          .eq(TestColumns.isActive, true)
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
}

@Riverpod(keepAlive: true)
TestsRepository testsRepository(Ref ref) {
  return TestsRepository(ref.watch(supabaseClientProvider));
}

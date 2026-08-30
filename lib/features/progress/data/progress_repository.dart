import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../../core/supabase/tables.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/user_facing_error.dart';
import '../domain/progress_models.dart';

part 'progress_repository.g.dart';

class ProgressRepository {
  ProgressRepository(this._client);

  final SupabaseClient _client;

  Future<Result<StudyProgress>> fetchProgress() async {
    if (_client.auth.currentUser == null) {
      return const Failure('Not signed in.');
    }
    try {
      final raw = await _client.rpc(RpcFunctions.getStudyProgress);
      if (raw is! Map) {
        return const Failure('Could not load progress.');
      }
      return Success(StudyProgress.fromJson(Map<String, dynamic>.from(raw)));
    } catch (e) {
      return Failure(
        UserFacingError.from(e, fallback: 'Could not load progress.'),
      );
    }
  }

  Future<Result<SearchHits>> search(String query) async {
    try {
      final raw = await _client.rpc(
        RpcFunctions.searchCatalog,
        params: {SearchCatalogParams.query: query},
      );
      if (raw is! Map) return const Success(SearchHits(subjects: [], lessons: [], questions: []));
      return Success(SearchHits.fromJson(Map<String, dynamic>.from(raw)));
    } catch (e) {
      return Failure(
        UserFacingError.from(e, fallback: 'Search failed.'),
      );
    }
  }
}

@Riverpod(keepAlive: true)
ProgressRepository progressRepository(Ref ref) {
  return ProgressRepository(ref.watch(supabaseClientProvider));
}

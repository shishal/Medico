import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../../core/supabase/tables.dart';
import '../../../core/utils/result.dart';
import '../domain/attempt_results.dart';

part 'results_repository.g.dart';

/// Loads a submitted attempt's summary. Presentation never calls Supabase.
class ResultsRepository {
  ResultsRepository(this._client);

  final SupabaseClient _client;

  Future<Result<AttemptResults>> fetchAttemptResults(String attemptId) async {
    if (_client.auth.currentUser == null) {
      return const Failure('Not signed in.');
    }

    try {
      final raw = await _client.rpc(
        RpcFunctions.getAttemptResults,
        params: {GetAttemptResultsParams.attemptId: attemptId},
      );

      final map = _asJsonMap(raw);
      if (map == null) {
        return const Failure('Could not load results. Please try again.');
      }
      return Success(AttemptResults.fromJson(map));
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (_) {
      return const Failure('Could not load results. Please try again.');
    }
  }

  static Map<String, dynamic>? _asJsonMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  static String _mapError(PostgrestException e) {
    final haystack = '${e.message} ${e.details} ${e.hint}';
    if (haystack.contains('NOT_AUTHENTICATED')) {
      return 'Not signed in.';
    }
    if (haystack.contains('ATTEMPT_NOT_FOUND') ||
        haystack.contains('ATTEMPT_NOT_OWNED')) {
      return 'Those results are not available.';
    }
    if (haystack.contains('ATTEMPT_NOT_SUBMITTED')) {
      return 'This attempt has not been submitted yet.';
    }
    return 'Could not load results. Please try again.';
  }
}

@Riverpod(keepAlive: true)
ResultsRepository resultsRepository(Ref ref) {
  return ResultsRepository(ref.watch(supabaseClientProvider));
}

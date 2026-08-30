import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../../core/supabase/tables.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/user_facing_error.dart';
import '../../progress/domain/progress_models.dart';

part 'trackers_repository.g.dart';

class TrackersRepository {
  TrackersRepository(this._client);

  final SupabaseClient _client;

  Future<Result<List<TrackerSummary>>> fetchAll() async {
    if (_client.auth.currentUser == null) {
      return const Failure('Not signed in.');
    }
    try {
      final rows = await _client
          .from(Tables.trackers)
          .select()
          .eq(TrackerColumns.isActive, true)
          .order(TrackerColumns.createdAt, ascending: false);
      final list = (rows as List<dynamic>).cast<Map<String, dynamic>>();
      final out = <TrackerSummary>[];
      for (final row in list) {
        final id = row[TrackerColumns.id] as String;
        final raw = await _client.rpc(
          RpcFunctions.trackerCompletion,
          params: {TrackerCompletionParams.trackerId: id},
        );
        final completion = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
        out.add(TrackerSummary.fromRow(row, completion));
      }
      return Success(out);
    } catch (e) {
      return Failure(
        UserFacingError.from(e, fallback: 'Could not load trackers.'),
      );
    }
  }

  Future<Result<String>> createCustom({
    required String title,
    required List<String> lessonIds,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Failure('Not signed in.');
    try {
      final row = await _client
          .from(Tables.trackers)
          .insert({
            TrackerColumns.ownerUserId: userId,
            TrackerColumns.kind: 'custom',
            TrackerColumns.title: title,
          })
          .select(TrackerColumns.id)
          .single();
      final trackerId = row[TrackerColumns.id] as String;
      if (lessonIds.isNotEmpty) {
        await _client.from(Tables.trackerItems).insert([
          for (var i = 0; i < lessonIds.length; i++)
            {
              TrackerItemColumns.trackerId: trackerId,
              TrackerItemColumns.lessonId: lessonIds[i],
              TrackerItemColumns.displayOrder: i,
            },
        ]);
      }
      return Success(trackerId);
    } catch (e) {
      return Failure(
        UserFacingError.from(e, fallback: 'Could not create tracker.'),
      );
    }
  }
}

@Riverpod(keepAlive: true)
TrackersRepository trackersRepository(Ref ref) {
  return TrackersRepository(ref.watch(supabaseClientProvider));
}

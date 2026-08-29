import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../../core/supabase/tables.dart';

part 'screenshot_events_repository.g.dart';

/// Best-effort insert of capture attempts. Failures must never interrupt
/// a test — presentation ignores the return.
class ScreenshotEventsRepository {
  ScreenshotEventsRepository(this._client);

  final SupabaseClient _client;

  Future<void> log({required String screen, required String eventType}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client.from(Tables.screenshotEvents).insert({
        ScreenshotEventColumns.userId: userId,
        ScreenshotEventColumns.screen: screen,
        ScreenshotEventColumns.eventType: eventType,
      });
    } catch (_) {
      // Audit only. A missing table or network blip must not crash the player.
    }
  }
}

@Riverpod(keepAlive: true)
ScreenshotEventsRepository screenshotEventsRepository(Ref ref) {
  return ScreenshotEventsRepository(ref.watch(supabaseClientProvider));
}

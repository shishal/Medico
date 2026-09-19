import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/result.dart';
import '../../../auth/presentation/providers/auth_session_provider.dart';
import '../../data/notifications_repository.dart';
import '../../domain/app_announcement.dart';

part 'notifications_provider.g.dart';

/// Active announcements for the signed-in user (newest first).
@Riverpod(keepAlive: true)
class Announcements extends _$Announcements {
  @override
  Future<List<AppAnnouncement>> build() async {
    final isSignedIn = ref.watch(authSessionProvider);
    if (!isSignedIn) return const [];

    final result = await ref.read(notificationsRepositoryProvider).fetchActive();
    return switch (result) {
      Success(:final value) => value,
      Failure(:final message) => throw Exception(message),
    };
  }

  /// Optimistic mark-read, then write through. Reverts if the insert fails.
  Future<Result<void>> markRead(String announcementId) async {
    final current = state.value;
    if (current == null) {
      return const Failure('Notifications not loaded yet.');
    }

    final index = current.indexWhere((a) => a.id == announcementId);
    if (index < 0) return const Success(null);
    if (current[index].isRead) return const Success(null);

    final previous = current;
    final next = [
      for (var i = 0; i < current.length; i++)
        if (i == index) current[i].copyWith(isRead: true) else current[i],
    ];
    state = AsyncData(next);

    final result = await ref
        .read(notificationsRepositoryProvider)
        .markRead(announcementId);

    switch (result) {
      case Success():
        return result;
      case Failure():
        state = AsyncData(previous);
        return result;
    }
  }
}

@riverpod
int unreadAnnouncementCount(Ref ref) {
  final list = ref.watch(announcementsProvider).value;
  if (list == null) return 0;
  return list.where((a) => !a.isRead).length;
}

/// Newest unread item for the Home strip (null when all read / none loaded).
@riverpod
AppAnnouncement? latestUnreadAnnouncement(Ref ref) {
  final list = ref.watch(announcementsProvider).value;
  if (list == null) return null;
  for (final item in list) {
    if (!item.isRead) return item;
  }
  return null;
}

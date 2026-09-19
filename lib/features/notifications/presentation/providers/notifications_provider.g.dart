// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Active announcements for the signed-in user (newest first).

@ProviderFor(Announcements)
final announcementsProvider = AnnouncementsProvider._();

/// Active announcements for the signed-in user (newest first).
final class AnnouncementsProvider
    extends $AsyncNotifierProvider<Announcements, List<AppAnnouncement>> {
  /// Active announcements for the signed-in user (newest first).
  AnnouncementsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'announcementsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$announcementsHash();

  @$internal
  @override
  Announcements create() => Announcements();
}

String _$announcementsHash() => r'c351782b8c81cf958a358258bae3745b459e3a43';

/// Active announcements for the signed-in user (newest first).

abstract class _$Announcements extends $AsyncNotifier<List<AppAnnouncement>> {
  FutureOr<List<AppAnnouncement>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<AppAnnouncement>>, List<AppAnnouncement>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<AppAnnouncement>>,
                List<AppAnnouncement>
              >,
              AsyncValue<List<AppAnnouncement>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(unreadAnnouncementCount)
final unreadAnnouncementCountProvider = UnreadAnnouncementCountProvider._();

final class UnreadAnnouncementCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  UnreadAnnouncementCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadAnnouncementCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadAnnouncementCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return unreadAnnouncementCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$unreadAnnouncementCountHash() =>
    r'4f0331240a0807d170cc8d48c87a6cedab82f1d3';

/// Newest unread item for the Home strip (null when all read / none loaded).

@ProviderFor(latestUnreadAnnouncement)
final latestUnreadAnnouncementProvider = LatestUnreadAnnouncementProvider._();

/// Newest unread item for the Home strip (null when all read / none loaded).

final class LatestUnreadAnnouncementProvider
    extends
        $FunctionalProvider<
          AppAnnouncement?,
          AppAnnouncement?,
          AppAnnouncement?
        >
    with $Provider<AppAnnouncement?> {
  /// Newest unread item for the Home strip (null when all read / none loaded).
  LatestUnreadAnnouncementProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'latestUnreadAnnouncementProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$latestUnreadAnnouncementHash();

  @$internal
  @override
  $ProviderElement<AppAnnouncement?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppAnnouncement? create(Ref ref) {
    return latestUnreadAnnouncement(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppAnnouncement? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppAnnouncement?>(value),
    );
  }
}

String _$latestUnreadAnnouncementHash() =>
    r'304e8e72dc348cb690fb92589a93677d19ccdeff';

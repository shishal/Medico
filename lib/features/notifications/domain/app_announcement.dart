import '../../../core/supabase/tables.dart';

/// One broadcast message from `announcements`, plus whether this user read it.
class AppAnnouncement {
  const AppAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.publishedAt,
    required this.isRead,
    this.deepLink,
    this.expiresAt,
  });

  final String id;
  final String title;
  final String body;

  /// `general` | `version` | `offer` | `payment` (enforced in Postgres).
  final String category;
  final String? deepLink;
  final DateTime publishedAt;
  final DateTime? expiresAt;
  final bool isRead;

  String get categoryLabel => switch (category) {
    'version' => 'Update',
    'offer' => 'Offer',
    'payment' => 'Payment',
    _ => 'News',
  };

  static AppAnnouncement? fromJson(Map<String, dynamic> json) {
    final id = json[AnnouncementColumns.id];
    final title = json[AnnouncementColumns.title];
    final body = json[AnnouncementColumns.body];
    final publishedRaw = json[AnnouncementColumns.publishedAt];
    if (id is! String ||
        title is! String ||
        body is! String ||
        publishedRaw is! String) {
      return null;
    }

    final publishedAt = DateTime.tryParse(publishedRaw);
    if (publishedAt == null) return null;

    final expiresRaw = json[AnnouncementColumns.expiresAt];
    DateTime? expiresAt;
    if (expiresRaw is String) {
      expiresAt = DateTime.tryParse(expiresRaw);
    }

    // RLS on announcement_reads only returns this user's rows, so a non-empty
    // embed means "read".
    final reads = json[AnnouncementColumns.readsEmbed];
    final isRead = reads is List && reads.isNotEmpty;

    return AppAnnouncement(
      id: id,
      title: title,
      body: body,
      category: json[AnnouncementColumns.category] as String? ?? 'general',
      deepLink: json[AnnouncementColumns.deepLink] as String?,
      publishedAt: publishedAt,
      expiresAt: expiresAt,
      isRead: isRead,
    );
  }

  AppAnnouncement copyWith({bool? isRead}) {
    return AppAnnouncement(
      id: id,
      title: title,
      body: body,
      category: category,
      deepLink: deepLink,
      publishedAt: publishedAt,
      expiresAt: expiresAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

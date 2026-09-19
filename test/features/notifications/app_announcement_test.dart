import 'package:flutter_test/flutter_test.dart';
import 'package:medico/core/supabase/tables.dart';
import 'package:medico/features/notifications/domain/app_announcement.dart';

void main() {
  group('AppAnnouncement.fromJson', () {
    test('parses unread row', () {
      final item = AppAnnouncement.fromJson({
        AnnouncementColumns.id: 'a1',
        AnnouncementColumns.title: 'Pro is 20% off',
        AnnouncementColumns.body: 'This week only.',
        AnnouncementColumns.category: 'offer',
        AnnouncementColumns.deepLink: '/upgrade',
        AnnouncementColumns.publishedAt: '2026-09-19T10:00:00Z',
        AnnouncementColumns.expiresAt: null,
        AnnouncementColumns.readsEmbed: <Object>[],
      });

      expect(item, isNotNull);
      expect(item!.id, 'a1');
      expect(item.categoryLabel, 'Offer');
      expect(item.isRead, isFalse);
      expect(item.deepLink, '/upgrade');
    });

    test('marks read when embed has a row', () {
      final item = AppAnnouncement.fromJson({
        AnnouncementColumns.id: 'a2',
        AnnouncementColumns.title: 'v1.2',
        AnnouncementColumns.body: 'Bug fixes.',
        AnnouncementColumns.category: 'version',
        AnnouncementColumns.publishedAt: '2026-09-18T10:00:00Z',
        AnnouncementColumns.readsEmbed: [
          {AnnouncementReadColumns.readAt: '2026-09-19T11:00:00Z'},
        ],
      });

      expect(item, isNotNull);
      expect(item!.isRead, isTrue);
      expect(item.categoryLabel, 'Update');
    });

    test('returns null on bad payload', () {
      expect(AppAnnouncement.fromJson(const {}), isNull);
    });
  });
}

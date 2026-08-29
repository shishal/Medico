import 'package:flutter_test/flutter_test.dart';

import 'package:medico/core/supabase/tables.dart';
import 'package:medico/features/bookmarks/domain/bookmarked_question.dart';

void main() {
  test('parses nested subject and topic from a join row', () {
    final item = BookmarkedQuestion.fromJson({
      BookmarkColumns.questionId: 'q1',
      BookmarkColumns.createdAt: '2026-08-01T10:00:00Z',
      BookmarkColumns.questionEmbed: {
        QuestionColumns.id: 'q1',
        QuestionColumns.questionText: 'Which organelle produces ATP?',
        QuestionColumns.topicEmbed: {
          TopicColumns.name: 'Cell Biology',
          TopicColumns.subjectEmbed: {SubjectColumns.name: 'Anatomy'},
        },
      },
    });

    expect(item, isNotNull);
    expect(item!.questionId, 'q1');
    expect(item.isPlanLocked, isFalse);
    expect(item.title, 'Which organelle produces ATP?');
    expect(item.subtitle, 'Anatomy · Cell Biology');
  });

  test('null question embed is plan-locked, not a crash', () {
    final item = BookmarkedQuestion.fromJson({
      BookmarkColumns.questionId: 'q-locked',
      BookmarkColumns.createdAt: '2026-08-01T10:00:00Z',
      BookmarkColumns.questionEmbed: null,
    });

    expect(item, isNotNull);
    expect(item!.isPlanLocked, isTrue);
    expect(item.title, 'Unavailable on your plan');
    expect(item.subtitle, isNull);
  });

  test('empty embed list is also plan-locked', () {
    final item = BookmarkedQuestion.fromJson({
      BookmarkColumns.questionId: 'q-empty',
      BookmarkColumns.createdAt: '2026-08-01T10:00:00Z',
      BookmarkColumns.questionEmbed: const [],
    });

    expect(item, isNotNull);
    expect(item!.isPlanLocked, isTrue);
  });
}

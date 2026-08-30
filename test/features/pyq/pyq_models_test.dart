import 'package:flutter_test/flutter_test.dart';
import 'package:medico/core/supabase/tables.dart';
import 'package:medico/features/profile/domain/plan_tier.dart';
import 'package:medico/features/pyq/domain/pyq_models.dart';
import 'package:medico/features/progress/domain/progress_models.dart';

void main() {
  test('PyqTeaser parses appearance_count', () {
    final teaser = PyqTeaser.fromJson({
      PyqTeaserColumns.id: 'q1',
      PyqTeaserColumns.lessonId: 'l1',
      PyqTeaserColumns.questionText: 'Describe the brachial plexus.',
      PyqTeaserColumns.marks: 10,
      PyqTeaserColumns.requiredPlan: 'free',
      PyqTeaserColumns.appearanceCount: 3,
    });
    expect(teaser.appearanceCount, 3);
    expect(teaser.requiredPlan, PlanTier.free);
    expect(teaser.marks, 10);
  });

  test('SearchHits maps subjects lessons and PYQ stems', () {
    final hits = SearchHits.fromJson({
      'subjects': [
        {'id': 's1', 'name': 'Anatomy'},
      ],
      'lessons': [
        {'id': 'l1', 'name': 'Brachial plexus', 'required_plan': 'free'},
      ],
      'questions': [
        {
          'id': 'q1',
          'question_text': 'Describe Erb palsy.',
          'lesson_id': 'l1',
        },
      ],
    });
    expect(hits.subjects.single.title, 'Anatomy');
    expect(hits.lessons.single.kind, 'lesson');
    expect(hits.questions.single.title, 'Describe Erb palsy.');
  });

  test('TextbookCitation formats book, edition, and page', () {
    final citation = TextbookCitation.fromJson({
      TextbookRefColumns.page: 48,
      TextbookRefColumns.sectionHeading: 'Brachial plexus',
      TextbookRefColumns.textbookEmbed: {
        TextbookColumns.title: "BD Chaurasia's Human Anatomy Vol 1",
        TextbookColumns.edition: '8th',
      },
    });
    expect(citation.label, contains('p. 48'));
    expect(citation.label, contains('8th'));
    expect(citation.label, contains('Brachial plexus'));
  });

  test('TrackerSummary reads completion RPC payload', () {
    final summary = TrackerSummary.fromRow(
      {
        TrackerColumns.id: 't1',
        TrackerColumns.title: 'Anatomy internal',
        TrackerColumns.kind: 'custom',
      },
      {'done': 2, 'total': 4, 'percent': 50.0},
    );
    expect(summary.percent, 50.0);
    expect(summary.done, 2);
    expect(summary.total, 4);
  });

  test('StudyProgress parses streak JSON from RPC', () {
    final progress = StudyProgress.fromJson({
      'streak': 2,
      'days7': [
        {'date': '2026-08-29', 'count': 1},
        {'date': '2026-08-30', 'count': 3},
      ],
      'days30': <Map<String, dynamic>>[],
      'subjects': [
        {
          'id': 's1',
          'name': 'Anatomy',
          'learnt_lessons': 1,
          'total_lessons': 4,
        },
      ],
    });
    expect(progress.streak, 2);
    expect(progress.days7.last.count, 3);
    expect(progress.subjects.single.totalLessons, 4);
  });
}

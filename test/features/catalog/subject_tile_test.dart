import 'package:flutter_test/flutter_test.dart';
import 'package:medico/features/catalog/presentation/widgets/subject_tile.dart';

void main() {
  test('subjectTileCaption prefers lesson progress when chapters exist', () {
    expect(
      subjectTileCaption(
        showLessonProgress: true,
        learntLessons: 1,
        totalLessons: 4,
        totalPyqs: 12,
      ),
      '1 of 4 lessons learnt',
    );
  });

  test('subjectTileCaption shows PYQ count when there are no lessons', () {
    expect(
      subjectTileCaption(
        showLessonProgress: true,
        learntLessons: 0,
        totalLessons: 0,
        totalPyqs: 1,
      ),
      '1 PYQ',
    );
    expect(
      subjectTileCaption(
        showLessonProgress: true,
        learntLessons: 0,
        totalLessons: 0,
        totalPyqs: 3,
      ),
      '3 PYQs',
    );
  });

  test('subjectTileCaption hides counts when this university has no papers', () {
    expect(
      subjectTileCaption(
        showLessonProgress: false,
        learntLessons: 0,
        totalLessons: 4,
        totalPyqs: 12,
      ),
      'No PYQs yet',
    );
  });
}

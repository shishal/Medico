import 'package:flutter_test/flutter_test.dart';
import 'package:medico/features/catalog/presentation/widgets/subject_tile.dart';

void main() {
  test('subjectTileCaption shows PYQ count even when chapters exist', () {
    expect(
      subjectTileCaption(
        showLessonProgress: true,
        totalPyqs: 12,
      ),
      '12 PYQs',
    );
  });

  test('subjectTileCaption singularizes a single PYQ', () {
    expect(
      subjectTileCaption(
        showLessonProgress: true,
        totalPyqs: 1,
      ),
      '1 PYQ',
    );
  });

  test('subjectTileCaption hides counts when this university has no papers', () {
    expect(
      subjectTileCaption(
        showLessonProgress: false,
        totalPyqs: 12,
      ),
      'No PYQs yet',
    );
  });

  test('subjectTileCaption is empty copy when the subject has no PYQs', () {
    expect(
      subjectTileCaption(
        showLessonProgress: true,
        totalPyqs: 0,
      ),
      'No PYQs yet',
    );
  });
}

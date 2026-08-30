import 'package:flutter_test/flutter_test.dart';

import 'package:medico/core/theme/brand_assets.dart';
import 'package:medico/features/catalog/domain/subject_visual.dart';

void main() {
  test('year art maps 1st / 2nd / 3rd / final', () {
    expect(
      BrandAssets.yearArt(code: 'Y1', name: '1st year', displayOrder: 1),
      BrandAssets.yearFirst,
    );
    expect(
      BrandAssets.yearArt(code: 'Y2', name: '2nd year', displayOrder: 2),
      BrandAssets.yearSecond,
    );
    expect(
      BrandAssets.yearArt(code: 'Y3', name: '3rd year', displayOrder: 3),
      BrandAssets.yearThird,
    );
    expect(
      BrandAssets.yearArt(code: 'Y4', name: 'Final year', displayOrder: 4),
      BrandAssets.yearFinal,
    );
  });

  test('subject names map to medical glyphs', () {
    expect(glyphForSubject('Anatomy'), MedGlyph.skull);
    expect(glyphForSubject('Physiology'), MedGlyph.heart);
    expect(glyphForSubject('Biochemistry'), MedGlyph.flask);
    expect(glyphForSubject('Pathology'), MedGlyph.microscope);
    expect(glyphForSubject('Pharmacology'), MedGlyph.pills);
    expect(glyphForSubject('Microbiology'), MedGlyph.bacteria);
    expect(glyphForSubject('ENT'), MedGlyph.ear);
    expect(glyphForSubject('Ophthalmology'), MedGlyph.eye);
    expect(glyphForSubject('General Surgery'), MedGlyph.scalpel);
    expect(glyphForSubject('General Medicine'), MedGlyph.stethoscope);
    expect(glyphForSubject('Orthopaedics'), MedGlyph.bone);
    expect(glyphForSubject('Psychiatry'), MedGlyph.brain);
    expect(glyphForSubject('Unknown elective'), MedGlyph.book);
  });
}

/// Comic glyph for a KUHS subject. Names are matched loosely so sheet
/// titles like "Gen. Medicine" still get a stethoscope.
enum MedGlyph {
  skull,
  heart,
  flask,
  microscope,
  pills,
  bacteria,
  fingerprint,
  people,
  ear,
  eye,
  stethoscope,
  scalpel,
  baby,
  bone,
  brain,
  book,
}

MedGlyph glyphForSubject(String name) {
  final n = name.toLowerCase();
  if (n.contains('anat')) return MedGlyph.skull;
  if (n.contains('physio')) return MedGlyph.heart;
  if (n.contains('biochem') || n.contains('chem')) return MedGlyph.flask;
  if (n.contains('path')) return MedGlyph.microscope;
  if (n.contains('pharm')) return MedGlyph.pills;
  if (n.contains('micro')) return MedGlyph.bacteria;
  if (n.contains('forensic') || n.contains('fmt')) return MedGlyph.fingerprint;
  if (n.contains('communit') ||
      n.contains('psm') ||
      n.contains('spm') ||
      n.contains('prevent')) {
    return MedGlyph.people;
  }
  if (n.contains('ent') || n.contains('oto') || n.contains('otorhin')) {
    return MedGlyph.ear;
  }
  if (n.contains('ophthal') || n.contains('eye')) return MedGlyph.eye;
  if (n.contains('surg')) return MedGlyph.scalpel;
  if (n.contains('ortho')) return MedGlyph.bone;
  if (n.contains('obst') ||
      n.contains('gyn') ||
      n.contains('paed') ||
      n.contains('pediat')) {
    return MedGlyph.baby;
  }
  if (n.contains('psych')) return MedGlyph.brain;
  if (n.contains('med')) return MedGlyph.stethoscope;
  return MedGlyph.book;
}

/// Paths and helpers for the Docci comic illustrations.
///
/// Docci is Medico’s intern mascot — a round comic med student, not a gecko.
abstract final class BrandAssets {
  static const mascotName = 'Docci';
  static const mascotHeroTag = 'docci-mascot';

  static const mascotWave = 'assets/illustrations/mascot_wave.jpg';
  static const mascotStudy = 'assets/illustrations/mascot_study.jpg';
  static const mascotAvatar = 'assets/illustrations/mascot_avatar.jpg';
  static const doodleEquipment = 'assets/illustrations/doodle_equipment.jpg';
  static const yearFirst = 'assets/illustrations/year_first.jpg';
  static const yearSecond = 'assets/illustrations/year_second.jpg';
  static const yearThird = 'assets/illustrations/year_third.jpg';
  static const yearFinal = 'assets/illustrations/year_final.jpg';

  /// Pick year art from KUHS phase code/name/order. 1st → skull, 2nd → lab,
  /// 3rd → clinics, final → stethoscope.
  static String yearArt({
    required String code,
    required String name,
    required int displayOrder,
  }) {
    final blob = '${code.toLowerCase()} ${name.toLowerCase()}';
    if (_looksFinal(blob, displayOrder)) return yearFinal;
    if (_looksThird(blob, displayOrder)) return yearThird;
    if (_looksSecond(blob, displayOrder)) return yearSecond;
    return yearFirst;
  }

  static bool _looksFinal(String blob, int order) =>
      blob.contains('final') ||
      blob.contains('phase4') ||
      blob.contains('year 4') ||
      blob.contains('4th') ||
      order >= 4;

  static bool _looksThird(String blob, int order) =>
      blob.contains('third') ||
      blob.contains('phase3') ||
      blob.contains('year 3') ||
      blob.contains('3rd') ||
      blob.contains('part 1') ||
      order == 3;

  static bool _looksSecond(String blob, int order) =>
      blob.contains('second') ||
      blob.contains('phase2') ||
      blob.contains('year 2') ||
      blob.contains('2nd') ||
      order == 2;
}

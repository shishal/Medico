/// Honest PYQ coverage for Home. Never a hard-coded marketing percentage.
class UniversityCoverage {
  const UniversityCoverage({
    required this.paperCount,
    required this.pyqCount,
    required this.contentUniversityId,
    this.contentUniversityName,
    this.selectedUniversityName,
  });

  final int paperCount;
  final int pyqCount;
  final String contentUniversityId;
  final String? contentUniversityName;
  final String? selectedUniversityName;
}

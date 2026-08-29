import 'package:flutter_test/flutter_test.dart';

import 'package:medico/features/security/domain/watermark_identity.dart';

void main() {
  test('joins name, phone, and email', () {
    expect(
      WatermarkIdentity.label(
        fullName: 'Ada Lovelace',
        phone: '9876543210',
        email: 'ada@example.com',
      ),
      'Ada Lovelace · 9876543210 · ada@example.com',
    );
  });

  test('skips blank and whitespace-only fields', () {
    expect(
      WatermarkIdentity.label(
        fullName: '  ',
        phone: null,
        email: 'ada@example.com',
      ),
      'ada@example.com',
    );
  });

  test('returns empty when nothing identifying is available', () {
    expect(WatermarkIdentity.label(), isEmpty);
  });
}
